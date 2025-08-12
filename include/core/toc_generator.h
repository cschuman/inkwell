#pragma once

#include "core/document.h"
#include <functional>

namespace mdviewer {

class TOCWidget {
public:
    struct Config {
        bool auto_hide = true;
        bool highlight_current = true;
        float width = 250.0f;
        float opacity = 0.95f;
        int max_depth = 3;
        bool show_numbers = false;
    };
    
    using NavigationCallback = std::function<void(size_t node_index)>;
    
    TOCWidget();
    ~TOCWidget();
    
    void set_document(const Document* doc);
    
    void set_config(const Config& config);
    
    void set_navigation_callback(NavigationCallback callback);
    
    void set_current_position(float scroll_y);
    
    void toggle_visibility();
    
    bool is_visible() const { return visible_; }
    
    void render(float x, float y);
    
    bool handle_mouse_event(float x, float y, bool clicked);
    
private:
    const Document* document_ = nullptr;
    Config config_;
    NavigationCallback nav_callback_;
    
    bool visible_ = false;
    float current_scroll_y_ = 0;
    size_t highlighted_index_ = 0;
    
    struct EntryRect {
        float x, y, width, height;
        size_t node_index;
        int level;
    };
    
    std::vector<EntryRect> entry_rects_;
    
    void update_highlighted_entry();
    void build_entry_rects();
    float render_entry(const Document::TableOfContents::Entry& entry, 
                       float x, float y, int depth);
};

} // namespace mdviewer