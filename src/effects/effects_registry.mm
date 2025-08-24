#import "../../include/effects/effect_manager.h"
#import "../../include/effects/drag_effect_protocol.h"

// Forward declare the simple effect that is defined in its own file
@interface NoEffect : BaseDragEffect
@end

@interface EffectsRegistry : NSObject
+ (void)registerAllBuiltInEffects;
@end

@implementation EffectsRegistry

+ (void)registerAllBuiltInEffects {
    EffectManager* manager = [EffectManager sharedManager];
    
    // Register only the simple no-op effect
    [manager registerEffect:[[NoEffect alloc] init]];
    
    // Set default effect
    [manager selectEffectByName:@"Classic Blue"];
    
    NSLog(@"Registered %lu built-in effect(s)", (unsigned long)manager.availableEffects.count);
}

@end

// Remove auto-register - will be called manually when app is ready