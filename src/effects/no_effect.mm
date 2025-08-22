#import "../../include/effects/drag_effect_protocol.h"

// The baseline - just the simple blue overlay we already have
@interface NoEffect : BaseDragEffect
@property (nonatomic, strong) NSView* overlayView;
@end

@implementation NoEffect

- (NSString*)effectName {
    return @"Classic Blue";
}

- (NSString*)effectDescription {
    return @"Simple blue overlay (no animation)";
}

- (void)setupEffect {
    // Nothing to setup for basic effect
}

- (void)cleanupEffect {
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
}

- (void)onDragEnter:(NSPoint)point {
    [super onDragEnter:point];
    
    // NSLog(@"NoEffect: onDragEnter called at point: %@", NSStringFromPoint(point));
    
    if (!self.overlayView && self.targetView) {
        // NSLog(@"NoEffect: Creating overlay view");
        self.overlayView = [[NSView alloc] initWithFrame:self.targetView.bounds];
        self.overlayView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.overlayView.wantsLayer = YES;
        self.overlayView.layer.backgroundColor = [[NSColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.25] CGColor];
        self.overlayView.layer.borderColor = [[NSColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8] CGColor];
        self.overlayView.layer.borderWidth = 3.0;
        self.overlayView.layer.cornerRadius = 8.0;
    }
}

- (void)renderToView:(NSView*)view {
    // NSLog(@"NoEffect: renderToView called, isDragging=%d, overlayView=%@", self.isDragging, self.overlayView);
    
    // Update targetView
    self.targetView = view;
    
    if (self.isDragging && self.overlayView) {
        // Ensure view has a layer
        if (!view.layer) {
            view.wantsLayer = YES;
        }
        
        if (self.overlayView.superview != view) {
            // NSLog(@"NoEffect: Adding overlay to view");
            // Add overlay on top of everything
            [view addSubview:self.overlayView positioned:NSWindowAbove relativeTo:nil];
            // Make sure it's on top by setting layer z-position
            self.overlayView.layer.zPosition = 1000;
        }
    }
}

- (void)onDragExit {
    [super onDragExit];
    // NSLog(@"NoEffect: onDragExit - removing overlay");
    [self.overlayView removeFromSuperview];
    [self.overlayView release];
    self.overlayView = nil;
}

- (void)onDrop:(NSPoint)point {
    [super onDrop:point];
    // NSLog(@"NoEffect: onDrop - removing overlay");
    [self.overlayView removeFromSuperview];
    [self.overlayView release];
    self.overlayView = nil;
}

- (NSUInteger)estimatedMemoryUsage {
    return 2048; // 2KB for the overlay view
}

- (CGFloat)gpuUsagePercent {
    return 0.1; // Basically nothing
}

@end