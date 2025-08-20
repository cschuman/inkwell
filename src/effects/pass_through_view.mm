#import "../../include/effects/pass_through_view.h"

@implementation PassThroughView

- (NSView*)hitTest:(NSPoint)point {
    // Return nil to pass all events through to the view below
    return nil;
}

- (BOOL)acceptsFirstResponder {
    return NO;
}

- (BOOL)mouseDownCanMoveWindow {
    return NO;
}

@end