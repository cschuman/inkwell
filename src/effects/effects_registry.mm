#import "../../include/effects/effect_manager.h"
#import "../../include/effects/drag_effect_protocol.h"

// Forward declare effect classes
@interface NoEffect : BaseDragEffect
@end

@interface RippleEffect : BaseDragEffect
@end

@interface ParticleEffect : BaseDragEffect
@end

@interface GravitationalWakeEffect : BaseDragEffect
@end

@interface LiquidGlassEffect : BaseDragEffect
@end

@interface EffectsRegistry : NSObject
+ (void)registerAllBuiltInEffects;
@end

@implementation EffectsRegistry

+ (void)registerAllBuiltInEffects {
    EffectManager* manager = [EffectManager sharedManager];
    
    // Register all built-in effects
    [manager registerEffect:[[NoEffect alloc] init]];
    [manager registerEffect:[[RippleEffect alloc] init]];
    [manager registerEffect:[[ParticleEffect alloc] init]];
    [manager registerEffect:[[GravitationalWakeEffect alloc] init]];
    [manager registerEffect:[[LiquidGlassEffect alloc] init]];
    
    // Set default effect
    [manager selectEffectByName:@"Classic Blue"];
    
    NSLog(@"Registered %lu built-in effects", (unsigned long)manager.availableEffects.count);
}

@end

// Remove auto-register - will be called manually when app is ready