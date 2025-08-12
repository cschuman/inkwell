#pragma once

#include <vector>
#include <string>
#include <memory>
#include "core/document.h"

// CoreText types will be defined by including CoreText.h in the implementation file
// We use void* in the header to avoid conflicts
typedef void* CTFontRef_t;
typedef void* CTLineRef_t;
typedef void* CTFrameRef_t;

namespace mdviewer {

class TextLayout {
public:
    struct Glyph {
        uint32_t codepoint;
        float x, y;
        float width, height;
        float advance;
        float baseline_offset;
    };
    
    struct Line {
        std::vector<Glyph> glyphs;
        float x, y;
        float width, height;
        float baseline;
        size_t char_start, char_end;
    };
    
    struct Paragraph {
        std::vector<Line> lines;
        float x, y;
        float width, height;
        float line_spacing;
    };
    
    struct LayoutOptions {
        float max_width = 800.0f;
        float font_size = 16.0f;
        float line_height = 1.6f;
        float paragraph_spacing = 1.0f;
        std::string font_family = "SF Pro Text";
        std::string code_font_family = "SF Mono";
        
        bool hyphenation = true;
        bool justification = false;
        bool kerning = true;
        bool ligatures = true;
    };
    
    TextLayout();
    ~TextLayout();
    
    void set_options(const LayoutOptions& options);
    
    std::vector<Paragraph> layout_document(const Document* doc);
    
    Paragraph layout_node(const Document::Node* node, float max_width);
    
    Line layout_line(const std::string& text, float max_width, CTFontRef_t font);
    
    float measure_text(const std::string& text, CTFontRef_t font);
    
    void apply_smart_typography(Paragraph& paragraph);
    
private:
    class Impl;
    std::unique_ptr<Impl> impl_;
    
    LayoutOptions options_;
    
    CTFontRef_t get_font_for_node(const Document::Node* node);
    void apply_orphan_widow_prevention(std::vector<Line>& lines);
    void apply_optical_margin_alignment(Line& line);
};

class GlyphCache {
public:
    struct CachedGlyph {
        uint32_t codepoint;
        float advance;
        float bearing_x, bearing_y;
        float width, height;
        std::vector<uint8_t> bitmap;
    };
    
    GlyphCache();
    ~GlyphCache();
    
    const CachedGlyph* get_glyph(uint32_t codepoint, CTFontRef_t font);
    
    void clear();
    
    size_t memory_usage() const;
    
private:
    class Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace mdviewer