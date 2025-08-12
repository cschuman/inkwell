#pragma once

#include <string>
#include <vector>
#include <functional>
#include <chrono>

namespace mdviewer::ui {

struct Color {
    float r, g, b, a;
    
    static Color fromHex(uint32_t hex, float alpha = 1.0f) {
        return {
            ((hex >> 16) & 0xFF) / 255.0f,
            ((hex >> 8) & 0xFF) / 255.0f,
            (hex & 0xFF) / 255.0f,
            alpha
        };
    }
    
    Color withAlpha(float alpha) const {
        return {r, g, b, alpha};
    }
    
    Color interpolate(const Color& other, float t) const {
        return {
            r + (other.r - r) * t,
            g + (other.g - g) * t,
            b + (other.b - b) * t,
            a + (other.a - a) * t
        };
    }
};

struct Gradient {
    std::vector<std::pair<float, Color>> stops;
    
    Color sample(float t) const {
        if (stops.empty()) return {0, 0, 0, 0};
        if (stops.size() == 1) return stops[0].second;
        
        for (size_t i = 1; i < stops.size(); ++i) {
            if (t <= stops[i].first) {
                float range = stops[i].first - stops[i-1].first;
                float local_t = (t - stops[i-1].first) / range;
                return stops[i-1].second.interpolate(stops[i].second, local_t);
            }
        }
        return stops.back().second;
    }
};

struct Shadow {
    float offset_x = 0;
    float offset_y = 2;
    float blur_radius = 8;
    float spread = 0;
    Color color = {0, 0, 0, 0.15f};
};

struct AnimationCurve {
    enum Type {
        Linear,
        EaseIn,
        EaseOut,
        EaseInOut,
        Spring,
        Bounce,
        Elastic
    };
    
    Type type = EaseInOut;
    float duration = 0.3f;
    float damping = 0.8f;  // For spring animations
    float stiffness = 100.0f;  // For spring animations
    
    float evaluate(float t) const;
};

struct DesignTokens {
    // Spacing scale (in points)
    struct Spacing {
        static constexpr float xs = 4;
        static constexpr float sm = 8;
        static constexpr float md = 16;
        static constexpr float lg = 24;
        static constexpr float xl = 32;
        static constexpr float xxl = 48;
        static constexpr float xxxl = 64;
    };
    
    // Border radius scale
    struct Radius {
        static constexpr float none = 0;
        static constexpr float sm = 4;
        static constexpr float md = 8;
        static constexpr float lg = 12;
        static constexpr float xl = 16;
        static constexpr float full = 9999;
    };
    
    // Typography scale
    struct Typography {
        struct Size {
            static constexpr float xs = 11;
            static constexpr float sm = 13;
            static constexpr float base = 15;
            static constexpr float lg = 17;
            static constexpr float xl = 20;
            static constexpr float xxl = 24;
            static constexpr float xxxl = 32;
            static constexpr float display = 48;
        };
        
        struct Weight {
            static constexpr float thin = 100;
            static constexpr float light = 300;
            static constexpr float regular = 400;
            static constexpr float medium = 500;
            static constexpr float semibold = 600;
            static constexpr float bold = 700;
            static constexpr float black = 900;
        };
        
        struct LineHeight {
            static constexpr float tight = 1.2f;
            static constexpr float normal = 1.5f;
            static constexpr float relaxed = 1.75f;
            static constexpr float loose = 2.0f;
        };
    };
    
    // Z-index layers
    struct Layer {
        static constexpr int base = 0;
        static constexpr int raised = 10;
        static constexpr int overlay = 100;
        static constexpr int modal = 200;
        static constexpr int popover = 300;
        static constexpr int tooltip = 400;
        static constexpr int notification = 500;
    };
};

class Theme {
public:
    struct Colors {
        // Brand colors
        Color primary = Color::fromHex(0x007AFF);
        Color secondary = Color::fromHex(0x5856D6);
        Color accent = Color::fromHex(0xFF3B30);
        
        // Semantic colors
        Color success = Color::fromHex(0x34C759);
        Color warning = Color::fromHex(0xFF9500);
        Color error = Color::fromHex(0xFF3B30);
        Color info = Color::fromHex(0x007AFF);
        
        // Background layers
        Color background = Color::fromHex(0xFFFFFF);
        Color surface = Color::fromHex(0xF2F2F7);
        Color elevated = Color::fromHex(0xFFFFFF);
        
        // Text colors
        Color text_primary = Color::fromHex(0x000000, 0.85f);
        Color text_secondary = Color::fromHex(0x3C3C43, 0.6f);
        Color text_tertiary = Color::fromHex(0x3C3C43, 0.3f);
        Color text_inverted = Color::fromHex(0xFFFFFF);
        
        // UI element colors
        Color border = Color::fromHex(0xC6C6C8, 0.5f);
        Color divider = Color::fromHex(0x3C3C43, 0.12f);
        Color overlay = Color::fromHex(0x000000, 0.4f);
        
        // Code highlighting
        Color code_background = Color::fromHex(0xF2F2F7);
        Color code_keyword = Color::fromHex(0x9B2393);
        Color code_string = Color::fromHex(0xD12F1B);
        Color code_number = Color::fromHex(0x0E73A2);
        Color code_comment = Color::fromHex(0x5D6C79);
        Color code_function = Color::fromHex(0x4B21B0);
        Color code_variable = Color::fromHex(0x0F68A0);
        
        // Interactive states
        Color hover = Color::fromHex(0x007AFF, 0.1f);
        Color pressed = Color::fromHex(0x007AFF, 0.2f);
        Color selected = Color::fromHex(0x007AFF, 0.15f);
        Color focus = Color::fromHex(0x007AFF, 0.4f);
        Color disabled = Color::fromHex(0x3C3C43, 0.18f);
    };
    
    struct Effects {
        // Shadows for elevation
        Shadow elevation_low = {0, 1, 3, 0, {0, 0, 0, 0.12f}};
        Shadow elevation_medium = {0, 2, 8, 0, {0, 0, 0, 0.15f}};
        Shadow elevation_high = {0, 4, 16, 0, {0, 0, 0, 0.18f}};
        Shadow elevation_ultra = {0, 8, 32, 0, {0, 0, 0, 0.25f}};
        
        // Gradients
        Gradient primary_gradient = {
            {{0.0f, Color::fromHex(0x007AFF)},
             {1.0f, Color::fromHex(0x5856D6)}}
        };
        
        Gradient surface_gradient = {
            {{0.0f, Color::fromHex(0xFFFFFF)},
             {1.0f, Color::fromHex(0xF2F2F7)}}
        };
        
        // Blur effects
        float background_blur = 20.0f;
        float overlay_blur = 10.0f;
        
        // Material properties
        float material_opacity = 0.8f;
        float glass_opacity = 0.95f;
    };
    
    Colors colors;
    Effects effects;
    bool is_dark = false;
    
    static Theme light();
    static Theme dark();
    void interpolate(const Theme& target, float t);
};

class AnimationController {
public:
    using UpdateCallback = std::function<void(float)>;
    using CompleteCallback = std::function<void()>;
    
    void animate(float from, float to, float duration, 
                 AnimationCurve curve,
                 UpdateCallback on_update,
                 CompleteCallback on_complete = nullptr);
    
    void spring_animate(float from, float to,
                       float stiffness, float damping,
                       UpdateCallback on_update,
                       CompleteCallback on_complete = nullptr);
    
    void update(float delta_time);
    void cancel_all();
    bool is_animating() const;
    
private:
    struct Animation {
        float from;
        float to;
        float current;
        float duration;
        float elapsed = 0;
        AnimationCurve curve;
        UpdateCallback on_update;
        CompleteCallback on_complete;
        bool is_spring = false;
        float velocity = 0;
    };
    
    std::vector<Animation> animations_;
};

class HapticFeedback {
public:
    enum Type {
        Light,
        Medium,
        Heavy,
        Selection,
        Success,
        Warning,
        Error
    };
    
    static void perform(Type type);
};

class SoundEffects {
public:
    enum Sound {
        Tap,
        Navigation,
        Success,
        Error,
        Notification,
        Swoosh
    };
    
    static void play(Sound sound, float volume = 1.0f);
};

}  // namespace mdviewer::ui