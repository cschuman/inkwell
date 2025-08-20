#ifndef EFFECTS_PASS_THROUGH_VIEW_H
#define EFFECTS_PASS_THROUGH_VIEW_H

#import <AppKit/AppKit.h>

// Custom view that doesn't intercept any events
// Used by drag effects to display visual overlays without blocking drag operations
@interface PassThroughView : NSView
@end

#endif // EFFECTS_PASS_THROUGH_VIEW_H