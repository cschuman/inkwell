#import <AppKit/AppKit.h>
#include "ui/design_system.h"

namespace mdviewer::ui {

void HapticFeedback::perform(Type type) {
    // Note: macOS doesn't have system-wide haptic feedback like iOS
    // This would require Force Touch trackpad support
    // For now, we'll use NSHapticFeedbackManager if available
    
    if (@available(macOS 10.11, *)) {
        NSHapticFeedbackManager* manager = [NSHapticFeedbackManager defaultPerformer];
        
        NSHapticFeedbackPattern pattern;
        switch (type) {
            case Light:
            case Selection:
                pattern = NSHapticFeedbackPatternGeneric;
                break;
            case Medium:
            case Success:
                pattern = NSHapticFeedbackPatternAlignment;
                break;
            case Heavy:
            case Warning:
            case Error:
                pattern = NSHapticFeedbackPatternLevelChange;
                break;
            default:
                pattern = NSHapticFeedbackPatternGeneric;
                break;
        }
        
        [manager performFeedbackPattern:pattern
                       performanceTime:NSHapticFeedbackPerformanceTimeDefault];
    }
}

void SoundEffects::play(Sound sound, float volume) {
    // Play system sounds
    NSSound* ns_sound = nil;
    
    switch (sound) {
        case Tap:
            ns_sound = [NSSound soundNamed:@"Tink"];
            break;
        case Navigation:
            ns_sound = [NSSound soundNamed:@"Pop"];
            break;
        case Success:
            ns_sound = [NSSound soundNamed:@"Glass"];
            break;
        case Error:
            ns_sound = [NSSound soundNamed:@"Basso"];
            break;
        case Notification:
            ns_sound = [NSSound soundNamed:@"Ping"];
            break;
        case Swoosh:
            ns_sound = [NSSound soundNamed:@"Whoosh"];
            break;
    }
    
    if (ns_sound) {
        [ns_sound setVolume:volume];
        [ns_sound play];
    }
}

}  // namespace mdviewer::ui