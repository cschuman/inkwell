#include "rendering/render_engine.h"
#include "rendering/text_layout.h"
#include "rendering/glyph_atlas.h"
#include <chrono>
#include <algorithm>

#ifdef __OBJC__
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#endif

namespace mdviewer {

class RenderEngine::Impl {
public:
    id<MTLDevice> device = nil;
    id<MTLCommandQueue> command_queue = nil;
    id<MTLRenderPipelineState> text_pipeline = nil;
    id<MTLRenderPipelineState> focus_pipeline = nil;
    id<MTLRenderPipelineState> selection_pipeline = nil;
    id<MTLRenderPipelineState> diff_pipeline = nil;
    
    id<MTLBuffer> vertex_buffers[kBufferCount];
    id<MTLBuffer> uniform_buffers[kBufferCount];
    id<MTLTexture> glyph_texture = nil;
    
    CAMetalLayer* metal_layer = nil;
    
    struct FrameData {
        std::chrono::steady_clock::time_point start_time;
        size_t draw_calls = 0;
        size_t vertices = 0;
    } frame_data;
    
    float fps_accumulator = 0.0f;
    int fps_frame_count = 0;
    std::chrono::steady_clock::time_point fps_last_update;
    
    bool initialize_pipelines();
    void create_buffers();
};

RenderEngine::RenderEngine() : impl_(std::make_unique<Impl>()) {
    glyph_atlas_ = std::make_unique<GlyphAtlas>();
    text_layout_ = std::make_unique<TextLayout>();
}

RenderEngine::~RenderEngine() = default;

bool RenderEngine::initialize(void* metal_device, void* metal_layer) {
    impl_->device = (__bridge id<MTLDevice>)metal_device;
    impl_->metal_layer = (__bridge CAMetalLayer*)metal_layer;
    
    if (!impl_->device) {
        return false;
    }
    
    impl_->command_queue = [impl_->device newCommandQueue];
    if (!impl_->command_queue) {
        return false;
    }
    
    // Initialize rendering pipelines
    if (!impl_->initialize_pipelines()) {
        return false;
    }
    
    // Create buffers
    impl_->create_buffers();
    
    // Initialize glyph atlas
    glyph_atlas_->initialize(impl_->device);
    
    impl_->fps_last_update = std::chrono::steady_clock::now();
    
    return true;
}

bool RenderEngine::Impl::initialize_pipelines() {
    NSError* error = nil;
    
    // Load shaders
    NSString* shader_path = [[NSBundle mainBundle] pathForResource:@"shaders" 
                                                           ofType:@"metallib"];
    id<MTLLibrary> library = [device newLibraryWithFile:shader_path error:&error];
    
    if (!library) {
        // Try to load default library if custom shaders not found
        library = [device newDefaultLibrary];
    }
    
    if (!library) {
        return false;
    }
    
    // Text rendering pipeline
    {
        MTLRenderPipelineDescriptor* descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        descriptor.vertexFunction = [library newFunctionWithName:@"text_vertex"];
        descriptor.fragmentFunction = [library newFunctionWithName:@"text_fragment"];
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        descriptor.colorAttachments[0].blendingEnabled = YES;
        descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        
        text_pipeline = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
        if (!text_pipeline) {
            return false;
        }
    }
    
    // Focus mode overlay pipeline
    {
        MTLRenderPipelineDescriptor* descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        descriptor.vertexFunction = [library newFunctionWithName:@"focus_overlay_vertex"];
        descriptor.fragmentFunction = [library newFunctionWithName:@"focus_overlay_fragment"];
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        descriptor.colorAttachments[0].blendingEnabled = YES;
        descriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        descriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        
        focus_pipeline = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
        if (!focus_pipeline) {
            return false;
        }
    }
    
    // Selection pipeline
    {
        MTLRenderPipelineDescriptor* descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        descriptor.vertexFunction = [library newFunctionWithName:@"selection_vertex"];
        descriptor.fragmentFunction = [library newFunctionWithName:@"selection_fragment"];
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        descriptor.colorAttachments[0].blendingEnabled = YES;
        
        selection_pipeline = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
        if (!selection_pipeline) {
            return false;
        }
    }
    
    // Diff highlight pipeline
    {
        MTLRenderPipelineDescriptor* descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        descriptor.vertexFunction = [library newFunctionWithName:@"diff_highlight_vertex"];
        descriptor.fragmentFunction = [library newFunctionWithName:@"diff_highlight_fragment"];
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        descriptor.colorAttachments[0].blendingEnabled = YES;
        
        diff_pipeline = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
        if (!diff_pipeline) {
            return false;
        }
    }
    
    return true;
}

void RenderEngine::Impl::create_buffers() {
    // Create vertex buffers for triple buffering
    for (size_t i = 0; i < kBufferCount; ++i) {
        vertex_buffers[i] = [device newBufferWithLength:1024 * 1024 * 4  // 4MB per buffer
                                                options:MTLResourceCPUCacheModeWriteCombined];
        
        uniform_buffers[i] = [device newBufferWithLength:sizeof(float) * 64
                                                 options:MTLResourceCPUCacheModeWriteCombined];
    }
}

void RenderEngine::set_virtual_dom(VirtualDOM* dom) {
    virtual_dom_ = dom;
}

void RenderEngine::render(ScrollPosition scroll) {
    if (!virtual_dom_ || !impl_->metal_layer) return;
    
    auto frame_start = std::chrono::steady_clock::now();
    impl_->frame_data.draw_calls = 0;
    impl_->frame_data.vertices = 0;
    
    @autoreleasepool {
        id<CAMetalDrawable> drawable = [impl_->metal_layer nextDrawable];
        if (!drawable) return;
        
        id<MTLCommandBuffer> command_buffer = [impl_->command_queue commandBuffer];
        
        MTLRenderPassDescriptor* render_pass = [[MTLRenderPassDescriptor alloc] init];
        render_pass.colorAttachments[0].texture = drawable.texture;
        render_pass.colorAttachments[0].loadAction = MTLLoadActionClear;
        render_pass.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
        render_pass.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        id<MTLRenderCommandEncoder> encoder = [command_buffer renderCommandEncoderWithDescriptor:render_pass];
        
        // Setup uniforms
        struct Uniforms {
            float projection_matrix[16];
            float viewport_size[2];
            float scroll_y;
            float time;
            float focus_y;
            float focus_height;
            int focus_mode;
            int typewriter_mode;
        } uniforms;
        
        // Setup orthographic projection
        float width = viewport_.width;
        float height = viewport_.height;
        uniforms.projection_matrix[0] = 2.0f / width;
        uniforms.projection_matrix[5] = -2.0f / height;
        uniforms.projection_matrix[10] = -1.0f;
        uniforms.projection_matrix[12] = -1.0f;
        uniforms.projection_matrix[13] = 1.0f;
        uniforms.projection_matrix[15] = 1.0f;
        
        uniforms.viewport_size[0] = width;
        uniforms.viewport_size[1] = height;
        uniforms.scroll_y = scroll.y;
        
        auto now = std::chrono::steady_clock::now();
        uniforms.time = std::chrono::duration<float>(now.time_since_epoch()).count();
        
        uniforms.focus_y = focus_y_;
        uniforms.focus_height = 100.0f;
        uniforms.focus_mode = focus_mode_ ? 1 : 0;
        uniforms.typewriter_mode = typewriter_mode_ ? 1 : 0;
        
        memcpy([impl_->uniform_buffers[current_buffer_] contents], &uniforms, sizeof(uniforms));
        
        // Render visible nodes
        render_visible_range(scroll);
        
        // Render focus overlay if enabled
        if (focus_mode_) {
            [encoder setRenderPipelineState:impl_->focus_pipeline];
            [encoder setVertexBuffer:impl_->vertex_buffers[current_buffer_] offset:0 atIndex:0];
            [encoder setVertexBuffer:impl_->uniform_buffers[current_buffer_] offset:0 atIndex:1];
            // Draw focus overlay quad
            impl_->frame_data.draw_calls++;
        }
        
        [encoder endEncoding];
        [command_buffer presentDrawable:drawable];
        [command_buffer commit];
        
        // Update buffer index
        current_buffer_ = (current_buffer_ + 1) % kBufferCount;
    }
    
    // Update stats
    auto frame_end = std::chrono::steady_clock::now();
    auto frame_duration = std::chrono::duration_cast<std::chrono::microseconds>(frame_end - frame_start);
    stats_.frame_time_ms = frame_duration.count() / 1000.0f;
    stats_.draw_calls = impl_->frame_data.draw_calls;
    stats_.vertices_rendered = impl_->frame_data.vertices;
    
    // Update FPS
    impl_->fps_frame_count++;
    auto fps_duration = std::chrono::duration_cast<std::chrono::milliseconds>(frame_end - impl_->fps_last_update);
    if (fps_duration.count() >= 1000) {
        stats_.fps = impl_->fps_frame_count * 1000.0f / fps_duration.count();
        impl_->fps_frame_count = 0;
        impl_->fps_last_update = frame_end;
    }
}

void RenderEngine::render_visible_range(ScrollPosition pos) {
    if (!virtual_dom_) return;
    
    // Update viewport in virtual DOM
    virtual_dom_->set_viewport(pos.y, viewport_.height);
    
    // Get visible nodes
    auto visible_nodes = virtual_dom_->get_visible_nodes();
    
    // Render each visible node
    for (const auto* node : visible_nodes) {
        // Text layout and rendering would happen here
        // This would use the text_layout_ object to position glyphs
        // and the glyph_atlas_ to get texture coordinates
        impl_->frame_data.draw_calls++;
        impl_->frame_data.vertices += 6; // Assuming quad per glyph
    }
}

void RenderEngine::resize(float width, float height) {
    viewport_.width = width;
    viewport_.height = height;
    
    if (virtual_dom_) {
        virtual_dom_->set_viewport(0, height);
    }
}

void RenderEngine::set_focus_mode(bool enabled, float focus_y) {
    focus_mode_ = enabled;
    focus_y_ = focus_y;
}

void RenderEngine::set_typewriter_mode(bool enabled) {
    typewriter_mode_ = enabled;
}

void RenderEngine::update_focus_effect(float y) {
    if (typewriter_mode_) {
        // Center the current line
        focus_y_ = viewport_.height / 2.0f + y;
    } else {
        focus_y_ = y;
    }
}

void RenderEngine::set_theme(const Theme& theme) {
    // Apply theme settings
    // This would update colors, fonts, etc.
}

} // namespace mdviewer