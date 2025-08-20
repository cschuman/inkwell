#import "../../include/effects/drag_effect_protocol.h"
#import <QuartzCore/QuartzCore.h>

@interface RippleEffect : BaseDragEffect
@property (nonatomic, strong) NSView* baseOverlay;  // Base overlay for drop zone
@property (nonatomic, strong) CALayer* rippleContainer;
@property (nonatomic, strong) NSMutableArray<CAShapeLayer*>* rippleLayers;
@property (nonatomic) NSInteger rippleCount;
@end

@implementation RippleEffect

- (NSString*)effectName {
    return @"Ripple";
}

- (NSString*)effectDescription {
    return @"Animated ripples emanate from cursor";
}

- (void)setupEffect {
    self.rippleLayers = [NSMutableArray array];
    self.rippleCount = 0;
}

- (void)cleanupEffect {
    [self.baseOverlay removeFromSuperview];
    self.baseOverlay = nil;
    [self.rippleContainer removeFromSuperlayer];
    self.rippleContainer = nil;
    [self.rippleLayers removeAllObjects];
}

- (void)onDragEnter:(NSPoint)point {
    [super onDragEnter:point];
    
    NSLog(@"RippleEffect: onDragEnter, targetView=%@", self.targetView);
    
    // Create base overlay for drop zone indication
    if (!self.baseOverlay && self.targetView) {
        NSLog(@"RippleEffect: Creating base overlay");
        self.baseOverlay = [[NSView alloc] initWithFrame:self.targetView.bounds];
        self.baseOverlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.baseOverlay.wantsLayer = YES;
        // More visible cyan/teal tint
        self.baseOverlay.layer.backgroundColor = [[NSColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:0.25] CGColor];
        self.baseOverlay.layer.borderColor = [[NSColor colorWithRed:0.0 green:0.7 blue:0.7 alpha:0.8] CGColor];
        self.baseOverlay.layer.borderWidth = 3.0;
        self.baseOverlay.layer.cornerRadius = 8.0;
        
        // Add it immediately
        [self.targetView addSubview:self.baseOverlay positioned:NSWindowAbove relativeTo:nil];
        self.baseOverlay.layer.zPosition = 1000;
    }
    
    if (!self.rippleContainer && self.targetView) {
        // Ensure view has a layer
        if (!self.targetView.layer) {
            self.targetView.wantsLayer = YES;
        }
        
        self.rippleContainer = [CALayer layer];
        self.rippleContainer.frame = self.targetView.bounds;
        self.rippleContainer.masksToBounds = NO;  // Allow ripples to expand beyond bounds
        self.rippleContainer.zPosition = 100;  // Ensure it's on top
        [self.targetView.layer addSublayer:self.rippleContainer];
        
        NSLog(@"RippleEffect: Created ripple container, frame=%@", NSStringFromRect(self.rippleContainer.frame));
    }
    
    [self createRippleAtPoint:point];
}

- (void)onDragMove:(NSPoint)point {
    [super onDragMove:point];
    
    // Create new ripple every few pixels of movement
    static NSPoint lastRipplePoint = {0, 0};
    CGFloat distance = hypot(point.x - lastRipplePoint.x, point.y - lastRipplePoint.y);
    
    if (distance > 30) { // Every 30 pixels
        [self createRippleAtPoint:point];
        lastRipplePoint = point;
    }
}

- (void)createRippleAtPoint:(NSPoint)point {
    // Point is already in view coordinates
    NSPoint layerPoint = point;
    
    NSLog(@"RippleEffect: Creating ripple at point %@", NSStringFromPoint(layerPoint));
    
    // Create ripple layer
    CAShapeLayer* ripple = [CAShapeLayer layer];
    ripple.position = layerPoint;
    ripple.zPosition = 50;  // Ensure visibility
    
    // Initial small circle
    CGFloat initialRadius = 10.0;
    ripple.path = [self circlePathWithRadius:initialRadius];
    ripple.fillColor = [[NSColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.2] CGColor];  // Add some fill
    ripple.strokeColor = [[NSColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8] CGColor];  // More opaque
    ripple.lineWidth = 3.0;  // Thicker line
    
    [self.rippleContainer addSublayer:ripple];
    [self.rippleLayers addObject:ripple];
    
    // Animate the ripple
    [self animateRipple:ripple];
    
    // Clean up old ripples
    if (self.rippleLayers.count > 5) {
        CAShapeLayer* oldRipple = self.rippleLayers.firstObject;
        [oldRipple removeFromSuperlayer];
        [self.rippleLayers removeObjectAtIndex:0];
    }
}

- (CGPathRef)circlePathWithRadius:(CGFloat)radius {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddEllipseInRect(path, NULL, CGRectMake(-radius, -radius, radius * 2, radius * 2));
    return path;
}

- (void)animateRipple:(CAShapeLayer*)ripple {
    // Expand animation
    CABasicAnimation* expandAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    expandAnimation.fromValue = (id)[self circlePathWithRadius:10];
    expandAnimation.toValue = (id)[self circlePathWithRadius:100];
    expandAnimation.duration = 1.5;
    
    // Fade animation
    CABasicAnimation* fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.fromValue = @1.0;
    fadeAnimation.toValue = @0.0;
    fadeAnimation.duration = 1.5;
    
    // Line width animation (gets thinner as it expands)
    CABasicAnimation* lineWidthAnimation = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
    lineWidthAnimation.fromValue = @2.0;
    lineWidthAnimation.toValue = @0.5;
    lineWidthAnimation.duration = 1.5;
    
    // Group animations
    CAAnimationGroup* animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[expandAnimation, fadeAnimation, lineWidthAnimation];
    animationGroup.duration = 1.5;
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animationGroup.removedOnCompletion = NO;
    animationGroup.fillMode = kCAFillModeForwards;
    
    // Add completion block to remove the layer
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [ripple removeFromSuperlayer];
    }];
    
    [ripple addAnimation:animationGroup forKey:@"rippleAnimation"];
    
    [CATransaction commit];
}

- (void)renderToView:(NSView*)view {
    // Always update targetView
    self.targetView = view;
    
    // Ensure view has a layer
    if (!view.layer) {
        view.wantsLayer = YES;
    }
    
    // Add base overlay if not already there
    if (self.baseOverlay && self.baseOverlay.superview != view) {
        [view addSubview:self.baseOverlay positioned:NSWindowAbove relativeTo:nil];
        self.baseOverlay.layer.zPosition = 1000;
    }
    
    // Add ripple container if not already there
    if (self.rippleContainer && self.rippleContainer.superlayer != view.layer) {
        [self.rippleContainer removeFromSuperlayer];
        [view.layer addSublayer:self.rippleContainer];
    }
}

- (void)onDragExit {
    [super onDragExit];
    
    // Remove base overlay
    [self.baseOverlay removeFromSuperview];
    [self.baseOverlay release];
    self.baseOverlay = nil;
    
    // Fade out all ripples
    for (CAShapeLayer* ripple in self.rippleLayers) {
        CABasicAnimation* fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOut.toValue = @0.0;
        fadeOut.duration = 0.3;
        fadeOut.removedOnCompletion = NO;
        fadeOut.fillMode = kCAFillModeForwards;
        [ripple addAnimation:fadeOut forKey:@"fadeOut"];
    }
    
    // Clean up after animation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.rippleContainer removeFromSuperlayer];
        [self.rippleLayers removeAllObjects];
    });
}

- (void)onDrop:(NSPoint)point {
    [super onDrop:point];
    
    // Remove base overlay
    [self.baseOverlay removeFromSuperview];
    [self.baseOverlay release];
    self.baseOverlay = nil;
    
    // Create a final "splash" ripple
    [self createRippleAtPoint:point];
    
    // Then clean up
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.rippleContainer removeFromSuperlayer];
        self.rippleContainer = nil;
        [self.rippleLayers removeAllObjects];
        self.rippleCount = 0;
    });
}

- (NSUInteger)estimatedMemoryUsage {
    return 10240; // ~10KB for layers
}

- (CGFloat)gpuUsagePercent {
    return 5.0; // Light GPU usage for animations
}

@end