#include "ui/design_system.h"
#include <cmath>
#include <algorithm>

#ifndef M_PI_F
#define M_PI_F 3.14159265358979323846f
#endif

namespace mdviewer::ui {

float AnimationCurve::evaluate(float t) const {
    t = std::clamp(t, 0.0f, 1.0f);
    
    switch (type) {
        case Linear:
            return t;
            
        case EaseIn:
            return t * t;
            
        case EaseOut:
            return t * (2.0f - t);
            
        case EaseInOut:
            if (t < 0.5f) {
                return 2.0f * t * t;
            } else {
                return -1.0f + (4.0f - 2.0f * t) * t;
            }
            
        case Spring: {
            float omega = std::sqrt(stiffness);
            float zeta = damping / (2.0f * omega);
            
            if (zeta < 1.0f) {  // Underdamped
                float wd = omega * std::sqrt(1.0f - zeta * zeta);
                float value = 1.0f - std::exp(-zeta * omega * t) * 
                              (std::cos(wd * t) + (zeta * omega / wd) * std::sin(wd * t));
                return value;
            } else {  // Critically damped or overdamped
                return 1.0f - std::exp(-omega * t) * (1.0f + omega * t);
            }
        }
            
        case Bounce: {
            if (t < 0.363636f) {
                return 7.5625f * t * t;
            } else if (t < 0.727272f) {
                t -= 0.545454f;
                return 7.5625f * t * t + 0.75f;
            } else if (t < 0.909090f) {
                t -= 0.818181f;
                return 7.5625f * t * t + 0.9375f;
            } else {
                t -= 0.954545f;
                return 7.5625f * t * t + 0.984375f;
            }
        }
            
        case Elastic: {
            if (t == 0 || t == 1) return t;
            float p = 0.3f;
            float s = p / 4.0f;
            t -= 1.0f;
            return -std::pow(2.0f, 10.0f * t) * std::sin((t - s) * 2.0f * M_PI / p);
        }
            
        default:
            return t;
    }
}

Theme Theme::light() {
    Theme theme;
    theme.is_dark = false;
    
    // Light theme uses default colors
    return theme;
}

Theme Theme::dark() {
    Theme theme;
    theme.is_dark = true;
    
    // Dark theme colors
    theme.colors.primary = Color::fromHex(0x0A84FF);
    theme.colors.secondary = Color::fromHex(0x5E5CE6);
    theme.colors.accent = Color::fromHex(0xFF453A);
    
    theme.colors.success = Color::fromHex(0x32D74B);
    theme.colors.warning = Color::fromHex(0xFF9F0A);
    theme.colors.error = Color::fromHex(0xFF453A);
    theme.colors.info = Color::fromHex(0x64D2FF);
    
    theme.colors.background = Color::fromHex(0x000000);
    theme.colors.surface = Color::fromHex(0x1C1C1E);
    theme.colors.elevated = Color::fromHex(0x2C2C2E);
    
    theme.colors.text_primary = Color::fromHex(0xFFFFFF, 0.85f);
    theme.colors.text_secondary = Color::fromHex(0xEBEBF5, 0.6f);
    theme.colors.text_tertiary = Color::fromHex(0xEBEBF5, 0.3f);
    theme.colors.text_inverted = Color::fromHex(0x000000);
    
    theme.colors.border = Color::fromHex(0x38383A, 0.65f);
    theme.colors.divider = Color::fromHex(0xFFFFFF, 0.08f);
    theme.colors.overlay = Color::fromHex(0x000000, 0.6f);
    
    theme.colors.code_background = Color::fromHex(0x1C1C1E);
    theme.colors.code_keyword = Color::fromHex(0xFF79C6);
    theme.colors.code_string = Color::fromHex(0x95E454);
    theme.colors.code_number = Color::fromHex(0xFF9F0A);
    theme.colors.code_comment = Color::fromHex(0x6C7986);
    theme.colors.code_function = Color::fromHex(0x82AAFF);
    theme.colors.code_variable = Color::fromHex(0x89DDFF);
    
    theme.colors.hover = Color::fromHex(0x0A84FF, 0.15f);
    theme.colors.pressed = Color::fromHex(0x0A84FF, 0.25f);
    theme.colors.selected = Color::fromHex(0x0A84FF, 0.2f);
    theme.colors.focus = Color::fromHex(0x0A84FF, 0.5f);
    theme.colors.disabled = Color::fromHex(0xEBEBF5, 0.16f);
    
    // Dark theme effects
    theme.effects.elevation_low = {0, 1, 4, 0, {0, 0, 0, 0.3f}};
    theme.effects.elevation_medium = {0, 2, 10, 0, {0, 0, 0, 0.4f}};
    theme.effects.elevation_high = {0, 4, 20, 0, {0, 0, 0, 0.5f}};
    theme.effects.elevation_ultra = {0, 8, 40, 0, {0, 0, 0, 0.6f}};
    
    theme.effects.primary_gradient = {
        {{0.0f, Color::fromHex(0x0A84FF)},
         {1.0f, Color::fromHex(0x5E5CE6)}}
    };
    
    theme.effects.surface_gradient = {
        {{0.0f, Color::fromHex(0x2C2C2E)},
         {1.0f, Color::fromHex(0x1C1C1E)}}
    };
    
    return theme;
}

void Theme::interpolate(const Theme& target, float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    
    // Interpolate all colors
    auto interpolate_color = [t](Color& current, const Color& target_color) {
        current = current.interpolate(target_color, t);
    };
    
    interpolate_color(colors.primary, target.colors.primary);
    interpolate_color(colors.secondary, target.colors.secondary);
    interpolate_color(colors.accent, target.colors.accent);
    
    interpolate_color(colors.success, target.colors.success);
    interpolate_color(colors.warning, target.colors.warning);
    interpolate_color(colors.error, target.colors.error);
    interpolate_color(colors.info, target.colors.info);
    
    interpolate_color(colors.background, target.colors.background);
    interpolate_color(colors.surface, target.colors.surface);
    interpolate_color(colors.elevated, target.colors.elevated);
    
    interpolate_color(colors.text_primary, target.colors.text_primary);
    interpolate_color(colors.text_secondary, target.colors.text_secondary);
    interpolate_color(colors.text_tertiary, target.colors.text_tertiary);
    interpolate_color(colors.text_inverted, target.colors.text_inverted);
    
    interpolate_color(colors.border, target.colors.border);
    interpolate_color(colors.divider, target.colors.divider);
    interpolate_color(colors.overlay, target.colors.overlay);
    
    interpolate_color(colors.code_background, target.colors.code_background);
    interpolate_color(colors.code_keyword, target.colors.code_keyword);
    interpolate_color(colors.code_string, target.colors.code_string);
    interpolate_color(colors.code_number, target.colors.code_number);
    interpolate_color(colors.code_comment, target.colors.code_comment);
    interpolate_color(colors.code_function, target.colors.code_function);
    interpolate_color(colors.code_variable, target.colors.code_variable);
    
    interpolate_color(colors.hover, target.colors.hover);
    interpolate_color(colors.pressed, target.colors.pressed);
    interpolate_color(colors.selected, target.colors.selected);
    interpolate_color(colors.focus, target.colors.focus);
    interpolate_color(colors.disabled, target.colors.disabled);
    
    // Interpolate shadow effects
    auto interpolate_shadow = [t](Shadow& current, const Shadow& target_shadow) {
        current.offset_x = current.offset_x + (target_shadow.offset_x - current.offset_x) * t;
        current.offset_y = current.offset_y + (target_shadow.offset_y - current.offset_y) * t;
        current.blur_radius = current.blur_radius + (target_shadow.blur_radius - current.blur_radius) * t;
        current.spread = current.spread + (target_shadow.spread - current.spread) * t;
        current.color = current.color.interpolate(target_shadow.color, t);
    };
    
    interpolate_shadow(effects.elevation_low, target.effects.elevation_low);
    interpolate_shadow(effects.elevation_medium, target.effects.elevation_medium);
    interpolate_shadow(effects.elevation_high, target.effects.elevation_high);
    interpolate_shadow(effects.elevation_ultra, target.effects.elevation_ultra);
    
    // Interpolate blur effects
    effects.background_blur = effects.background_blur + (target.effects.background_blur - effects.background_blur) * t;
    effects.overlay_blur = effects.overlay_blur + (target.effects.overlay_blur - effects.overlay_blur) * t;
    effects.material_opacity = effects.material_opacity + (target.effects.material_opacity - effects.material_opacity) * t;
    effects.glass_opacity = effects.glass_opacity + (target.effects.glass_opacity - effects.glass_opacity) * t;
}

void AnimationController::animate(float from, float to, float duration,
                                 AnimationCurve curve,
                                 UpdateCallback on_update,
                                 CompleteCallback on_complete) {
    Animation anim;
    anim.from = from;
    anim.to = to;
    anim.current = from;
    anim.duration = duration;
    anim.curve = curve;
    anim.on_update = on_update;
    anim.on_complete = on_complete;
    anim.is_spring = false;
    
    animations_.push_back(anim);
}

void AnimationController::spring_animate(float from, float to,
                                        float stiffness, float damping,
                                        UpdateCallback on_update,
                                        CompleteCallback on_complete) {
    Animation anim;
    anim.from = from;
    anim.to = to;
    anim.current = from;
    anim.duration = 5.0f;  // Max duration for spring animations
    anim.curve.type = AnimationCurve::Spring;
    anim.curve.stiffness = stiffness;
    anim.curve.damping = damping;
    anim.on_update = on_update;
    anim.on_complete = on_complete;
    anim.is_spring = true;
    
    animations_.push_back(anim);
}

void AnimationController::update(float delta_time) {
    auto it = animations_.begin();
    while (it != animations_.end()) {
        it->elapsed += delta_time;
        
        if (it->is_spring) {
            // Spring animation physics
            float target = it->to;
            float current = it->current;
            float velocity = it->velocity;
            
            float spring_force = (target - current) * it->curve.stiffness;
            float damping_force = -velocity * it->curve.damping;
            float acceleration = spring_force + damping_force;
            
            velocity += acceleration * delta_time;
            current += velocity * delta_time;
            
            it->velocity = velocity;
            it->current = current;
            
            // Check if animation is complete (settled)
            bool settled = std::abs(current - target) < 0.001f && std::abs(velocity) < 0.001f;
            
            if (it->on_update) {
                it->on_update(current);
            }
            
            if (settled || it->elapsed >= it->duration) {
                if (it->on_complete) {
                    it->on_complete();
                }
                it = animations_.erase(it);
            } else {
                ++it;
            }
        } else {
            // Regular curve-based animation
            float t = it->elapsed / it->duration;
            
            if (t >= 1.0f) {
                if (it->on_update) {
                    it->on_update(it->to);
                }
                if (it->on_complete) {
                    it->on_complete();
                }
                it = animations_.erase(it);
            } else {
                float progress = it->curve.evaluate(t);
                float value = it->from + (it->to - it->from) * progress;
                
                if (it->on_update) {
                    it->on_update(value);
                }
                ++it;
            }
        }
    }
}

void AnimationController::cancel_all() {
    animations_.clear();
}

bool AnimationController::is_animating() const {
    return !animations_.empty();
}

#ifndef __APPLE__

void HapticFeedback::perform(Type type) {
    // Stub for non-Apple platforms
}

void SoundEffects::play(Sound sound, float volume) {
    // Stub for non-Apple platforms
}

#endif

}  // namespace mdviewer::ui