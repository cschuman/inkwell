#pragma once

#import <Cocoa/Cocoa.h>

@class AnimationController;
@class Theme;

@interface MDEnhancedWindow : NSWindow
@end

@interface MDVibrancyView : NSVisualEffectView
@end

@interface MDFloatingPanel : NSView
@end

@interface MDAnimatedButton : NSButton
@end

@interface MDSidebarController : NSViewController
- (void)toggleSidebar;
@end