#pragma once

#include <memory>
#include <unordered_map>
#include <vector>

#ifdef __OBJC__
#import <Metal/Metal.h>
#else
typedef void* id;
#endif

namespace mdviewer {

class GlyphAtlas {
public:
    struct GlyphInfo {
        uint32_t codepoint;
        float u0, v0, u1, v1;  // Texture coordinates
        float width, height;
        float bearing_x, bearing_y;
        float advance;
    };
    
    struct AtlasMetrics {
        size_t texture_width = 2048;
        size_t texture_height = 2048;
        size_t padding = 2;
        size_t glyphs_cached = 0;
        float fill_percentage = 0.0f;
    };
    
    GlyphAtlas();
    ~GlyphAtlas();
    
    bool initialize(void* metal_device);
    
    const GlyphInfo* get_glyph(uint32_t codepoint, float font_size);
    
    void* get_texture() const;
    
    void clear();
    
    const AtlasMetrics& get_metrics() const { return metrics_; }
    
    void generate_sdf_glyph(uint32_t codepoint, float font_size);
    
private:
    class Impl;
    std::unique_ptr<Impl> impl_;
    
    AtlasMetrics metrics_;
    
    struct PackNode {
        int x, y;
        int width, height;
        bool used = false;
        std::unique_ptr<PackNode> left;
        std::unique_ptr<PackNode> right;
    };
    
    std::unique_ptr<PackNode> pack_root_;
    
    PackNode* insert_rect(PackNode* node, int width, int height);
    bool pack_glyph(const GlyphInfo& info, int& out_x, int& out_y);
};

class SDFGenerator {
public:
    static std::vector<float> generate_sdf(
        const uint8_t* bitmap,
        int width,
        int height,
        int spread
    );
    
    static void generate_sdf_simd(
        const uint8_t* bitmap,
        int width,
        int height,
        int spread,
        float* output
    );
    
private:
    static float distance_to_edge(
        const uint8_t* bitmap,
        int width,
        int height,
        int x,
        int y,
        int max_dist
    );
};

} // namespace mdviewer