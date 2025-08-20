#import "../../include/effects/drag_effect_protocol.h"
#import "../../include/effects/physics_world.h"
#import "../../include/effects/animation_orchestrator.h"
#import "../../include/effects/noise_generator.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <simd/simd.h>

@interface LiquidGlassEffect : BaseDragEffect <AnimationOrchestrorDelegate>

// Glass layers
@property (nonatomic, strong) CALayer* glassLayer;
@property (nonatomic, strong) CAGradientLayer* refractionLayer;
@property (nonatomic, strong) CAShapeLayer* liquidBoundary;
@property (nonatomic, strong) NSMutableArray<CAShapeLayer*>* droplets;

// Physics simulation
@property (nonatomic, strong) PhysicsWorld* liquidPhysics;
@property (nonatomic, strong) AnimationOrchestrator* animator;

// Liquid properties
@property (nonatomic) NSMutableArray<NSValue*>* liquidPoints;  // Surface points
@property (nonatomic) NSMutableArray<NSNumber*>* liquidVelocities;
@property (nonatomic) float viscosity;
@property (nonatomic) float surfaceTension;

// Drag state
@property (nonatomic) simd_float2 dragPosition;
@property (nonatomic) simd_float2 dragVelocity;
@property (nonatomic) NSTimeInterval lastDragTime;

// Refraction effect
@property (nonatomic, strong) CIContext* ciContext;
@property (nonatomic, strong) CIFilter* refractionFilter;
@property (nonatomic, strong) NSView* overlayView;

// Glass cracks
@property (nonatomic, strong) NSMutableArray<CAShapeLayer*>* cracks;
@property (nonatomic) BOOL isShattered;

@end

@implementation LiquidGlassEffect

- (NSString*)effectName {
    return @"Liquid Glass";
}

- (NSString*)effectDescription {
    return @"Glass refracts and liquifies, with mercury-like droplets trailing behind";
}

- (void)setupEffect {
    _droplets = [NSMutableArray array];
    _liquidPoints = [NSMutableArray array];
    _liquidVelocities = [NSMutableArray array];
    _cracks = [NSMutableArray array];
    
    _viscosity = 0.98f;
    _surfaceTension = 0.05f;
    _isShattered = NO;
    
    // Initialize physics for liquid simulation
    CGRect bounds = CGRectMake(0, 0, 800, 600);
    _liquidPhysics = [[PhysicsWorld alloc] initWithBounds:bounds cellSize:20.0f];
    _liquidPhysics.gravity = simd_make_float2(0, -200.0f);  // Liquid falls
    _liquidPhysics.airDensity = 5.0f;  // Higher resistance for liquid
    
    // Initialize animator
    _animator = [[AnimationOrchestrator alloc] init];
    _animator.delegate = self;
    
    // Core Image context for refraction
    _ciContext = [CIContext context];
    
    // Initialize liquid surface
    [self initializeLiquidSurface];
}

- (void)initializeLiquidSurface {
    NSInteger pointCount = 50;
    float spacing = 800.0f / (pointCount - 1);
    
    for (NSInteger i = 0; i < pointCount; i++) {
        simd_float2 point = simd_make_float2(i * spacing, 300.0f);
        [_liquidPoints addObject:[NSValue valueWithBytes:&point objCType:@encode(simd_float2)]];
        [_liquidVelocities addObject:@(0.0f)];
    }
}

- (void)cleanupEffect {
    [_animator stop];
    [_liquidPhysics removeAllParticles];
    
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
    
    [self.glassLayer removeFromSuperlayer];
    self.glassLayer = nil;
    
    [self.liquidBoundary removeFromSuperlayer];
    self.liquidBoundary = nil;
    
    for (CAShapeLayer* droplet in self.droplets) {
        [droplet removeFromSuperlayer];
    }
    [self.droplets removeAllObjects];
    
    for (CAShapeLayer* crack in self.cracks) {
        [crack removeFromSuperlayer];
    }
    [self.cracks removeAllObjects];
}

- (void)onDragEnter:(NSPoint)point {
    [super onDragEnter:point];
    
    self.dragPosition = simd_make_float2(point.x, point.y);
    self.lastDragTime = CACurrentMediaTime();
    
    if (!self.overlayView && self.targetView) {
        // Create overlay
        self.overlayView = [[[NSView alloc] initWithFrame:self.targetView.bounds] autorelease];
        self.overlayView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.overlayView.wantsLayer = YES;
        self.overlayView.layer.backgroundColor = [[NSColor clearColor] CGColor];
        
        // Create glass layer
        self.glassLayer = [CALayer layer];
        self.glassLayer.frame = self.overlayView.bounds;
        self.glassLayer.backgroundColor = [[NSColor colorWithWhite:1.0 alpha:0.05] CGColor];
        self.glassLayer.cornerRadius = 10.0;
        
        // Add glass shine gradient
        CAGradientLayer* shineLayer = [CAGradientLayer layer];
        shineLayer.frame = self.glassLayer.bounds;
        shineLayer.colors = @[
            (id)[[NSColor colorWithWhite:1.0 alpha:0.3] CGColor],
            (id)[[NSColor colorWithWhite:1.0 alpha:0.1] CGColor],
            (id)[[NSColor colorWithWhite:1.0 alpha:0.0] CGColor]
        ];
        shineLayer.locations = @[@0.0, @0.3, @1.0];
        shineLayer.startPoint = CGPointMake(0, 0);
        shineLayer.endPoint = CGPointMake(1, 1);
        [self.glassLayer addSublayer:shineLayer];
        
        // Create refraction layer
        self.refractionLayer = [CAGradientLayer layer];
        self.refractionLayer.frame = CGRectMake(point.x - 100, point.y - 100, 200, 200);
        self.refractionLayer.type = kCAGradientLayerRadial;
        self.refractionLayer.colors = @[
            (id)[[NSColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:0.4] CGColor],
            (id)[[NSColor colorWithRed:0.7 green:0.85 blue:1.0 alpha:0.2] CGColor],
            (id)[[NSColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:0.0] CGColor]
        ];
        self.refractionLayer.locations = @[@0.0, @0.5, @1.0];
        self.refractionLayer.startPoint = CGPointMake(0.5, 0.5);
        self.refractionLayer.endPoint = CGPointMake(1.0, 1.0);
        
        // Add chromatic aberration effect
        CALayer* redChannel = [CALayer layer];
        redChannel.frame = self.refractionLayer.bounds;
        redChannel.backgroundColor = [[NSColor colorWithRed:1.0 green:0 blue:0 alpha:0.05] CGColor];
        redChannel.compositingFilter = @"screenBlendMode";
        
        CALayer* blueChannel = [CALayer layer];
        blueChannel.frame = CGRectInset(self.refractionLayer.bounds, -2, -2);
        blueChannel.backgroundColor = [[NSColor colorWithRed:0 green:0 blue:1.0 alpha:0.05] CGColor];
        blueChannel.compositingFilter = @"screenBlendMode";
        
        [self.refractionLayer addSublayer:redChannel];
        [self.refractionLayer addSublayer:blueChannel];
        
        // Create liquid boundary
        self.liquidBoundary = [CAShapeLayer layer];
        self.liquidBoundary.frame = self.overlayView.bounds;
        self.liquidBoundary.fillColor = [[NSColor colorWithRed:0.7 green:0.85 blue:1.0 alpha:0.3] CGColor];
        self.liquidBoundary.strokeColor = [[NSColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:0.6] CGColor];
        self.liquidBoundary.lineWidth = 2.0;
        
        // Add layers
        [self.overlayView.layer addSublayer:self.glassLayer];
        [self.overlayView.layer addSublayer:self.refractionLayer];
        [self.overlayView.layer addSublayer:self.liquidBoundary];
        
        // Add overlay to view
        [self.targetView addSubview:self.overlayView positioned:NSWindowAbove relativeTo:nil];
        self.overlayView.layer.zPosition = 1000;
        
        // Start liquid at drag point
        [self createLiquidPuddle:point];
        
        // Start animation
        [self.animator start];
    }
}

- (void)createLiquidPuddle:(NSPoint)center {
    // Create initial liquid particles around drag point
    NSInteger particleCount = 20;
    float radius = 50.0f;
    
    for (NSInteger i = 0; i < particleCount; i++) {
        float angle = (float)i / particleCount * 2.0f * M_PI;
        float r = radius * (0.8f + 0.2f * ((float)arc4random_uniform(100) / 100.0f));
        
        simd_float2 position = simd_make_float2(
            center.x + cosf(angle) * r,
            center.y + sinf(angle) * r
        );
        
        PhysicsParticle* particle = [self.liquidPhysics addParticleAt:position withMass:0.1f];
        particle.damping = self.viscosity;
        particle.lifetime = INFINITY;  // Liquid doesn't disappear
        
        // Connect nearby particles for cohesion
        if (i > 0) {
            NSArray* nearby = [self.liquidPhysics particlesNearPoint:position radius:30.0f];
            for (PhysicsParticle* neighbor in nearby) {
                if (neighbor != particle) {
                    [self.liquidPhysics connectParticles:particle to:neighbor withStiffness:self.surfaceTension];
                }
            }
        }
    }
}

- (void)onDragMove:(NSPoint)point {
    [super onDragMove:point];
    
    NSTimeInterval currentTime = CACurrentMediaTime();
    NSTimeInterval dt = currentTime - self.lastDragTime;
    
    simd_float2 newPosition = simd_make_float2(point.x, point.y);
    self.dragVelocity = (newPosition - self.dragPosition) / dt;
    
    // Move refraction layer with smooth animation
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.1];
    self.refractionLayer.position = point;
    
    // Distort refraction based on velocity
    float speed = simd_length(self.dragVelocity);
    float distortion = 1.0f + speed * 0.001f;
    self.refractionLayer.transform = CATransform3DMakeScale(distortion, distortion * 0.9f, 1.0);
    [CATransaction commit];
    
    // Check for fast movement that might shatter the glass
    if (speed > 500.0f && !self.isShattered) {
        [self shatterGlass:point];
    }
    
    // Create liquid trail
    [self createLiquidDroplets:self.dragPosition velocity:self.dragVelocity];
    
    // Disturb liquid surface
    [self disturbLiquidSurface:point velocity:self.dragVelocity];
    
    // Update state
    self.dragPosition = newPosition;
    self.lastDragTime = currentTime;
}

- (void)shatterGlass:(NSPoint)impact {
    self.isShattered = YES;
    
    // Create crack pattern
    NSInteger crackCount = 8 + arc4random_uniform(5);
    
    for (NSInteger i = 0; i < crackCount; i++) {
        CAShapeLayer* crack = [CAShapeLayer layer];
        crack.frame = self.overlayView.bounds;
        
        NSBezierPath* crackPath = [NSBezierPath bezierPath];
        [crackPath moveToPoint:impact];
        
        // Create jagged crack line
        float angle = (float)i / crackCount * 2.0f * M_PI;
        float length = 100.0f + arc4random_uniform(100);
        
        NSPoint currentPoint = impact;
        for (int segment = 0; segment < 5; segment++) {
            float segmentLength = length / 5.0f;
            float deviation = (arc4random_uniform(40) - 20);
            
            currentPoint = NSMakePoint(
                currentPoint.x + cosf(angle) * segmentLength + deviation,
                currentPoint.y + sinf(angle) * segmentLength + deviation
            );
            
            [crackPath lineToPoint:currentPoint];
        }
        
        crack.path = [self CGPathFromNSBezierPath:crackPath];
        crack.strokeColor = [[NSColor colorWithWhite:1.0 alpha:0.6] CGColor];
        crack.fillColor = [[NSColor clearColor] CGColor];
        crack.lineWidth = 1.5;
        crack.lineCap = kCALineCapRound;
        
        // Animate crack appearance
        CABasicAnimation* crackAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        crackAnimation.fromValue = @0.0;
        crackAnimation.toValue = @1.0;
        crackAnimation.duration = 0.2 + (float)i * 0.05f;
        crackAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [crack addAnimation:crackAnimation forKey:@"crack"];
        
        [self.overlayView.layer addSublayer:crack];
        [self.cracks addObject:crack];
    }
    
    // Add shatter sound effect (visual feedback)
    CALayer* shatterFlash = [CALayer layer];
    shatterFlash.frame = self.overlayView.bounds;
    shatterFlash.backgroundColor = [[NSColor whiteColor] CGColor];
    shatterFlash.opacity = 0.0;
    [self.overlayView.layer addSublayer:shatterFlash];
    
    CAKeyframeAnimation* flash = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    flash.values = @[@0.0, @0.5, @0.0];
    flash.keyTimes = @[@0.0, @0.1, @0.3];
    flash.duration = 0.3;
    flash.removedOnCompletion = YES;
    [shatterFlash addAnimation:flash forKey:@"flash"];
    
    // Remove flash after animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [shatterFlash removeFromSuperlayer];
    });
}

- (void)createLiquidDroplets:(simd_float2)position velocity:(simd_float2)velocity {
    // Emit droplets based on velocity
    float speed = simd_length(velocity);
    if (speed < 50.0f) return;
    
    NSInteger dropletCount = MIN(5, (NSInteger)(speed / 100.0f));
    
    for (NSInteger i = 0; i < dropletCount; i++) {
        // Create physics particle
        simd_float2 perpendicular = simd_make_float2(-velocity.y, velocity.x);
        perpendicular = simd_normalize(perpendicular) * (arc4random_uniform(40) - 20);
        
        simd_float2 dropletPos = position + perpendicular;
        PhysicsParticle* particle = [self.liquidPhysics addParticleAt:dropletPos withMass:0.05f];
        particle.lifetime = 3.0f;
        
        // Give it some initial velocity
        simd_float2 dropletVel = velocity * -0.3f + perpendicular * 0.5f;
        [self.liquidPhysics applyImpulseToParticle:particle impulse:dropletVel];
        
        // Create visual droplet
        CAShapeLayer* droplet = [CAShapeLayer layer];
        droplet.frame = CGRectMake(dropletPos.x - 3, dropletPos.y - 3, 6, 6);
        droplet.path = CGPathCreateWithEllipseInRect(CGRectMake(0, 0, 6, 6), NULL);
        droplet.fillColor = [[NSColor colorWithRed:0.7 green:0.85 blue:1.0 alpha:0.8] CGColor];
        droplet.strokeColor = [[NSColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0] CGColor];
        droplet.lineWidth = 0.5;
        
        // Add shimmer
        CAGradientLayer* shimmer = [CAGradientLayer layer];
        shimmer.frame = droplet.bounds;
        shimmer.colors = @[
            (id)[[NSColor whiteColor] CGColor],
            (id)[[NSColor colorWithWhite:1.0 alpha:0.0] CGColor]
        ];
        shimmer.locations = @[@0.0, @0.5];
        shimmer.type = kCAGradientLayerRadial;
        shimmer.startPoint = CGPointMake(0.3, 0.3);
        shimmer.endPoint = CGPointMake(0.7, 0.7);
        droplet.mask = shimmer;
        
        [self.overlayView.layer addSublayer:droplet];
        [self.droplets addObject:droplet];
        
        // Store particle reference in layer for physics update
        [droplet setValue:[NSValue valueWithPointer:particle] forKey:@"particle"];
    }
    
    // Clean up old droplets
    while (self.droplets.count > 100) {
        CAShapeLayer* oldDroplet = self.droplets[0];
        [oldDroplet removeFromSuperlayer];
        [self.droplets removeObjectAtIndex:0];
    }
}

- (void)disturbLiquidSurface:(NSPoint)point velocity:(simd_float2)velocity {
    // Find nearest liquid surface point
    NSInteger nearestIndex = -1;
    float nearestDistance = INFINITY;
    
    for (NSInteger i = 0; i < self.liquidPoints.count; i++) {
        simd_float2 surfacePoint;
        [self.liquidPoints[i] getValue:&surfacePoint];
        
        float distance = fabs(surfacePoint.x - point.x);
        if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestIndex = i;
        }
    }
    
    if (nearestIndex >= 0 && nearestDistance < 100.0f) {
        // Apply force to surface
        float force = simd_length(velocity) * 0.1f * (1.0f - nearestDistance / 100.0f);
        self.liquidVelocities[nearestIndex] = @(self.liquidVelocities[nearestIndex].floatValue - force);
        
        // Propagate waves
        NSInteger waveRadius = 5;
        for (NSInteger offset = 1; offset <= waveRadius; offset++) {
            float dampening = 1.0f - (float)offset / waveRadius;
            
            if (nearestIndex - offset >= 0) {
                NSInteger idx = nearestIndex - offset;
                self.liquidVelocities[idx] = @(self.liquidVelocities[idx].floatValue - force * dampening * 0.5f);
            }
            
            if (nearestIndex + offset < self.liquidPoints.count) {
                NSInteger idx = nearestIndex + offset;
                self.liquidVelocities[idx] = @(self.liquidVelocities[idx].floatValue - force * dampening * 0.5f);
            }
        }
    }
}

- (void)renderToView:(NSView*)view {
    self.targetView = view;
    
    if (!view.layer) {
        view.wantsLayer = YES;
    }
    
    // Update physics bounds
    if (_liquidPhysics) {
        CGRect newBounds = view.bounds;
        _liquidPhysics = [[PhysicsWorld alloc] initWithBounds:newBounds cellSize:20.0f];
        _liquidPhysics.gravity = simd_make_float2(0, -200.0f);
        _liquidPhysics.airDensity = 5.0f;
    }
    
    if (self.overlayView && self.overlayView.superview != view) {
        [view addSubview:self.overlayView positioned:NSWindowAbove relativeTo:nil];
        self.overlayView.layer.zPosition = 1000;
    }
}

#pragma mark - AnimationOrchestrorDelegate

- (void)animationOrchestrator:(id)orchestrator didUpdateWithDeltaTime:(NSTimeInterval)dt {
    // Update physics
    [self.liquidPhysics stepWithDeltaTime:dt];
    
    // Update liquid surface
    [self updateLiquidSurface:dt];
    
    // Update droplet positions
    [self updateDroplets];
    
    // Update liquid boundary
    [self updateLiquidBoundary];
}

- (void)updateLiquidSurface:(NSTimeInterval)dt {
    // Spring-based surface simulation
    float springConstant = 0.02f;
    float damping = 0.95f;
    
    for (NSInteger i = 0; i < self.liquidPoints.count; i++) {
        simd_float2 point;
        [self.liquidPoints[i] getValue:&point];
        
        float velocity = self.liquidVelocities[i].floatValue;
        
        // Spring force to rest position
        float restY = 300.0f;
        float displacement = point.y - restY;
        float springForce = -springConstant * displacement;
        
        // Surface tension from neighbors
        float tensionForce = 0;
        if (i > 0) {
            simd_float2 leftPoint;
            [self.liquidPoints[i-1] getValue:&leftPoint];
            tensionForce += (leftPoint.y - point.y) * self.surfaceTension;
        }
        if (i < self.liquidPoints.count - 1) {
            simd_float2 rightPoint;
            [self.liquidPoints[i+1] getValue:&rightPoint];
            tensionForce += (rightPoint.y - point.y) * self.surfaceTension;
        }
        
        // Update velocity and position
        velocity += (springForce + tensionForce) * dt;
        velocity *= damping;
        point.y += velocity * dt;
        
        // Update stored values
        self.liquidVelocities[i] = @(velocity);
        self.liquidPoints[i] = [NSValue valueWithBytes:&point objCType:@encode(simd_float2)];
    }
}

- (void)updateDroplets {
    for (CAShapeLayer* droplet in self.droplets) {
        NSValue* particleValue = [droplet valueForKey:@"particle"];
        if (particleValue) {
            PhysicsParticle* particle = (PhysicsParticle*)[particleValue pointerValue];
            if (particle && particle.lifetime > 0) {
                droplet.position = CGPointMake(particle.position.x, particle.position.y);
                droplet.opacity = particle.lifetime / 3.0f;  // Fade as it ages
            } else {
                droplet.opacity = 0;
            }
        }
    }
}

- (void)updateLiquidBoundary {
    if (self.liquidPoints.count < 2) return;
    
    NSBezierPath* liquidPath = [NSBezierPath bezierPath];
    
    // Start from first point
    simd_float2 firstPoint;
    [self.liquidPoints[0] getValue:&firstPoint];
    [liquidPath moveToPoint:CGPointMake(firstPoint.x, firstPoint.y)];
    
    // Create smooth curve through points
    for (NSInteger i = 1; i < self.liquidPoints.count; i++) {
        simd_float2 point;
        [self.liquidPoints[i] getValue:&point];
        
        if (i == 1) {
            [liquidPath lineToPoint:CGPointMake(point.x, point.y)];
        } else {
            simd_float2 prevPoint;
            [self.liquidPoints[i-1] getValue:&prevPoint];
            
            CGPoint control = CGPointMake(
                (prevPoint.x + point.x) / 2,
                (prevPoint.y + point.y) / 2
            );
            
            [liquidPath curveToPoint:CGPointMake(point.x, point.y)
                       controlPoint1:control
                       controlPoint2:control];
        }
    }
    
    // Close the path
    simd_float2 lastPoint;
    [self.liquidPoints[self.liquidPoints.count - 1] getValue:&lastPoint];
    [liquidPath lineToPoint:CGPointMake(lastPoint.x, 0)];
    [liquidPath lineToPoint:CGPointMake(firstPoint.x, 0)];
    [liquidPath closePath];
    
    self.liquidBoundary.path = [self CGPathFromNSBezierPath:liquidPath];
}

- (CGPathRef)CGPathFromNSBezierPath:(NSBezierPath*)path {
    CGMutablePathRef cgPath = CGPathCreateMutable();
    NSInteger elementCount = [path elementCount];
    
    for (NSInteger i = 0; i < elementCount; i++) {
        NSPoint points[3];
        NSBezierPathElement element = [path elementAtIndex:i associatedPoints:points];
        
        switch (element) {
            case NSBezierPathElementMoveTo:
                CGPathMoveToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            case NSBezierPathElementLineTo:
                CGPathAddLineToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            case NSBezierPathElementCurveTo:
                CGPathAddCurveToPoint(cgPath, NULL, points[0].x, points[0].y,
                                     points[1].x, points[1].y,
                                     points[2].x, points[2].y);
                break;
            case NSBezierPathElementClosePath:
                CGPathCloseSubpath(cgPath);
                break;
        }
    }
    
    return cgPath;
}

- (void)onDragExit {
    [super onDragExit];
    
    // Animate cleanup
    [self.animator animateValue:1.0 to:0.0 duration:0.5
                         curve:[AnimationCurve easeInOutCubic]
                        update:^(float value) {
        self.overlayView.layer.opacity = value;
        
        // Drain liquid
        for (NSInteger i = 0; i < self.liquidPoints.count; i++) {
            simd_float2 point;
            [self.liquidPoints[i] getValue:&point];
            point.y = point.y * value;
            self.liquidPoints[i] = [NSValue valueWithBytes:&point objCType:@encode(simd_float2)];
        }
        [self updateLiquidBoundary];
    } completion:^{
        [self cleanupEffect];
    }];
}

- (void)onDrop:(NSPoint)point {
    [super onDrop:point];
    
    // Create splash effect
    [self.liquidPhysics applyExplosionAt:simd_make_float2(point.x, point.y)
                                   force:200.0f
                                  radius:100.0f];
    
    // Shatter remaining glass
    if (!self.isShattered) {
        [self shatterGlass:point];
    }
    
    // Animate liquid splash and cleanup
    [self.animator springAnimateValue:1.0 to:0.0
                             damping:0.5f
                           stiffness:200.0f
                              update:^(float value) {
        self.overlayView.layer.opacity = value;
        
        // Disperse droplets
        for (CAShapeLayer* droplet in self.droplets) {
            CGPoint center = droplet.position;
            CGPoint delta = CGPointMake(center.x - point.x, center.y - point.y);
            float distance = hypotf(delta.x, delta.y);
            
            if (distance < 200.0f) {
                float force = (1.0f - value) * 100.0f / (distance + 1.0f);
                droplet.position = CGPointMake(
                    center.x + delta.x * force * 0.01f,
                    center.y + delta.y * force * 0.01f
                );
            }
        }
    }];
    
    // Cleanup after animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self cleanupEffect];
    });
}

- (NSUInteger)estimatedMemoryUsage {
    return 204800;  // ~200KB for liquid simulation and droplets
}

- (CGFloat)gpuUsagePercent {
    return 30.0;  // Moderate GPU for refraction and liquid rendering
}

@end