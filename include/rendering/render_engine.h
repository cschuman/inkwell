#pragma once

#include <memory>
#include <array>
#include "core/virtual_dom.h"

#ifdef __OBJC__
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#else
typedef void* id;
#endif

namespace mdviewer {

class GlyphAtlas;
class TextLayout;

class RenderEngine {
public:
    struct ScrollPosition {
        float y;
        float velocity;
    };
    
    struct RenderStats {
        float fps;
        size_t draw_calls;
        size_t vertices_rendered;
        float frame_time_ms;
    };
    
    RenderEngine();
    ~RenderEngine();
    
    bool initialize(void* metal_device, void* metal_layer);
    
    void set_virtual_dom(VirtualDOM* dom);
    
    void render(ScrollPosition scroll);
    
    void resize(float width, float height);
    
    void set_focus_mode(bool enabled, float focus_y = 0);
    
    void set_typewriter_mode(bool enabled);
    
    const RenderStats& get_stats() const { return stats_; }
    
    void set_theme(const struct Theme& theme);
    
private:
    class Impl;
    std::unique_ptr<Impl> impl_;
    
    VirtualDOM* virtual_dom_ = nullptr;
    
    // Triple buffering
    static constexpr size_t kBufferCount = 3;
    size_t current_buffer_ = 0;
    
    struct {
        float width = 0;
        float height = 0;
    } viewport_;
    
    bool focus_mode_ = false;
    float focus_y_ = 0;
    bool typewriter_mode_ = false;
    
    RenderStats stats_;
    
    std::unique_ptr<GlyphAtlas> glyph_atlas_;
    std::unique_ptr<TextLayout> text_layout_;
    
    void render_visible_range(ScrollPosition pos);
    void update_focus_effect(float y);
};

struct Theme {
    struct Color {
        float r, g, b, a;
    };
    
    Color background = {1.0f, 1.0f, 1.0f, 1.0f};
    Color text = {0.1f, 0.1f, 0.1f, 1.0f};
    Color heading = {0.0f, 0.0f, 0.0f, 1.0f};
    Color code_background = {0.95f, 0.95f, 0.95f, 1.0f};
    Color code_text = {0.2f, 0.2f, 0.2f, 1.0f};
    Color link = {0.0f, 0.4f, 0.8f, 1.0f};
    Color quote_border = {0.7f, 0.7f, 0.7f, 1.0f};
    
    float font_size = 16.0f;
    float line_height = 1.6f;
    float paragraph_spacing = 1.0f;
    
    std::string font_family = "SF Pro Text";
    std::string code_font_family = "SF Mono";
};

} // namespace mdviewer