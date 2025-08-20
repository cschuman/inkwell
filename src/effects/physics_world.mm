#import "../../include/effects/physics_world.h"
#import <vector>
#import <unordered_map>

@implementation PhysicsParticle
- (instancetype)init {
    if (self = [super init]) {
        _position = simd_make_float2(0, 0);
        _oldPosition = _position;
        _acceleration = simd_make_float2(0, 0);
        _mass = 1.0f;
        _damping = 0.99f;
        _lifetime = INFINITY;
        _gridIndex = -1;
    }
    return self;
}
@end

@implementation SpringConstraint
@synthesize particleA = _particleA;
@synthesize particleB = _particleB;

- (void)solve {
    if (!self.particleA || !self.particleB) return;
    
    simd_float2 delta = self.particleB.position - self.particleA.position;
    float currentLength = simd_length(delta);
    
    if (currentLength < 0.0001f) return;  // Prevent division by zero
    
    float difference = (self.restLength - currentLength) / currentLength;
    simd_float2 correction = delta * difference * self.stiffness * 0.5f;
    
    // Apply corrections weighted by mass
    float totalMass = self.particleA.mass + self.particleB.mass;
    float ratioA = self.particleB.mass / totalMass;
    float ratioB = self.particleA.mass / totalMass;
    
    self.particleA.position -= correction * ratioA;
    self.particleB.position += correction * ratioB;
    
    // Apply damping
    simd_float2 velocityA = self.particleA.position - self.particleA.oldPosition;
    simd_float2 velocityB = self.particleB.position - self.particleB.oldPosition;
    simd_float2 relativeVelocity = velocityB - velocityA;
    
    simd_float2 dampingForce = relativeVelocity * self.damping;
    self.particleA.position += dampingForce * ratioA * 0.5f;
    self.particleB.position -= dampingForce * ratioB * 0.5f;
}
@end

@interface VectorField ()
@property (nonatomic) NSMutableArray<NSValue*>* attractors;
@property (nonatomic) NSMutableArray<NSNumber*>* attractorStrengths;
@property (nonatomic) NSMutableArray<NSValue*>* vortices;
@property (nonatomic) NSMutableArray<NSNumber*>* vortexStrengths;
@property (nonatomic) NSMutableArray<NSNumber*>* vortexRadii;
@end

@implementation VectorField

- (instancetype)init {
    if (self = [super init]) {
        _attractors = [[NSMutableArray alloc] init];
        _attractorStrengths = [[NSMutableArray alloc] init];
        _vortices = [[NSMutableArray alloc] init];
        _vortexStrengths = [[NSMutableArray alloc] init];
        _vortexRadii = [[NSMutableArray alloc] init];
    }
    return self;
}

- (simd_float2)forceAtPoint:(simd_float2)point time:(NSTimeInterval)time {
    simd_float2 totalForce = simd_make_float2(0, 0);
    
    // Attractors create gravitational pull
    for (NSInteger i = 0; i < self.attractors.count; i++) {
        simd_float2 attractorPos;
        [self.attractors[i] getValue:&attractorPos];
        float strength = self.attractorStrengths[i].floatValue;
        
        simd_float2 delta = attractorPos - point;
        float distanceSq = simd_length_squared(delta);
        
        if (distanceSq > 0.0001f) {
            // Inverse square law with cutoff to prevent singularity
            float force = strength / fmaxf(distanceSq, 1.0f);
            totalForce += simd_normalize(delta) * force;
        }
    }
    
    // Vortices create rotational forces
    for (NSInteger i = 0; i < self.vortices.count; i++) {
        simd_float2 vortexPos;
        [self.vortices[i] getValue:&vortexPos];
        float strength = self.vortexStrengths[i].floatValue;
        float radius = self.vortexRadii[i].floatValue;
        
        simd_float2 delta = point - vortexPos;
        float distance = simd_length(delta);
        
        if (distance < radius && distance > 0.0001f) {
            // Perpendicular force for rotation
            simd_float2 tangent = simd_make_float2(-delta.y, delta.x);
            float falloff = 1.0f - (distance / radius);
            totalForce += simd_normalize(tangent) * strength * falloff;
            
            // Add slight inward pull for spiral effect
            totalForce -= simd_normalize(delta) * strength * 0.1f * falloff;
        }
    }
    
    // Add time-varying turbulence for organic feel
    float turbulence = sinf(point.x * 0.1f + time * 2.0f) * cosf(point.y * 0.1f - time * 1.5f);
    totalForce += simd_make_float2(turbulence * 0.5f, turbulence * 0.3f);
    
    return totalForce;
}

- (void)addAttractor:(simd_float2)position strength:(float)strength {
    [self.attractors addObject:[NSValue valueWithBytes:&position objCType:@encode(simd_float2)]];
    [self.attractorStrengths addObject:@(strength)];
}

- (void)addVortex:(simd_float2)position strength:(float)strength radius:(float)radius {
    [self.vortices addObject:[NSValue valueWithBytes:&position objCType:@encode(simd_float2)]];
    [self.vortexStrengths addObject:@(strength)];
    [self.vortexRadii addObject:@(radius)];
}

- (void)clear {
    if (self.attractors) {
        [self.attractors removeAllObjects];
    }
    if (self.attractorStrengths) {
        [self.attractorStrengths removeAllObjects];
    }
    if (self.vortices) {
        [self.vortices removeAllObjects];
    }
    if (self.vortexStrengths) {
        [self.vortexStrengths removeAllObjects];
    }
    if (self.vortexRadii) {
        [self.vortexRadii removeAllObjects];
    }
}

@end

@interface PhysicsWorld ()
@property (nonatomic) CGRect bounds;
@property (nonatomic) NSMutableDictionary<NSNumber*, NSMutableArray<PhysicsParticle*>*>* spatialHash;
@property (nonatomic) NSTimeInterval currentTime;
@end

@implementation PhysicsWorld

- (instancetype)initWithBounds:(CGRect)bounds cellSize:(float)cellSize {
    if (self = [super init]) {
        _bounds = bounds;
        _cellSize = cellSize;
        _gridWidth = (NSInteger)ceil(bounds.size.width / cellSize);
        _gridHeight = (NSInteger)ceil(bounds.size.height / cellSize);
        
        _gravity = simd_make_float2(0, -98.0f);  // Realistic gravity
        _airDensity = 1.2f;
        _windVelocity = simd_make_float2(0, 0);
        
        _particles = [[NSMutableArray alloc] init];
        _constraints = [[NSMutableArray alloc] init];
        _spatialHash = [[NSMutableDictionary alloc] init];
        _vectorField = [[VectorField alloc] init];
        
        _currentTime = 0;
    }
    return self;
}

- (PhysicsParticle*)addParticleAt:(simd_float2)position withMass:(float)mass {
    if (!self.particles) {
        NSLog(@"PhysicsWorld: ERROR - particles array is nil in addParticleAt");
        return nil;
    }
    
    PhysicsParticle* particle = [[PhysicsParticle alloc] init];
    if (!particle) {
        NSLog(@"PhysicsWorld: ERROR - failed to create particle");
        return nil;
    }
    
    particle.position = position;
    particle.oldPosition = position;
    particle.mass = mass;
    
    [self.particles addObject:particle];
    [self updateSpatialHashForParticle:particle];
    
    // The particle is retained by the particles array, return without autorelease
    return particle;
}

- (void)removeParticle:(PhysicsParticle*)particle {
    [self removeSpatialHashForParticle:particle];
    [self.particles removeObject:particle];
    
    // Remove any constraints involving this particle
    NSMutableArray* constraintsToRemove = [NSMutableArray array];
    for (SpringConstraint* constraint in self.constraints) {
        if (constraint.particleA == particle || constraint.particleB == particle) {
            [constraintsToRemove addObject:constraint];
        }
    }
    [self.constraints removeObjectsInArray:constraintsToRemove];
}

- (void)removeAllParticles {
    [self.particles removeAllObjects];
    [self.constraints removeAllObjects];
    [self.spatialHash removeAllObjects];
}

- (SpringConstraint*)connectParticles:(PhysicsParticle*)a 
                                   to:(PhysicsParticle*)b 
                        withStiffness:(float)stiffness {
    SpringConstraint* constraint = [[SpringConstraint alloc] init];
    constraint.particleA = a;
    constraint.particleB = b;
    constraint.restLength = simd_distance(a.position, b.position);
    constraint.stiffness = stiffness;
    constraint.damping = 0.1f;
    
    [self.constraints addObject:constraint];
    return constraint;
}

- (void)stepWithDeltaTime:(NSTimeInterval)dt {
    _currentTime += dt;
    
    // Cap timestep for stability
    dt = fminf(dt, 0.016f);  // Cap at 60fps equivalent
    
    // Apply forces and update positions using Verlet integration
    for (PhysicsParticle* particle in self.particles) {
        if (particle.lifetime <= 0) continue;
        
        particle.lifetime -= dt;
        
        // Calculate total acceleration
        simd_float2 totalAcceleration = self.gravity;
        
        // Add vector field forces
        simd_float2 fieldForce = [self.vectorField forceAtPoint:particle.position time:_currentTime];
        totalAcceleration += fieldForce / particle.mass;
        
        // Air resistance (quadratic drag)
        simd_float2 velocity = particle.position - particle.oldPosition;
        float speed = simd_length(velocity);
        if (speed > 0.0001f) {
            simd_float2 dragForce = -simd_normalize(velocity) * speed * speed * self.airDensity * 0.47f;
            totalAcceleration += dragForce / particle.mass;
        }
        
        // Wind
        simd_float2 relativeWind = self.windVelocity - velocity;
        totalAcceleration += relativeWind * 0.1f;
        
        // Verlet integration
        simd_float2 newPosition = particle.position * 2.0f - particle.oldPosition + totalAcceleration * dt * dt;
        
        // Apply damping
        newPosition = particle.position + (newPosition - particle.position) * particle.damping;
        
        // Boundary collision with bounce
        simd_float2 oldPos = particle.oldPosition;
        if (newPosition.x < self.bounds.origin.x) {
            newPosition.x = self.bounds.origin.x;
            oldPos.x = particle.position.x + (particle.position.x - oldPos.x) * 0.8f;
        }
        if (newPosition.x > self.bounds.origin.x + self.bounds.size.width) {
            newPosition.x = self.bounds.origin.x + self.bounds.size.width;
            oldPos.x = particle.position.x + (particle.position.x - oldPos.x) * 0.8f;
        }
        if (newPosition.y < self.bounds.origin.y) {
            newPosition.y = self.bounds.origin.y;
            oldPos.y = particle.position.y + (particle.position.y - oldPos.y) * 0.8f;
        }
        if (newPosition.y > self.bounds.origin.y + self.bounds.size.height) {
            newPosition.y = self.bounds.origin.y + self.bounds.size.height;
            oldPos.y = particle.position.y + (particle.position.y - oldPos.y) * 0.8f;
        }
        
        particle.oldPosition = oldPos;
        particle.position = newPosition;
        particle.acceleration = totalAcceleration;
    }
    
    // Solve constraints (multiple iterations for stability)
    for (int i = 0; i < 3; i++) {
        for (SpringConstraint* constraint in self.constraints) {
            [constraint solve];
        }
    }
    
    // Update spatial hash
    for (PhysicsParticle* particle in self.particles) {
        [self updateSpatialHashForParticle:particle];
    }
    
    // Remove dead particles
    NSMutableArray* deadParticles = [NSMutableArray array];
    for (PhysicsParticle* particle in self.particles) {
        if (particle.lifetime <= 0) {
            [deadParticles addObject:particle];
        }
    }
    for (PhysicsParticle* particle in deadParticles) {
        [self removeParticle:particle];
    }
}

- (void)applyImpulseToParticle:(PhysicsParticle*)particle impulse:(simd_float2)impulse {
    // Convert impulse to position change for Verlet
    simd_float2 velocityChange = impulse / particle.mass;
    particle.oldPosition -= velocityChange;
}

- (void)applyExplosionAt:(simd_float2)center force:(float)force radius:(float)radius {
    for (PhysicsParticle* particle in self.particles) {
        simd_float2 delta = particle.position - center;
        float distance = simd_length(delta);
        
        if (distance < radius && distance > 0.0001f) {
            float falloff = 1.0f - (distance / radius);
            simd_float2 impulse = simd_normalize(delta) * force * falloff * falloff;
            [self applyImpulseToParticle:particle impulse:impulse];
        }
    }
}

#pragma mark - Spatial Hashing

- (NSInteger)hashForPosition:(simd_float2)position {
    NSInteger x = (NSInteger)floorf(position.x / self.cellSize);
    NSInteger y = (NSInteger)floorf(position.y / self.cellSize);
    
    x = MAX(0, MIN(x, self.gridWidth - 1));
    y = MAX(0, MIN(y, self.gridHeight - 1));
    
    return y * self.gridWidth + x;
}

- (void)updateSpatialHashForParticle:(PhysicsParticle*)particle {
    if (!particle) return;
    
    [self removeSpatialHashForParticle:particle];
    
    NSInteger newIndex = [self hashForPosition:particle.position];
    particle.gridIndex = newIndex;
    
    NSNumber* key = @(newIndex);
    NSMutableArray* cellParticles = self.spatialHash[key];
    if (!cellParticles) {
        cellParticles = [NSMutableArray array];
        self.spatialHash[key] = cellParticles;
    }
    [cellParticles addObject:particle];
}

- (void)removeSpatialHashForParticle:(PhysicsParticle*)particle {
    if (!particle) return;
    
    if (particle.gridIndex >= 0) {
        NSNumber* key = @(particle.gridIndex);
        NSMutableArray* cellParticles = self.spatialHash[key];
        [cellParticles removeObject:particle];
        
        // Clean up empty cells
        if (cellParticles.count == 0) {
            [self.spatialHash removeObjectForKey:key];
        }
        
        particle.gridIndex = -1;
    }
}

- (NSArray<PhysicsParticle*>*)particlesNearPoint:(simd_float2)point radius:(float)radius {
    NSMutableArray* result = [NSMutableArray array];
    
    // Check all cells that could contain particles within radius
    NSInteger minX = (NSInteger)floorf((point.x - radius) / self.cellSize);
    NSInteger maxX = (NSInteger)ceilf((point.x + radius) / self.cellSize);
    NSInteger minY = (NSInteger)floorf((point.y - radius) / self.cellSize);
    NSInteger maxY = (NSInteger)ceilf((point.y + radius) / self.cellSize);
    
    minX = MAX(0, minX);
    maxX = MIN(self.gridWidth - 1, maxX);
    minY = MAX(0, minY);
    maxY = MIN(self.gridHeight - 1, maxY);
    
    float radiusSq = radius * radius;
    
    for (NSInteger y = minY; y <= maxY; y++) {
        for (NSInteger x = minX; x <= maxX; x++) {
            NSInteger index = y * self.gridWidth + x;
            NSArray* cellParticles = self.spatialHash[@(index)];
            
            for (PhysicsParticle* particle in cellParticles) {
                if (simd_distance_squared(particle.position, point) <= radiusSq) {
                    [result addObject:particle];
                }
            }
        }
    }
    
    return result;
}

- (PhysicsParticle*)nearestParticleToPoint:(simd_float2)point maxRadius:(float)maxRadius {
    NSArray* nearby = [self particlesNearPoint:point radius:maxRadius];
    
    PhysicsParticle* nearest = nil;
    float nearestDistSq = maxRadius * maxRadius;
    
    for (PhysicsParticle* particle in nearby) {
        float distSq = simd_distance_squared(particle.position, point);
        if (distSq < nearestDistSq) {
            nearest = particle;
            nearestDistSq = distSq;
        }
    }
    
    return nearest;
}

#pragma mark - Metrics

- (NSUInteger)activeParticleCount {
    return self.particles.count;
}

- (float)averageParticleSpeed {
    if (self.particles.count == 0) return 0;
    
    float totalSpeed = 0;
    for (PhysicsParticle* particle in self.particles) {
        simd_float2 velocity = particle.position - particle.oldPosition;
        totalSpeed += simd_length(velocity);
    }
    
    return totalSpeed / self.particles.count;
}

@end