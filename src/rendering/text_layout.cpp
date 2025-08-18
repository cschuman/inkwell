#include "rendering/text_layout.h"
#include <CoreText/CoreText.h>
#include <unordered_map>
#include <algorithm>

namespace mdviewer {

class TextLayout::Impl {
public:
    std::unordered_map<std::string, CTFontRef_t> font_cache;
    std::unique_ptr<GlyphCache> glyph_cache;
    
    Impl() : glyph_cache(std::make_unique<GlyphCache>()) {}
    
    ~Impl() {
        for (auto& [key, font] : font_cache) {
            if (font) CFRelease((CFTypeRef)font);
        }
    }
    
    CTFontRef_t get_or_create_font(const std::string& family, float size) {
        std::string key = family + "_" + std::to_string(size);
        
        auto it = font_cache.find(key);
        if (it != font_cache.end()) {
            return it->second;
        }
        
        CFStringRef family_name = CFStringCreateWithCString(
            kCFAllocatorDefault,
            family.c_str(),
            kCFStringEncodingUTF8
        );
        
        CTFontRef_t font = (CTFontRef_t)CTFontCreateWithName(family_name, size, nullptr);
        CFRelease(family_name);
        
        font_cache[key] = font;
        return font;
    }
};

TextLayout::TextLayout() : impl_(std::make_unique<Impl>()) {}
TextLayout::~TextLayout() = default;

void TextLayout::set_options(const LayoutOptions& options) {
    options_ = options;
}

std::vector<TextLayout::Paragraph> TextLayout::layout_document(const Document* doc) {
    std::vector<Paragraph> paragraphs;
    
    if (!doc || !doc->get_root()) {
        return paragraphs;
    }
    
    float y_offset = 0.0f;
    
    doc->visit([this, &paragraphs, &y_offset](const Document::Node& node) {
        if (node.type == Document::NodeType::Paragraph ||
            node.type == Document::NodeType::Heading ||
            node.type == Document::NodeType::CodeBlock) {
            
            Paragraph para = layout_node(&node, options_.max_width);
            para.y = y_offset;
            
            y_offset += para.height + options_.paragraph_spacing * options_.font_size;
            
            apply_smart_typography(para);
            paragraphs.push_back(std::move(para));
        }
    });
    
    return paragraphs;
}

TextLayout::Paragraph TextLayout::layout_node(const Document::Node* node, float max_width) {
    Paragraph paragraph;
    
    CTFontRef_t font = get_font_for_node(node);
    
    // Collect all text from the node
    std::string full_text;
    std::function<void(const Document::Node*)> collect_text = 
        [&full_text, &collect_text](const Document::Node* n) {
        if (n->type == Document::NodeType::Text) {
            full_text += n->content;
        }
        for (const auto& child : n->children) {
            collect_text(child.get());
        }
    };
    
    collect_text(node);
    
    // Create attributed string for Core Text
    CFStringRef cf_text = CFStringCreateWithCString(
        kCFAllocatorDefault,
        full_text.c_str(),
        kCFStringEncodingUTF8
    );
    
    CFMutableAttributedStringRef attr_string = CFAttributedStringCreateMutable(
        kCFAllocatorDefault,
        CFStringGetLength(cf_text)
    );
    
    CFAttributedStringReplaceString(attr_string, CFRangeMake(0, 0), cf_text);
    
    // Apply font
    CFAttributedStringSetAttribute(
        attr_string,
        CFRangeMake(0, CFAttributedStringGetLength(attr_string)),
        kCTFontAttributeName,
        (CTFontRef)font
    );
    
    // Apply paragraph style
    CTTextAlignment alignment = options_.justification ? 
        kCTTextAlignmentJustified : kCTTextAlignmentLeft;
    
    CTParagraphStyleSetting settings[] = {
        {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
        {kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(float), &options_.line_height}
    };
    
    CTParagraphStyleRef para_style = CTParagraphStyleCreate(settings, 2);
    CFAttributedStringSetAttribute(
        attr_string,
        CFRangeMake(0, CFAttributedStringGetLength(attr_string)),
        kCTParagraphStyleAttributeName,
        para_style
    );
    
    // Create framesetter and frame
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attr_string);
    
    CGPathRef path = CGPathCreateWithRect(
        CGRectMake(0, 0, max_width, CGFLOAT_MAX),
        nullptr
    );
    
    CTFrameRef frame = CTFramesetterCreateFrame(
        framesetter,
        CFRangeMake(0, CFAttributedStringGetLength(attr_string)),
        path,
        nullptr
    );
    
    // Extract lines
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex line_count = CFArrayGetCount(lines);
    
    std::vector<CGPoint> origins(line_count);
    CTFrameGetLineOrigins(frame, CFRangeMake(0, line_count), origins.data());
    
    for (CFIndex i = 0; i < line_count; ++i) {
        CTLineRef ct_line = (CTLineRef)CFArrayGetValueAtIndex(lines, i);
        
        Line line;
        line.x = origins[i].x;
        line.y = origins[i].y;
        
        // Get line metrics
        CGFloat ascent, descent, leading;
        line.width = CTLineGetTypographicBounds(ct_line, &ascent, &descent, &leading);
        line.height = ascent + descent + leading;
        line.baseline = ascent;
        
        // Get character range
        CFRange range = CTLineGetStringRange(ct_line);
        line.char_start = range.location;
        line.char_end = range.location + range.length;
        
        // Extract glyphs
        CFArrayRef runs = CTLineGetGlyphRuns(ct_line);
        CFIndex run_count = CFArrayGetCount(runs);
        
        for (CFIndex j = 0; j < run_count; ++j) {
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runs, j);
            CFIndex glyph_count = CTRunGetGlyphCount(run);
            
            std::vector<CGGlyph> glyphs(glyph_count);
            std::vector<CGPoint> positions(glyph_count);
            std::vector<CGSize> advances(glyph_count);
            
            CTRunGetGlyphs(run, CFRangeMake(0, glyph_count), glyphs.data());
            CTRunGetPositions(run, CFRangeMake(0, glyph_count), positions.data());
            CTRunGetAdvances(run, CFRangeMake(0, glyph_count), advances.data());
            
            for (CFIndex k = 0; k < glyph_count; ++k) {
                Glyph glyph;
                glyph.codepoint = glyphs[k];
                glyph.x = positions[k].x;
                glyph.y = positions[k].y;
                glyph.advance = advances[k].width;
                
                line.glyphs.push_back(glyph);
            }
        }
        
        paragraph.lines.push_back(std::move(line));
    }
    
    // Calculate paragraph dimensions
    if (!paragraph.lines.empty()) {
        paragraph.width = std::max_element(
            paragraph.lines.begin(),
            paragraph.lines.end(),
            [](const Line& a, const Line& b) { return a.width < b.width; }
        )->width;
        
        paragraph.height = std::abs(origins[0].y - origins[line_count - 1].y) +
                          paragraph.lines.back().height;
    }
    
    paragraph.line_spacing = options_.line_height;
    
    // Cleanup
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(para_style);
    CFRelease(attr_string);
    CFRelease(cf_text);
    
    return paragraph;
}

TextLayout::Line TextLayout::layout_line(const std::string& text, float max_width, CTFontRef_t font) {
    Line line;
    
    CFStringRef cf_text = CFStringCreateWithCString(
        kCFAllocatorDefault,
        text.c_str(),
        kCFStringEncodingUTF8
    );
    
    CFMutableAttributedStringRef attr_string = CFAttributedStringCreateMutable(
        kCFAllocatorDefault,
        CFStringGetLength(cf_text)
    );
    
    CFAttributedStringReplaceString(attr_string, CFRangeMake(0, 0), cf_text);
    CFAttributedStringSetAttribute(
        attr_string,
        CFRangeMake(0, CFAttributedStringGetLength(attr_string)),
        kCTFontAttributeName,
        (CTFontRef)font
    );
    
    CTLineRef ct_line = CTLineCreateWithAttributedString(attr_string);
    
    CGFloat ascent, descent, leading;
    line.width = CTLineGetTypographicBounds(ct_line, &ascent, &descent, &leading);
    line.height = ascent + descent + leading;
    line.baseline = ascent;
    
    CFRelease(ct_line);
    CFRelease(attr_string);
    CFRelease(cf_text);
    
    return line;
}

float TextLayout::measure_text(const std::string& text, CTFontRef_t font) {
    CFStringRef cf_text = CFStringCreateWithCString(
        kCFAllocatorDefault,
        text.c_str(),
        kCFStringEncodingUTF8
    );
    
    CFMutableAttributedStringRef attr_string = CFAttributedStringCreateMutable(
        kCFAllocatorDefault,
        CFStringGetLength(cf_text)
    );
    
    CFAttributedStringReplaceString(attr_string, CFRangeMake(0, 0), cf_text);
    CFAttributedStringSetAttribute(
        attr_string,
        CFRangeMake(0, CFAttributedStringGetLength(attr_string)),
        kCTFontAttributeName,
        (CTFontRef)font
    );
    
    CTLineRef line = CTLineCreateWithAttributedString(attr_string);
    CGFloat width = CTLineGetTypographicBounds(line, nullptr, nullptr, nullptr);
    
    CFRelease(line);
    CFRelease(attr_string);
    CFRelease(cf_text);
    
    return width;
}

CTFontRef_t TextLayout::get_font_for_node(const Document::Node* node) {
    std::string family = options_.font_family;
    float size = options_.font_size;
    
    if (node->type == Document::NodeType::Heading) {
        size *= (2.5f - node->heading_level * 0.25f);
    } else if (node->type == Document::NodeType::Code ||
               node->type == Document::NodeType::CodeBlock) {
        family = options_.code_font_family;
        size *= 0.9f;
    }
    
    return impl_->get_or_create_font(family, size);
}

void TextLayout::apply_smart_typography(Paragraph& paragraph) {
    if (paragraph.lines.size() > 1) {
        apply_orphan_widow_prevention(paragraph.lines);
    }
    
    for (auto& line : paragraph.lines) {
        apply_optical_margin_alignment(line);
    }
}

void TextLayout::apply_orphan_widow_prevention(std::vector<Line>& lines) {
    // Prevent single words on last line (widow)
    if (lines.size() >= 2) {
        Line& last_line = lines.back();
        Line& second_last = lines[lines.size() - 2];
        
        // Count words in last line
        int word_count = 0;
        for (const auto& glyph : last_line.glyphs) {
            if (glyph.codepoint == ' ') word_count++;
        }
        
        if (word_count == 0 && !last_line.glyphs.empty()) {
            // Single word on last line - try to pull word from previous line
            // This would require re-layout of the last two lines
        }
    }
}

void TextLayout::apply_optical_margin_alignment(Line& line) {
    // Adjust line position for optical alignment
    // Punctuation marks hang slightly outside the margin
    if (!line.glyphs.empty()) {
        uint32_t first_char = line.glyphs.front().codepoint;
        
        // Hanging punctuation
        if (first_char == '"' || first_char == '\'' || first_char == '(' ||
            first_char == '[' || first_char == '{') {
            line.x -= line.glyphs.front().advance * 0.3f;
        }
    }
}

// GlyphCache implementation
class GlyphCache::Impl {
public:
    std::unordered_map<uint64_t, CachedGlyph> cache;
    size_t total_memory = 0;
    
    uint64_t make_key(uint32_t codepoint, CTFontRef_t font) {
        uint64_t font_hash = reinterpret_cast<uintptr_t>(font);
        return (uint64_t(codepoint) << 32) | (font_hash & 0xFFFFFFFF);
    }
};

GlyphCache::GlyphCache() : impl_(std::make_unique<Impl>()) {}
GlyphCache::~GlyphCache() = default;

const GlyphCache::CachedGlyph* GlyphCache::get_glyph(uint32_t codepoint, CTFontRef_t font) {
    uint64_t key = impl_->make_key(codepoint, font);
    
    auto it = impl_->cache.find(key);
    if (it != impl_->cache.end()) {
        return &it->second;
    }
    
    // Render glyph and cache it
    CachedGlyph glyph;
    glyph.codepoint = codepoint;
    
    // Get glyph metrics from Core Text
    CGGlyph cg_glyph;
    UniChar character = codepoint;
    CTFontGetGlyphsForCharacters((CTFontRef)font, &character, &cg_glyph, 1);
    
    CGSize advance;
    CTFontGetAdvancesForGlyphs((CTFontRef)font, kCTFontOrientationDefault, &cg_glyph, &advance, 1);
    glyph.advance = advance.width;
    
    CGRect bbox;
    CTFontGetBoundingRectsForGlyphs((CTFontRef)font, kCTFontOrientationDefault, &cg_glyph, &bbox, 1);
    glyph.width = bbox.size.width;
    glyph.height = bbox.size.height;
    glyph.bearing_x = bbox.origin.x;
    glyph.bearing_y = bbox.origin.y;
    
    impl_->cache[key] = std::move(glyph);
    impl_->total_memory += sizeof(CachedGlyph) + glyph.bitmap.size();
    
    return &impl_->cache[key];
}

void GlyphCache::clear() {
    impl_->cache.clear();
    impl_->total_memory = 0;
}

size_t GlyphCache::memory_usage() const {
    return impl_->total_memory;
}

} // namespace mdviewer