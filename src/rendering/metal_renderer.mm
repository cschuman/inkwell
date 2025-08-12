#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#include <vector>
#include <string>

namespace mdviewer {
namespace rendering {

struct Vertex {
    simd_float2 position;
    simd_float2 texCoord;
    simd_float4 color;
};

struct Uniforms {
    simd_float4x4 projectionMatrix;
    simd_float4x4 viewMatrix;
    simd_float2 screenSize;
    float time;
    float _padding;
};

class MetalRenderer {
private:
    id<MTLDevice> device_;
    id<MTLCommandQueue> commandQueue_;
    id<MTLRenderPipelineState> pipelineState_;
    id<MTLBuffer> vertexBuffer_;
    id<MTLBuffer> uniformBuffer_;
    
    std::vector<Vertex> vertices_;
    Uniforms uniforms_;
    
public:
    MetalRenderer() {
        device_ = MTLCreateSystemDefaultDevice();
        if (!device_) {
            // Handle error - no Metal support
            return;
        }
        
        commandQueue_ = [device_ newCommandQueue];
        setupRenderPipeline();
        setupBuffers();
    }
    
    ~MetalRenderer() {
        // ARC will handle cleanup
    }
    
    bool initialize() {
        return device_ != nil && commandQueue_ != nil && pipelineState_ != nil;
    }
    
    void setupRenderPipeline() {
        NSError* error = nil;
        
        // Simple shader source - in production, would load from .metal files
        NSString* shaderSource = @R"(
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float4 color [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

struct Uniforms {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    float2 screenSize;
    float time;
    float _padding;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                           constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    float4 pos = float4(in.position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * pos;
    out.texCoord = in.texCoord;
    out.color = in.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
        )";
        
        id<MTLLibrary> library = [device_ newLibraryWithSource:shaderSource
                                                       options:nil
                                                         error:&error];
        if (!library) {
            NSLog(@"Failed to create Metal library: %@", error.localizedDescription);
            return;
        }
        
        id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
        
        MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDescriptor.vertexFunction = vertexFunction;
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        // Setup vertex descriptor
        MTLVertexDescriptor* vertexDescriptor = [[MTLVertexDescriptor alloc] init];
        
        // Position
        vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        
        // Texture coordinates
        vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[1].offset = sizeof(simd_float2);
        vertexDescriptor.attributes[1].bufferIndex = 0;
        
        // Color
        vertexDescriptor.attributes[2].format = MTLVertexFormatFloat4;
        vertexDescriptor.attributes[2].offset = sizeof(simd_float2) + sizeof(simd_float2);
        vertexDescriptor.attributes[2].bufferIndex = 0;
        
        vertexDescriptor.layouts[0].stride = sizeof(Vertex);
        pipelineDescriptor.vertexDescriptor = vertexDescriptor;
        
        pipelineState_ = [device_ newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                error:&error];
        if (!pipelineState_) {
            NSLog(@"Failed to create render pipeline state: %@", error.localizedDescription);
        }
    }
    
    void setupBuffers() {
        // Create initial vertex buffer
        vertexBuffer_ = [device_ newBufferWithLength:sizeof(Vertex) * 1024
                                             options:MTLResourceStorageModeShared];
        
        // Create uniform buffer
        uniformBuffer_ = [device_ newBufferWithLength:sizeof(Uniforms)
                                              options:MTLResourceStorageModeShared];
    }
    
    void updateUniforms(float width, float height) {
        // Create orthographic projection matrix
        float left = 0.0f;
        float right = width;
        float bottom = height;
        float top = 0.0f;
        float nearZ = -1.0f;
        float farZ = 1.0f;
        
        simd_float4x4 projection = {
            .columns[0] = { 2.0f / (right - left), 0, 0, 0 },
            .columns[1] = { 0, 2.0f / (top - bottom), 0, 0 },
            .columns[2] = { 0, 0, 1.0f / (farZ - nearZ), 0 },
            .columns[3] = { -(right + left) / (right - left),
                           -(top + bottom) / (top - bottom),
                           -nearZ / (farZ - nearZ), 1 }
        };
        
        uniforms_.projectionMatrix = projection;
        uniforms_.viewMatrix = matrix_identity_float4x4;
        uniforms_.screenSize = simd_make_float2(width, height);
        uniforms_.time = 0.0f; // TODO: Update with actual time
        
        memcpy([uniformBuffer_ contents], &uniforms_, sizeof(Uniforms));
    }
    
    void addQuad(float x, float y, float width, float height, 
                 simd_float4 color = {1, 1, 1, 1}) {
        Vertex quad[6] = {
            // First triangle
            {{x, y}, {0, 0}, color},
            {{x + width, y}, {1, 0}, color},
            {{x, y + height}, {0, 1}, color},
            
            // Second triangle
            {{x + width, y}, {1, 0}, color},
            {{x + width, y + height}, {1, 1}, color},
            {{x, y + height}, {0, 1}, color}
        };
        
        for (int i = 0; i < 6; i++) {
            vertices_.push_back(quad[i]);
        }
    }
    
    void clearVertices() {
        vertices_.clear();
    }
    
    void render(id<MTLRenderCommandEncoder> renderEncoder, float width, float height) {
        if (!pipelineState_ || vertices_.empty()) {
            return;
        }
        
        updateUniforms(width, height);
        
        // Update vertex buffer
        size_t vertexDataSize = vertices_.size() * sizeof(Vertex);
        if (vertexDataSize > [vertexBuffer_ length]) {
            // Recreate buffer if needed
            vertexBuffer_ = [device_ newBufferWithLength:vertexDataSize
                                                 options:MTLResourceStorageModeShared];
        }
        
        memcpy([vertexBuffer_ contents], vertices_.data(), vertexDataSize);
        
        [renderEncoder setRenderPipelineState:pipelineState_];
        [renderEncoder setVertexBuffer:vertexBuffer_ offset:0 atIndex:0];
        [renderEncoder setVertexBuffer:uniformBuffer_ offset:0 atIndex:1];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:vertices_.size()];
    }
    
    // Convenience methods for common shapes
    void renderText(const std::string& text, float x, float y, 
                   simd_float4 color = {0, 0, 0, 1}) {
        // TODO: Implement text rendering using glyph atlas
        // For now, just draw a placeholder rectangle
        addQuad(x, y, text.length() * 12, 16, color);
    }
    
    void renderRectangle(float x, float y, float width, float height,
                        simd_float4 color = {0.5, 0.5, 0.5, 1}) {
        addQuad(x, y, width, height, color);
    }
    
    void renderLine(float x1, float y1, float x2, float y2,
                   float thickness = 1.0f, simd_float4 color = {0, 0, 0, 1}) {
        // Simple line rendering as a thin rectangle
        float dx = x2 - x1;
        float dy = y2 - y1;
        float length = sqrt(dx * dx + dy * dy);
        
        if (length > 0) {
            float angle = atan2(dy, dx);
            
            // For simplicity, just draw a horizontal rectangle
            // In a complete implementation, would rotate properly
            addQuad(x1, y1 - thickness/2, length, thickness, color);
        }
    }
};

} // namespace rendering
} // namespace mdviewer

// C interface for use from other languages
extern "C" {
    using namespace mdviewer::rendering;
    
    MetalRenderer* metal_renderer_create() {
        return new MetalRenderer();
    }
    
    void metal_renderer_destroy(MetalRenderer* renderer) {
        delete renderer;
    }
    
    bool metal_renderer_initialize(MetalRenderer* renderer) {
        return renderer->initialize();
    }
    
    void metal_renderer_clear_vertices(MetalRenderer* renderer) {
        renderer->clearVertices();
    }
    
    void metal_renderer_add_quad(MetalRenderer* renderer,
                                 float x, float y, float width, float height,
                                 float r, float g, float b, float a) {
        renderer->addQuad(x, y, width, height, {r, g, b, a});
    }
    
    void metal_renderer_render_text(MetalRenderer* renderer,
                                   const char* text, float x, float y,
                                   float r, float g, float b, float a) {
        renderer->renderText(std::string(text), x, y, {r, g, b, a});
    }
    
    void metal_renderer_render_rectangle(MetalRenderer* renderer,
                                        float x, float y, float width, float height,
                                        float r, float g, float b, float a) {
        renderer->renderRectangle(x, y, width, height, {r, g, b, a});
    }
}