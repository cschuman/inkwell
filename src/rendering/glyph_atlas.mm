#include "rendering/glyph_atlas.h"
#include <CoreText/CoreText.h>
#include <cmath>
#include <algorithm>
#ifdef __x86_64__
#include <immintrin.h>
#elif defined(__aarch64__)
#include <arm_neon.h>
#endif

// Define CTFontRef_t for consistency with text_layout.h
typedef void* CTFontRef_t;

#ifdef __OBJC__
#import <Metal/Metal.h>
#else
// Forward declarations for Metal types when not compiling as Objective-C
typedef struct MTLRegion {
    struct { size_t x, y, z; } origin;
    struct { size_t width, height, depth; } size;
} MTLRegion;

static inline MTLRegion MTLRegionMake2D(size_t x, size_t y, size_t width, size_t height) {
    MTLRegion region;
    region.origin.x = x; region.origin.y = y; region.origin.z = 0;
    region.size.width = width; region.size.height = height; region.size.depth = 1;
    return region;
}

enum {
    MTLPixelFormatR8Unorm = 10,
    MTLTextureUsageShaderRead = 0x0001,
    MTLStorageModeManaged = 1
};
#endif

namespace mdviewer {

class GlyphAtlas::Impl {
public:
    id<MTLDevice> device = nil;
    id<MTLTexture> texture = nil;
    std::unordered_map<uint64_t, GlyphInfo> glyph_map;
    std::vector<uint8_t> texture_data;
    int current_x = 0;
    int current_y = 0;
    int row_height = 0;
    
    uint64_t make_key(uint32_t codepoint, float font_size) {
        return (uint64_t(codepoint) << 32) | (uint32_t(font_size * 100));
    }
    
    bool create_texture(size_t width, size_t height) {
        MTLTextureDescriptor* descriptor = [MTLTextureDescriptor 
            texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                         width:width
                                        height:height
                                     mipmapped:NO];
        
        descriptor.usage = MTLTextureUsageShaderRead;
        descriptor.storageMode = MTLStorageModeManaged;
        
        texture = [device newTextureWithDescriptor:descriptor];
        
        if (texture) {
            texture_data.resize(width * height, 0);
            return true;
        }
        
        return false;
    }
    
    void upload_texture_region(int x, int y, int width, int height, const uint8_t* data) {
        if (!texture) return;
        
        MTLRegion region = MTLRegionMake2D(x, y, width, height);
        
        [texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:data
                    bytesPerRow:width];
    }
};

GlyphAtlas::GlyphAtlas() : impl_(std::make_unique<Impl>()) {
    metrics_.texture_width = 2048;
    metrics_.texture_height = 2048;
    metrics_.padding = 2;
    
    pack_root_ = std::make_unique<PackNode>();
    pack_root_->x = 0;
    pack_root_->y = 0;
    pack_root_->width = metrics_.texture_width;
    pack_root_->height = metrics_.texture_height;
}

GlyphAtlas::~GlyphAtlas() = default;

bool GlyphAtlas::initialize(void* metal_device) {
    impl_->device = (__bridge id<MTLDevice>)metal_device;
    
    if (!impl_->device) {
        return false;
    }
    
    return impl_->create_texture(metrics_.texture_width, metrics_.texture_height);
}

const GlyphAtlas::GlyphInfo* GlyphAtlas::get_glyph(uint32_t codepoint, float font_size) {
    uint64_t key = impl_->make_key(codepoint, font_size);
    
    auto it = impl_->glyph_map.find(key);
    if (it != impl_->glyph_map.end()) {
        return &it->second;
    }
    
    // Generate and cache the glyph
    generate_sdf_glyph(codepoint, font_size);
    
    it = impl_->glyph_map.find(key);
    if (it != impl_->glyph_map.end()) {
        return &it->second;
    }
    
    return nullptr;
}

void GlyphAtlas::generate_sdf_glyph(uint32_t codepoint, float font_size) {
    // Create Core Text font
    CTFontRef_t font = (CTFontRef_t)CTFontCreateWithName(CFSTR("SF Pro Text"), font_size, nullptr);
    
    // Get glyph for codepoint
    CGGlyph glyph;
    UniChar character = codepoint;
    CTFontGetGlyphsForCharacters((CTFontRef)font, &character, &glyph, 1);
    
    // Get glyph metrics
    CGSize advance;
    CTFontGetAdvancesForGlyphs((CTFontRef)font, kCTFontOrientationDefault, &glyph, &advance, 1);
    
    CGRect bbox;
    CTFontGetBoundingRectsForGlyphs((CTFontRef)font, kCTFontOrientationDefault, &glyph, &bbox, 1);
    
    // Add padding for SDF
    const int sdf_padding = 8;
    int width = std::ceil(bbox.size.width) + sdf_padding * 2;
    int height = std::ceil(bbox.size.height) + sdf_padding * 2;
    
    // Create bitmap context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(
        nullptr,
        width,
        height,
        8,
        width,
        colorSpace,
        kCGImageAlphaNone
    );
    
    // Clear to black
    CGContextSetGrayFillColor(context, 0.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    
    // Draw glyph in white
    CGContextSetGrayFillColor(context, 1.0, 1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextPosition(context, 
                            sdf_padding - bbox.origin.x,
                            sdf_padding - bbox.origin.y);
    
    CTFontDrawGlyphs((CTFontRef)font, &glyph, &CGPointZero, 1, context);
    
    // Get bitmap data
    uint8_t* bitmap = (uint8_t*)CGBitmapContextGetData(context);
    
    // Generate SDF
    std::vector<float> sdf_data = SDFGenerator::generate_sdf(
        bitmap, width, height, sdf_padding
    );
    
    // Convert SDF to uint8
    std::vector<uint8_t> sdf_uint8(sdf_data.size());
    for (size_t i = 0; i < sdf_data.size(); ++i) {
        float value = sdf_data[i] * 0.5f + 0.5f; // Map [-1, 1] to [0, 1]
        sdf_uint8[i] = std::min(255, std::max(0, int(value * 255)));
    }
    
    // Find location in atlas
    int atlas_x, atlas_y;
    if (pack_glyph({codepoint, 0, 0, 0, 0, (float)width, (float)height}, atlas_x, atlas_y)) {
        // Upload to texture
        impl_->upload_texture_region(atlas_x, atlas_y, width, height, sdf_uint8.data());
        
        // Create glyph info
        GlyphInfo info;
        info.codepoint = codepoint;
        info.u0 = float(atlas_x) / metrics_.texture_width;
        info.v0 = float(atlas_y) / metrics_.texture_height;
        info.u1 = float(atlas_x + width) / metrics_.texture_width;
        info.v1 = float(atlas_y + height) / metrics_.texture_height;
        info.width = bbox.size.width;
        info.height = bbox.size.height;
        info.bearing_x = bbox.origin.x;
        info.bearing_y = bbox.origin.y;
        info.advance = advance.width;
        
        uint64_t key = impl_->make_key(codepoint, font_size);
        impl_->glyph_map[key] = info;
        
        metrics_.glyphs_cached++;
        metrics_.fill_percentage = float(metrics_.glyphs_cached * width * height) / 
                                  (metrics_.texture_width * metrics_.texture_height) * 100;
    }
    
    // Cleanup
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CFRelease((CFTypeRef)font);
}

bool GlyphAtlas::pack_glyph(const GlyphInfo& info, int& out_x, int& out_y) {
    int width = std::ceil(info.width) + metrics_.padding * 2;
    int height = std::ceil(info.height) + metrics_.padding * 2;
    
    PackNode* node = insert_rect(pack_root_.get(), width, height);
    if (node) {
        out_x = node->x + metrics_.padding;
        out_y = node->y + metrics_.padding;
        return true;
    }
    
    return false;
}

GlyphAtlas::PackNode* GlyphAtlas::insert_rect(PackNode* node, int width, int height) {
    if (node->used) {
        // Try inserting in children
        PackNode* result = nullptr;
        if (node->left) {
            result = insert_rect(node->left.get(), width, height);
        }
        if (!result && node->right) {
            result = insert_rect(node->right.get(), width, height);
        }
        return result;
    }
    
    // Check if rect fits
    if (width > node->width || height > node->height) {
        return nullptr;
    }
    
    // Perfect fit
    if (width == node->width && height == node->height) {
        node->used = true;
        return node;
    }
    
    // Split node
    node->used = true;
    node->left = std::make_unique<PackNode>();
    node->right = std::make_unique<PackNode>();
    
    // Decide split direction
    int dw = node->width - width;
    int dh = node->height - height;
    
    if (dw > dh) {
        // Vertical split
        node->left->x = node->x;
        node->left->y = node->y;
        node->left->width = width;
        node->left->height = node->height;
        
        node->right->x = node->x + width;
        node->right->y = node->y;
        node->right->width = dw;
        node->right->height = node->height;
    } else {
        // Horizontal split
        node->left->x = node->x;
        node->left->y = node->y;
        node->left->width = node->width;
        node->left->height = height;
        
        node->right->x = node->x;
        node->right->y = node->y + height;
        node->right->width = node->width;
        node->right->height = dh;
    }
    
    return insert_rect(node->left.get(), width, height);
}

void* GlyphAtlas::get_texture() const {
    return (__bridge void*)impl_->texture;
}

void GlyphAtlas::clear() {
    impl_->glyph_map.clear();
    impl_->current_x = 0;
    impl_->current_y = 0;
    impl_->row_height = 0;
    metrics_.glyphs_cached = 0;
    metrics_.fill_percentage = 0;
    
    // Reset packing tree
    pack_root_ = std::make_unique<PackNode>();
    pack_root_->x = 0;
    pack_root_->y = 0;
    pack_root_->width = metrics_.texture_width;
    pack_root_->height = metrics_.texture_height;
    
    // Clear texture
    if (impl_->texture_data.size() > 0) {
        std::fill(impl_->texture_data.begin(), impl_->texture_data.end(), 0);
        impl_->upload_texture_region(0, 0, metrics_.texture_width, metrics_.texture_height,
                                     impl_->texture_data.data());
    }
}

// SDFGenerator implementation
std::vector<float> SDFGenerator::generate_sdf(
    const uint8_t* bitmap,
    int width,
    int height,
    int spread
) {
    std::vector<float> output(width * height);
    
    #ifdef __AVX2__
    generate_sdf_simd(bitmap, width, height, spread, output.data());
    #else
    // Fallback scalar implementation
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float dist = distance_to_edge(bitmap, width, height, x, y, spread);
            bool inside = bitmap[y * width + x] > 128;
            output[y * width + x] = inside ? dist : -dist;
        }
    }
    
    // Normalize to [-1, 1]
    float max_dist = spread;
    for (auto& value : output) {
        value = std::max(-1.0f, std::min(1.0f, value / max_dist));
    }
    #endif
    
    return output;
}

void SDFGenerator::generate_sdf_simd(
    const uint8_t* bitmap,
    int width,
    int height,
    int spread,
    float* output
) {
    #ifdef __AVX2__
    const __m256 threshold = _mm256_set1_ps(128.0f);
    const __m256 spread_vec = _mm256_set1_ps(float(spread));
    const __m256 one = _mm256_set1_ps(1.0f);
    const __m256 neg_one = _mm256_set1_ps(-1.0f);
    
    for (int y = 0; y < height; ++y) {
        int x = 0;
        
        // Process 8 pixels at a time
        for (; x + 7 < width; x += 8) {
            // Load 8 pixels
            __m128i pixels_i = _mm_loadl_epi64((const __m128i*)(bitmap + y * width + x));
            __m256i pixels_256 = _mm256_cvtepu8_epi32(pixels_i);
            __m256 pixels = _mm256_cvtepi32_ps(pixels_256);
            
            // Check if inside or outside
            __m256 inside_mask = _mm256_cmp_ps(pixels, threshold, _CMP_GT_OS);
            
            // Calculate distances (simplified for demonstration)
            __m256 distances = _mm256_set1_ps(0.0f);
            
            // For each pixel, find minimum distance to edge
            for (int dy = -spread; dy <= spread; ++dy) {
                for (int dx = -spread; dx <= spread; ++dx) {
                    if (dx == 0 && dy == 0) continue;
                    
                    int ny = y + dy;
                    int nx_base = x + dx;
                    
                    if (ny >= 0 && ny < height) {
                        __m256 dx_vec = _mm256_set1_ps(float(dx));
                        __m256 dy_vec = _mm256_set1_ps(float(dy));
                        
                        // Calculate squared distance
                        __m256 dist_sq = _mm256_add_ps(
                            _mm256_mul_ps(dx_vec, dx_vec),
                            _mm256_mul_ps(dy_vec, dy_vec)
                        );
                        
                        __m256 dist = _mm256_sqrt_ps(dist_sq);
                        
                        // Update minimum distance
                        distances = _mm256_min_ps(distances, dist);
                    }
                }
            }
            
            // Apply sign based on inside/outside
            __m256 signed_dist = _mm256_blendv_ps(
                _mm256_sub_ps(_mm256_setzero_ps(), distances),
                distances,
                inside_mask
            );
            
            // Normalize to [-1, 1]
            __m256 normalized = _mm256_div_ps(signed_dist, spread_vec);
            normalized = _mm256_max_ps(neg_one, _mm256_min_ps(one, normalized));
            
            // Store result
            _mm256_storeu_ps(output + y * width + x, normalized);
        }
        
        // Handle remaining pixels
        for (; x < width; ++x) {
            float dist = distance_to_edge(bitmap, width, height, x, y, spread);
            bool inside = bitmap[y * width + x] > 128;
            output[y * width + x] = inside ? dist : -dist;
            output[y * width + x] /= spread;
            output[y * width + x] = std::max(-1.0f, std::min(1.0f, output[y * width + x]));
        }
    }
    #else
    // Fallback to scalar version
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float dist = distance_to_edge(bitmap, width, height, x, y, spread);
            bool inside = bitmap[y * width + x] > 128;
            output[y * width + x] = (inside ? dist : -dist) / spread;
            output[y * width + x] = std::max(-1.0f, std::min(1.0f, output[y * width + x]));
        }
    }
    #endif
}

float SDFGenerator::distance_to_edge(
    const uint8_t* bitmap,
    int width,
    int height,
    int x,
    int y,
    int max_dist
) {
    bool inside = bitmap[y * width + x] > 128;
    float min_dist = max_dist;
    
    for (int dy = -max_dist; dy <= max_dist; ++dy) {
        for (int dx = -max_dist; dx <= max_dist; ++dx) {
            int nx = x + dx;
            int ny = y + dy;
            
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                bool neighbor_inside = bitmap[ny * width + nx] > 128;
                
                if (neighbor_inside != inside) {
                    float dist = std::sqrt(dx * dx + dy * dy);
                    min_dist = std::min(min_dist, dist);
                }
            }
        }
    }
    
    return min_dist;
}

} // namespace mdviewer