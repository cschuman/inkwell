#pragma once

#import <Cocoa/Cocoa.h>
#import "../../include/effects/effect_manager.h"
#import "../../include/effects/drag_effect_protocol.h"

// Helper class to integrate effects with existing drag & drop
@interface DragIntegrationHelper : NSObject

+ (void)integrateWithViewController:(NSViewController*)viewController;
+ (void)setupEffectSwitchingHotkeys:(NSView*)view;
+ (void)showEffectSelectionMenu;
+ (void)showEffectDebugOverlay:(NSView*)parentView;

@end

// Category to add effect support to existing view controller
@interface NSViewController (DragEffects)

- (void)enableDragEffects;
- (void)switchToNextEffect;
- (void)switchToPreviousEffect;
- (void)showEffectPicker;

@end