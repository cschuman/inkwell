#import "../../include/effects/drag_effect_protocol.h"
#import <Cocoa/Cocoa.h>

@implementation BaseDragEffect

@synthesize currentDragPoint;
@synthesize isDragging;
@synthesize animationTime;
@synthesize targetView;
@synthesize dimmingOverlay;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isDragging = NO;
        self.animationTime = 0.0;
        [self setupEffect];
    }
    return self;
}

- (void)dealloc {
    [self cleanupEffect];
    [self.dimmingOverlay release];
    [super dealloc];
}

// Helper method to create dimming overlay
- (void)createDimmingOverlay {
    if (!self.dimmingOverlay && self.targetView) {
        self.dimmingOverlay = [[NSView alloc] initWithFrame:self.targetView.bounds];
        self.dimmingOverlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.dimmingOverlay.wantsLayer = YES;
        self.dimmingOverlay.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.4] CGColor];
    }
}

- (void)removeDimmingOverlay {
    if (self.dimmingOverlay) {
        // Simple removal without animation for now
        [self.dimmingOverlay removeFromSuperview];
        [self.dimmingOverlay release];
        self.dimmingOverlay = nil;
    }
}

// Default implementations
- (void)onDragEnter:(NSPoint)point {
    self.currentDragPoint = point;
    self.isDragging = YES;
}

- (void)onDragMove:(NSPoint)point {
    self.currentDragPoint = point;
}

- (void)onDragExit {
    self.isDragging = NO;
}

- (void)onDrop:(NSPoint)point {
    self.isDragging = NO;
    // Subclasses can add drop animation
}

- (void)renderToView:(NSView*)view {
    // Subclasses override this
}

- (void)updateWithTimeDelta:(NSTimeInterval)delta {
    self.animationTime += delta;
}

- (NSString*)effectName {
    return @"Base Effect";
}

- (NSString*)effectDescription {
    return @"Base drag effect implementation";
}

- (NSImage*)previewImage {
    // Generate a simple preview
    NSImage* preview = [[NSImage alloc] initWithSize:NSMakeSize(100, 100)];
    [preview lockFocus];
    [[NSColor grayColor] set];
    NSRectFill(NSMakeRect(0, 0, 100, 100));
    [preview unlockFocus];
    return preview;
}

- (NSUInteger)estimatedMemoryUsage {
    return 1024; // 1KB base
}

- (CGFloat)gpuUsagePercent {
    return 0.0;
}

// Override points for subclasses
- (void)setupEffect {
    // Subclasses initialize resources here
}

- (void)cleanupEffect {
    // Subclasses cleanup resources here
}

@end