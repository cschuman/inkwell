#import "../../include/effects/drag_effect_protocol.h"
#import "../../include/effects/pass_through_view.h"
#import <QuartzCore/QuartzCore.h>

@interface ParticleEffect : BaseDragEffect
@property (nonatomic, strong) NSView* baseOverlay;  // Base overlay for drop zone
@property (nonatomic, strong) CAEmitterLayer* emitterLayer;
@property (nonatomic, strong) CAGradientLayer* glowLayer;
@end

@implementation ParticleEffect

- (NSString*)effectName {
    return @"Stardust";
}

- (NSString*)effectDescription {
    return @"Magical particles follow your drag";
}

- (void)setupEffect {
    // Prepare particle system
}

- (void)cleanupEffect {
    [self.baseOverlay removeFromSuperview];
    self.baseOverlay = nil;
    [self.emitterLayer removeFromSuperlayer];
    [self.glowLayer removeFromSuperlayer];
    self.emitterLayer = nil;
    self.glowLayer = nil;
}

- (void)onDragEnter:(NSPoint)point {
    [super onDragEnter:point];
    
    NSLog(@"ParticleEffect: onDragEnter, targetView=%@", self.targetView);
    
    // Create base overlay for drop zone indication
    if (!self.baseOverlay && self.targetView) {
        NSLog(@"ParticleEffect: Creating base overlay");
        self.baseOverlay = [[PassThroughView alloc] initWithFrame:self.targetView.bounds];
        self.baseOverlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.baseOverlay.wantsLayer = YES;
        // More visible purple/pink tint
        self.baseOverlay.layer.backgroundColor = [[NSColor colorWithRed:0.8 green:0.0 blue:0.8 alpha:0.25] CGColor];
        self.baseOverlay.layer.borderColor = [[NSColor colorWithRed:0.7 green:0.0 blue:0.7 alpha:0.8] CGColor];
        self.baseOverlay.layer.borderWidth = 3.0;
        self.baseOverlay.layer.cornerRadius = 8.0;
        
        // Add it immediately
        [self.targetView addSubview:self.baseOverlay positioned:NSWindowAbove relativeTo:nil];
        self.baseOverlay.layer.zPosition = 1000;
    }
    
    if (!self.emitterLayer && self.targetView) {
        NSLog(@"ParticleEffect: Setting up particle emitter");
        [self setupParticleEmitter];
        [self setupGlowEffect];
    } else if (self.emitterLayer) {
        NSLog(@"ParticleEffect: Emitter already exists");
    }
    
    // Position emitter at drag point
    [self updateEmitterPosition:point];
}

- (void)setupParticleEmitter {
    // Ensure view has a layer
    if (!self.targetView.layer) {
        self.targetView.wantsLayer = YES;
    }
    
    self.emitterLayer = [CAEmitterLayer layer];
    self.emitterLayer.frame = self.targetView.bounds;
    self.emitterLayer.zPosition = 100;  // Ensure it's on top
    
    NSLog(@"ParticleEffect: Created emitter layer, frame=%@", NSStringFromRect(self.emitterLayer.frame));
    
    // Configure emitter properties
    self.emitterLayer.emitterShape = kCAEmitterLayerPoint;
    self.emitterLayer.emitterMode = kCAEmitterLayerOutline;
    self.emitterLayer.renderMode = kCAEmitterLayerAdditive;
    
    // Create particle cell
    CAEmitterCell* particle = [CAEmitterCell emitterCell];
    particle.name = @"particle";
    
    // Particle appearance
    NSImage* particleImage = [self createParticleImage];
    particle.contents = (id)[particleImage CGImageForProposedRect:NULL context:nil hints:nil];
    particle.contentsRect = CGRectMake(0, 0, 1, 1);
    
    // Birth rate and lifetime
    particle.birthRate = 100;  // More particles
    particle.lifetime = 3.0;   // Longer life
    particle.lifetimeRange = 0.5;
    
    // Velocity and emission
    particle.velocity = 50;    // Faster movement
    particle.velocityRange = 20;
    particle.emissionRange = M_PI * 2;
    
    // Scale - make particles bigger
    particle.scale = 1.0;      // Bigger initial size
    particle.scaleRange = 0.5;
    particle.scaleSpeed = -0.2;
    
    // Color
    particle.color = [[NSColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0] CGColor];
    particle.redRange = 0.2;
    particle.greenRange = 0.2;
    particle.blueRange = 0.2;
    
    // Alpha - start fully opaque
    particle.alphaSpeed = -0.3;  // Fade slower
    particle.alphaRange = 0.2;
    
    // Spin
    particle.spin = M_PI;
    particle.spinRange = M_PI * 2;
    
    self.emitterLayer.emitterCells = @[particle];
    [self.targetView.layer addSublayer:self.emitterLayer];
    
    NSLog(@"ParticleEffect: Added emitter to view layer, birthRate=%f", particle.birthRate);
}

- (void)setupGlowEffect {
    self.glowLayer = [CAGradientLayer layer];
    self.glowLayer.frame = CGRectMake(0, 0, 100, 100);
    self.glowLayer.cornerRadius = 50;
    
    // Radial gradient effect
    self.glowLayer.type = kCAGradientLayerRadial;
    self.glowLayer.colors = @[
        (id)[[NSColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.3] CGColor],
        (id)[[NSColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.0] CGColor]
    ];
    self.glowLayer.locations = @[@0.0, @1.0];
    self.glowLayer.startPoint = CGPointMake(0.5, 0.5);
    self.glowLayer.endPoint = CGPointMake(1.0, 1.0);
    
    [self.targetView.layer addSublayer:self.glowLayer];
}

- (NSImage*)createParticleImage {
    NSImage* particleImage = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
    
    [particleImage lockFocus];
    
    // Draw a simple bright circle for visibility
    NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(5, 5, 10, 10)];
    [[NSColor whiteColor] setFill];
    [circle fill];
    
    // Add a colored glow
    NSBezierPath* glow = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(2, 2, 16, 16)];
    [[NSColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:0.5] setFill];
    [glow fill];
    
    [particleImage unlockFocus];
    
    NSLog(@"ParticleEffect: Created particle image, size=%@", NSStringFromSize(particleImage.size));
    return particleImage;
}

- (void)updateEmitterPosition:(NSPoint)point {
    // Point is already in view coordinates
    NSPoint layerPoint = point;
    
    NSLog(@"ParticleEffect: Updating emitter position to %@", NSStringFromPoint(layerPoint));
    
    // Update emitter position
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.emitterLayer.emitterPosition = layerPoint;
    
    // Update glow position
    if (self.glowLayer) {
        self.glowLayer.position = layerPoint;
    }
    [CATransaction commit];
}

- (void)onDragMove:(NSPoint)point {
    [super onDragMove:point];
    [self updateEmitterPosition:point];
    
    // Add some velocity based on movement
    static NSPoint lastPoint = {0, 0};
    CGFloat dx = point.x - lastPoint.x;
    CGFloat dy = point.y - lastPoint.y;
    
    // Update acceleration dynamically doesn't work well with CAEmitterCell
    // Skip this for now to avoid issues
    
    lastPoint = point;
}

- (void)renderToView:(NSView*)view {
    // NSLog(@"ParticleEffect: renderToView called, emitterLayer=%@", self.emitterLayer);
    
    // Always update targetView
    self.targetView = view;
    
    // Ensure view has a layer
    if (!view.layer) {
        view.wantsLayer = YES;
    }
    
    // Add base overlay if not already there
    if (self.baseOverlay && self.baseOverlay.superview != view) {
        NSLog(@"ParticleEffect: Adding base overlay to view");
        [view addSubview:self.baseOverlay positioned:NSWindowAbove relativeTo:nil];
        self.baseOverlay.layer.zPosition = 1000;
    }
    
    // Add emitter layer if not already there
    if (self.emitterLayer && self.emitterLayer.superlayer != view.layer) {
        NSLog(@"ParticleEffect: Adding emitter layer to view");
        [self.emitterLayer removeFromSuperlayer];
        [view.layer addSublayer:self.emitterLayer];
    }
    
    // Add glow layer if not already there
    if (self.glowLayer && self.glowLayer.superlayer != view.layer) {
        NSLog(@"ParticleEffect: Adding glow layer to view");
        [self.glowLayer removeFromSuperlayer];
        [view.layer addSublayer:self.glowLayer];
    }
}

- (void)onDragExit {
    [super onDragExit];
    
    // Remove base overlay
    [self.baseOverlay removeFromSuperview];
    [self.baseOverlay release];
    self.baseOverlay = nil;
    
    // Stop emitting new particles
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.emitterLayer.birthRate = 0;
    [CATransaction commit];
    
    // Fade out glow
    CABasicAnimation* fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.toValue = @0.0;
    fadeOut.duration = 0.5;
    fadeOut.removedOnCompletion = NO;
    fadeOut.fillMode = kCAFillModeForwards;
    [self.glowLayer addAnimation:fadeOut forKey:@"fadeOut"];
    
    // Clean up after particles die
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.emitterLayer removeFromSuperlayer];
        [self.glowLayer removeFromSuperlayer];
        self.emitterLayer = nil;
        self.glowLayer = nil;
    });
}

- (void)onDrop:(NSPoint)point {
    [super onDrop:point];
    
    // Remove base overlay
    [self.baseOverlay removeFromSuperview];
    [self.baseOverlay release];
    self.baseOverlay = nil;
    
    // Particle burst on drop
    CAEmitterCell* burst = [CAEmitterCell emitterCell];
    burst.birthRate = 500;
    burst.lifetime = 0.5;
    burst.velocity = 100;
    burst.scale = 0.5;
    NSImage* burstImage = [self createParticleImage];
    burst.contents = (id)[burstImage CGImageForProposedRect:NULL context:nil hints:nil];
    
    CAEmitterLayer* burstLayer = [CAEmitterLayer layer];
    burstLayer.emitterPosition = point;  // Point is already in view coordinates
    burstLayer.emitterCells = @[burst];
    [self.targetView.layer addSublayer:burstLayer];
    
    // Remove burst and cleanup after animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [burstLayer removeFromSuperlayer];
        [self.emitterLayer removeFromSuperlayer];
        [self.glowLayer removeFromSuperlayer];
        self.emitterLayer = nil;
        self.glowLayer = nil;
    });
}

- (NSUInteger)estimatedMemoryUsage {
    return 51200; // ~50KB for particle system
}

- (CGFloat)gpuUsagePercent {
    return 15.0; // Moderate GPU usage
}

@end