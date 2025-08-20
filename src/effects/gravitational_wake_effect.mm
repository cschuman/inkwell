#import "../../include/effects/drag_effect_protocol.h"
#import "../../include/effects/physics_world.h"
#import "../../include/effects/animation_orchestrator.h"
#import "../../include/effects/noise_generator.h"
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

@interface GravitationalWakeEffect : BaseDragEffect <AnimationOrchestrorDelegate>

// Core components
@property (nonatomic, strong) PhysicsWorld* physicsWorld;
@property (nonatomic, strong) AnimationOrchestrator* animator;
@property (nonatomic, strong) CAShapeLayer* distortionMesh;
@property (nonatomic, strong) NSMutableArray<CAShapeLayer*>* fieldLines;
@property (nonatomic, strong) CAGradientLayer* warpField;

// Drag state
@property (nonatomic) simd_float2 dragVelocity;
@property (nonatomic) simd_float2 lastDragPosition;
@property (nonatomic) NSTimeInterval lastDragTime;
@property (nonatomic) float currentMass;  // Mass of dragged item based on velocity

// Visual components
@property (nonatomic, strong) NSView* overlayView;
@property (nonatomic, strong) CALayer* attractorLayer;
@property (nonatomic, strong) NSMutableArray<CAShapeLayer*>* magneticConnections;

// Grid distortion
@property (nonatomic) NSInteger gridResolution;
@property (nonatomic) NSMutableArray<NSValue*>* gridPoints;
@property (nonatomic) NSMutableArray<NSValue*>* distortedPoints;

@end

@implementation GravitationalWakeEffect

// Helper to convert NSBezierPath to CGPath
- (CGPathRef)CGPathFromNSBezierPath:(NSBezierPath*)path {
    CGMutablePathRef cgPath = CGPathCreateMutable();
    NSInteger elementCount = [path elementCount];
    
    for (NSInteger i = 0; i < elementCount; i++) {
        NSPoint points[3];
        NSBezierPathElement element = [path elementAtIndex:i associatedPoints:points];
        
        switch (element) {
            case NSMoveToBezierPathElement:
                CGPathMoveToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            case NSLineToBezierPathElement:
                CGPathAddLineToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            case NSCurveToBezierPathElement:
                CGPathAddCurveToPoint(cgPath, NULL, points[0].x, points[0].y,
                                     points[1].x, points[1].y,
                                     points[2].x, points[2].y);
                break;
            case NSClosePathBezierPathElement:
                CGPathCloseSubpath(cgPath);
                break;
        }
    }
    
    return cgPath;
}

- (NSString*)effectName {
    return @"Gravitational Wake";
}

- (NSString*)effectDescription {
    return @"Spacetime bends around your drag, with field lines reaching for drop zones";
}

- (void)setupEffect {
    _gridResolution = 20;
    _fieldLines = [NSMutableArray array];
    _magneticConnections = [NSMutableArray array];
    _gridPoints = [NSMutableArray array];
    _distortedPoints = [NSMutableArray array];
    
    // Initialize physics world
    CGRect bounds = CGRectMake(0, 0, 800, 600);  // Will be updated when view is set
    _physicsWorld = [[PhysicsWorld alloc] initWithBounds:bounds cellSize:40.0f];
    _physicsWorld.gravity = simd_make_float2(0, 0);  // No gravity in space
    _physicsWorld.airDensity = 0.01f;  // Low resistance
    
    // Initialize animator
    _animator = [[AnimationOrchestrator alloc] init];
    _animator.delegate = self;
    
    // Setup grid points
    [self setupGrid];
}

- (void)setupGrid {
    [_gridPoints removeAllObjects];
    [_distortedPoints removeAllObjects];
    
    if (!self.targetView) return;
    
    CGRect bounds = self.targetView.bounds;
    float stepX = bounds.size.width / (float)(_gridResolution - 1);
    float stepY = bounds.size.height / (float)(_gridResolution - 1);
    
    for (NSInteger y = 0; y < _gridResolution; y++) {
        for (NSInteger x = 0; x < _gridResolution; x++) {
            simd_float2 point = simd_make_float2(x * stepX, y * stepY);
            [_gridPoints addObject:[NSValue valueWithBytes:&point objCType:@encode(simd_float2)]];
            [_distortedPoints addObject:[NSValue valueWithBytes:&point objCType:@encode(simd_float2)]];
        }
    }
}

- (void)cleanupEffect {
    [_animator stop];
    [_physicsWorld removeAllParticles];
    
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
    
    [self.distortionMesh removeFromSuperlayer];
    self.distortionMesh = nil;
    
    for (CAShapeLayer* line in self.fieldLines) {
        [line removeFromSuperlayer];
    }
    [self.fieldLines removeAllObjects];
    
    for (CAShapeLayer* connection in self.magneticConnections) {
        [connection removeFromSuperlayer];
    }
    [self.magneticConnections removeAllObjects];
}

- (void)onDragEnter:(NSPoint)point {
    [super onDragEnter:point];
    
    self.lastDragPosition = simd_make_float2(point.x, point.y);
    self.lastDragTime = CACurrentMediaTime();
    self.currentMass = 10.0f;
    
    // Create overlay
    if (!self.overlayView && self.targetView) {
        self.overlayView = [[[NSView alloc] initWithFrame:self.targetView.bounds] autorelease];
        self.overlayView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.overlayView.wantsLayer = YES;
        self.overlayView.layer.backgroundColor = [[NSColor clearColor] CGColor];
        
        // Create warp field gradient
        self.warpField = [CAGradientLayer layer];
        self.warpField.frame = self.overlayView.bounds;
        self.warpField.type = kCAGradientLayerRadial;
        self.warpField.colors = @[
            (id)[[NSColor colorWithRed:0.0 green:0.2 blue:0.5 alpha:0.0] CGColor],
            (id)[[NSColor colorWithRed:0.0 green:0.3 blue:0.7 alpha:0.1] CGColor],
            (id)[[NSColor colorWithRed:0.0 green:0.4 blue:0.9 alpha:0.05] CGColor]
        ];
        self.warpField.locations = @[@0.0, @0.5, @1.0];
        self.warpField.startPoint = CGPointMake(0.5, 0.5);
        self.warpField.endPoint = CGPointMake(1.0, 1.0);
        [self.overlayView.layer addSublayer:self.warpField];
        
        // Create distortion mesh
        [self createDistortionMesh];
        
        // Create attractor visualization
        self.attractorLayer = [CALayer layer];
        self.attractorLayer.frame = CGRectMake(point.x - 20, point.y - 20, 40, 40);
        self.attractorLayer.cornerRadius = 20;
        self.attractorLayer.backgroundColor = [[NSColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.3] CGColor];
        self.attractorLayer.borderColor = [[NSColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:0.8] CGColor];
        self.attractorLayer.borderWidth = 2.0;
        
        // Add pulsing animation to attractor
        CABasicAnimation* pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        pulse.fromValue = @1.0;
        pulse.toValue = @1.2;
        pulse.duration = 0.8;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.attractorLayer addAnimation:pulse forKey:@"pulse"];
        
        [self.overlayView.layer addSublayer:self.attractorLayer];
        
        // Add overlay to target view
        [self.targetView addSubview:self.overlayView positioned:NSWindowAbove relativeTo:nil];
        self.overlayView.layer.zPosition = 1000;
        
        // Setup physics
        [self setupPhysicsField:point];
        
        // Start animation
        [self.animator start];
    }
}

- (void)createDistortionMesh {
    self.distortionMesh = [CAShapeLayer layer];
    self.distortionMesh.frame = self.overlayView.bounds;
    self.distortionMesh.fillColor = [[NSColor clearColor] CGColor];
    self.distortionMesh.strokeColor = [[NSColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.15] CGColor];
    self.distortionMesh.lineWidth = 0.5;
    
    [self updateDistortionMesh];
    [self.overlayView.layer addSublayer:self.distortionMesh];
}

- (void)updateDistortionMesh {
    NSBezierPath* meshPath = [NSBezierPath bezierPath];
    
    // Draw horizontal lines
    for (NSInteger y = 0; y < _gridResolution; y++) {
        for (NSInteger x = 0; x < _gridResolution; x++) {
            NSInteger index = y * _gridResolution + x;
            simd_float2 point;
            [self.distortedPoints[index] getValue:&point];
            
            if (x == 0) {
                [meshPath moveToPoint:CGPointMake(point.x, point.y)];
            } else {
                [meshPath lineToPoint:CGPointMake(point.x, point.y)];
            }
        }
    }
    
    // Draw vertical lines
    for (NSInteger x = 0; x < _gridResolution; x++) {
        for (NSInteger y = 0; y < _gridResolution; y++) {
            NSInteger index = y * _gridResolution + x;
            simd_float2 point;
            [self.distortedPoints[index] getValue:&point];
            
            if (y == 0) {
                [meshPath moveToPoint:CGPointMake(point.x, point.y)];
            } else {
                [meshPath lineToPoint:CGPointMake(point.x, point.y)];
            }
        }
    }
    
    self.distortionMesh.path = [self CGPathFromNSBezierPath:meshPath];
}

- (void)setupPhysicsField:(NSPoint)point {
    // Clear existing field
    [self.physicsWorld.vectorField clear];
    
    // Add main attractor at drag point
    simd_float2 attractorPos = simd_make_float2(point.x, point.y);
    [self.physicsWorld.vectorField addAttractor:attractorPos strength:100.0f];
    
    // Add vortex for swirling motion
    [self.physicsWorld.vectorField addVortex:attractorPos strength:50.0f radius:150.0f];
    
    // Create field line particles
    [self createFieldLines:point];
}

- (void)createFieldLines:(NSPoint)center {
    NSInteger lineCount = 12;
    float angleStep = (2.0f * M_PI) / lineCount;
    
    for (NSInteger i = 0; i < lineCount; i++) {
        float angle = i * angleStep;
        float radius = 80.0f;
        
        CAShapeLayer* fieldLine = [CAShapeLayer layer];
        fieldLine.frame = self.overlayView.bounds;
        fieldLine.fillColor = [[NSColor clearColor] CGColor];
        fieldLine.strokeColor = [[NSColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:0.3] CGColor];
        fieldLine.lineWidth = 1.5;
        fieldLine.lineCap = kCALineCapRound;
        
        // Create initial path
        NSBezierPath* path = [NSBezierPath bezierPath];
        CGPoint start = CGPointMake(center.x + cosf(angle) * radius, 
                                   center.y + sinf(angle) * radius);
        [path moveToPoint:start];
        
        // Trace field line
        simd_float2 position = simd_make_float2(start.x, start.y);
        for (int step = 0; step < 50; step++) {
            simd_float2 force = [self.physicsWorld.vectorField forceAtPoint:position time:0];
            position += simd_normalize(force) * 5.0f;
            [path lineToPoint:CGPointMake(position.x, position.y)];
        }
        
        fieldLine.path = [self CGPathFromNSBezierPath:path];
        
        // Add flowing animation
        CABasicAnimation* dashAnimation = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
        dashAnimation.fromValue = @0.0;
        dashAnimation.toValue = @10.0;
        dashAnimation.duration = 2.0;
        dashAnimation.repeatCount = HUGE_VALF;
        fieldLine.lineDashPattern = @[@5, @5];
        [fieldLine addAnimation:dashAnimation forKey:@"flow"];
        
        [self.overlayView.layer addSublayer:fieldLine];
        [self.fieldLines addObject:fieldLine];
    }
}

- (void)onDragMove:(NSPoint)point {
    [super onDragMove:point];
    
    NSTimeInterval currentTime = CACurrentMediaTime();
    NSTimeInterval dt = currentTime - self.lastDragTime;
    
    // Calculate velocity
    simd_float2 currentPos = simd_make_float2(point.x, point.y);
    self.dragVelocity = (currentPos - self.lastDragPosition) / dt;
    
    // Update mass based on velocity (faster = more massive)
    float speed = simd_length(self.dragVelocity);
    self.currentMass = 10.0f + speed * 0.1f;
    
    // Update attractor position with smooth animation
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.1];
    self.attractorLayer.position = point;
    
    // Scale based on mass
    float scale = 1.0f + (self.currentMass - 10.0f) * 0.01f;
    self.attractorLayer.transform = CATransform3DMakeScale(scale, scale, 1.0);
    [CATransaction commit];
    
    // Update physics field
    [self.physicsWorld.vectorField clear];
    [self.physicsWorld.vectorField addAttractor:currentPos strength:self.currentMass * 10.0f];
    
    // Add motion-based vortex
    if (speed > 10.0f) {
        simd_float2 perpendicular = simd_make_float2(-self.dragVelocity.y, self.dragVelocity.x);
        simd_float2 vortexPos = currentPos - simd_normalize(self.dragVelocity) * 50.0f;
        [self.physicsWorld.vectorField addVortex:vortexPos 
                                         strength:speed * 2.0f 
                                           radius:100.0f + speed];
    }
    
    // Create wake trail
    [self createWakeParticle:self.lastDragPosition velocity:self.dragVelocity];
    
    // Check for nearby drop zones and create magnetic connections
    [self updateMagneticConnections:point];
    
    self.lastDragPosition = currentPos;
    self.lastDragTime = currentTime;
}

- (void)createWakeParticle:(simd_float2)position velocity:(simd_float2)velocity {
    PhysicsParticle* particle = [self.physicsWorld addParticleAt:position withMass:0.5f];
    particle.lifetime = 2.0f;
    
    // Add perpendicular velocity for swirl
    simd_float2 perpendicular = simd_make_float2(-velocity.y, velocity.x) * 0.3f;
    [self.physicsWorld applyImpulseToParticle:particle impulse:perpendicular];
}

- (void)updateMagneticConnections:(NSPoint)dragPoint {
    // Clear existing connections
    for (CAShapeLayer* connection in self.magneticConnections) {
        [connection removeFromSuperlayer];
    }
    [self.magneticConnections removeAllObjects];
    
    // Find potential drop zones (simplified - would integrate with actual drop targets)
    NSArray* dropZones = [self findDropZones];
    
    for (NSValue* zoneValue in dropZones) {
        CGPoint dropZone = [zoneValue pointValue];
        float distance = hypotf(dropZone.x - dragPoint.x, dropZone.y - dragPoint.y);
        
        if (distance < 200.0f) {  // Within magnetic range
            CAShapeLayer* connection = [CAShapeLayer layer];
            connection.frame = self.overlayView.bounds;
            
            // Create curved path using bezier
            NSBezierPath* path = [NSBezierPath bezierPath];
            [path moveToPoint:dragPoint];
            
            // Control points for curve
            CGPoint control1 = CGPointMake(dragPoint.x, dropZone.y);
            CGPoint control2 = CGPointMake(dropZone.x, dragPoint.y);
            
            [path curveToPoint:dropZone controlPoint1:control1 controlPoint2:control2];
            
            connection.path = [self CGPathFromNSBezierPath:path];
            connection.fillColor = [[NSColor clearColor] CGColor];
            
            // Stronger connection when closer
            float strength = 1.0f - (distance / 200.0f);
            connection.strokeColor = [[NSColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:strength * 0.5] CGColor];
            connection.lineWidth = strength * 3.0f;
            connection.lineCap = kCALineCapRound;
            
            // Animated dash pattern
            connection.lineDashPattern = @[@10, @5];
            CABasicAnimation* dashAnimation = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
            dashAnimation.fromValue = @0.0;
            dashAnimation.toValue = @(-15.0);
            dashAnimation.duration = 0.5;
            dashAnimation.repeatCount = HUGE_VALF;
            [connection addAnimation:dashAnimation forKey:@"dash"];
            
            [self.overlayView.layer addSublayer:connection];
            [self.magneticConnections addObject:connection];
        }
    }
}

- (NSArray*)findDropZones {
    // Placeholder - would integrate with actual drop target detection
    // For now, return some mock drop zones
    return @[
        [NSValue valueWithPoint:CGPointMake(100, 300)],
        [NSValue valueWithPoint:CGPointMake(700, 300)],
        [NSValue valueWithPoint:CGPointMake(400, 100)],
        [NSValue valueWithPoint:CGPointMake(400, 500)]
    ];
}

- (void)renderToView:(NSView*)view {
    self.targetView = view;
    
    if (!view.layer) {
        view.wantsLayer = YES;
    }
    
    // Update physics world bounds
    if (_physicsWorld) {
        CGRect newBounds = view.bounds;
        _physicsWorld = [[PhysicsWorld alloc] initWithBounds:newBounds cellSize:40.0f];
        _physicsWorld.gravity = simd_make_float2(0, 0);
        _physicsWorld.airDensity = 0.01f;
    }
    
    // Update grid for new bounds
    [self setupGrid];
    
    if (self.overlayView && self.overlayView.superview != view) {
        [view addSubview:self.overlayView positioned:NSWindowAbove relativeTo:nil];
        self.overlayView.layer.zPosition = 1000;
    }
}

#pragma mark - AnimationOrchestrorDelegate

- (void)animationOrchestrator:(id)orchestrator didUpdateWithDeltaTime:(NSTimeInterval)dt {
    // Update physics
    [self.physicsWorld stepWithDeltaTime:dt];
    
    // Update grid distortion
    [self updateGridDistortion];
    
    // Update field lines
    [self updateFieldLines];
    
    // Render particles
    [self renderParticles];
}

- (void)updateGridDistortion {
    if (!self.isDragging) return;
    
    simd_float2 attractorPos = self.lastDragPosition;
    float mass = self.currentMass;
    
    for (NSInteger i = 0; i < self.gridPoints.count; i++) {
        simd_float2 originalPoint;
        [self.gridPoints[i] getValue:&originalPoint];
        
        // Calculate distortion based on distance to attractor
        simd_float2 delta = originalPoint - attractorPos;
        float distance = simd_length(delta);
        
        if (distance > 0.001f) {
            // Gravitational lensing formula (simplified)
            float distortion = mass * 50.0f / (distance + 50.0f);
            simd_float2 pull = simd_normalize(delta) * distortion;
            
            // Add some noise for organic feel
            float noise = [NoiseGenerator perlinNoise2D:originalPoint * 0.01f] * 5.0f;
            pull += simd_make_float2(noise, noise * 0.5f);
            
            simd_float2 distortedPoint = originalPoint - pull;
            self.distortedPoints[i] = [NSValue valueWithBytes:&distortedPoint objCType:@encode(simd_float2)];
        }
    }
    
    [self updateDistortionMesh];
}

- (void)updateFieldLines {
    // Recreate field lines periodically for dynamic effect
    static NSTimeInterval lastUpdate = 0;
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    if (currentTime - lastUpdate > 0.5) {
        for (CAShapeLayer* line in self.fieldLines) {
            [line removeFromSuperlayer];
        }
        [self.fieldLines removeAllObjects];
        [self createFieldLines:NSMakePoint(self.lastDragPosition.x, self.lastDragPosition.y)];
        lastUpdate = currentTime;
    }
}

- (void)renderParticles {
    // Render physics particles as small dots
    for (PhysicsParticle* particle in self.physicsWorld.particles) {
        // Could add CALayer representations here for visible particles
        // For now, the distortion mesh and field lines provide the visual
    }
}

- (void)onDragExit {
    [super onDragExit];
    
    // Animate collapse
    [self.animator animateValue:1.0 to:0.0 duration:0.5 
                         curve:[AnimationCurve easeInOutCubic]
                        update:^(float value) {
        self.overlayView.layer.opacity = value;
        
        // Contract the warp field
        CATransform3D transform = CATransform3DMakeScale(1.0f + (1.0f - value), 
                                                         1.0f + (1.0f - value), 1.0);
        self.warpField.transform = transform;
    } completion:^{
        [self cleanupEffect];
    }];
}

- (void)onDrop:(NSPoint)point {
    [super onDrop:point];
    
    // Create implosion effect
    [self.physicsWorld applyExplosionAt:simd_make_float2(point.x, point.y) 
                                   force:-500.0f 
                                  radius:200.0f];
    
    // Animate the collapse with a satisfying snap
    [self.animator springAnimateValue:1.0 to:0.0 
                             damping:0.7f 
                           stiffness:300.0f 
                              update:^(float value) {
        self.overlayView.layer.opacity = value;
        
        // Collapse to drop point
        CATransform3D transform = CATransform3DMakeScale(value, value, 1.0);
        self.attractorLayer.transform = transform;
        
        // Pulse the field lines
        for (CAShapeLayer* line in self.fieldLines) {
            line.strokeColor = [[NSColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:value * 0.5] CGColor];
            line.lineWidth = (1.0f - value) * 5.0f + 1.0f;
        }
    }];
    
    // Final cleanup after animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self cleanupEffect];
    });
}

- (NSUInteger)estimatedMemoryUsage {
    return 102400;  // ~100KB for physics particles and grid
}

- (CGFloat)gpuUsagePercent {
    return 25.0;  // Moderate GPU usage for distortion calculations
}

@end