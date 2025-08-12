#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Vertex {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float4 color [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
    float focusAlpha;
};

struct Uniforms {
    float4x4 projectionMatrix;
    float2 viewportSize;
    float scrollY;
    float time;
    float focusY;
    float focusHeight;
    bool focusMode;
    bool typewriterMode;
};

vertex VertexOut text_vertex(
    Vertex in [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]],
    uint vid [[vertex_id]]
) {
    VertexOut out;
    
    float4 worldPos = float4(in.position, 0.0, 1.0);
    worldPos.y -= uniforms.scrollY;
    
    out.position = uniforms.projectionMatrix * worldPos;
    out.texCoord = in.texCoord;
    out.color = in.color;
    
    // Calculate focus mode alpha
    if (uniforms.focusMode) {
        float distance = abs(worldPos.y - uniforms.focusY);
        float fadeDistance = uniforms.focusHeight * 0.5;
        out.focusAlpha = 1.0 - smoothstep(0.0, fadeDistance, distance);
        
        // Typewriter mode keeps current line fully visible
        if (uniforms.typewriterMode && distance < 20.0) {
            out.focusAlpha = 1.0;
        }
    } else {
        out.focusAlpha = 1.0;
    }
    
    return out;
}

fragment float4 text_fragment(
    VertexOut in [[stage_in]],
    texture2d<float> glyphAtlas [[texture(0)]],
    sampler glyphSampler [[sampler(0)]]
) {
    // Sample SDF glyph texture
    float sdfValue = glyphAtlas.sample(glyphSampler, in.texCoord).r;
    
    // Compute anti-aliased edge
    float width = fwidth(sdfValue);
    float alpha = smoothstep(0.5 - width, 0.5 + width, sdfValue);
    
    // Apply focus mode dimming
    alpha *= in.focusAlpha;
    
    return float4(in.color.rgb, in.color.a * alpha);
}

// Compute shader for parallel text layout
kernel void compute_text_layout(
    device float2* positions [[buffer(0)]],
    device const uint* glyphIndices [[buffer(1)]],
    device const float* glyphWidths [[buffer(2)]],
    constant float& lineHeight [[buffer(3)]],
    constant float& maxWidth [[buffer(4)]],
    uint gid [[thread_position_in_grid]]
) {
    float x = 0.0;
    float y = float(gid / 1024) * lineHeight; // Approximate line calculation
    
    uint glyphIndex = glyphIndices[gid];
    float width = glyphWidths[glyphIndex];
    
    // Simple word wrapping
    if (x + width > maxWidth) {
        x = 0.0;
        y += lineHeight;
    }
    
    positions[gid] = float2(x, y);
}

// Shader for rendering focus mode overlay
struct FocusVertex {
    float2 position [[attribute(0)]];
};

struct FocusVertexOut {
    float4 position [[position]];
    float alpha;
};

vertex FocusVertexOut focus_overlay_vertex(
    FocusVertex in [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    FocusVertexOut out;
    out.position = uniforms.projectionMatrix * float4(in.position, 0.0, 1.0);
    
    // Calculate gradient for smooth focus transition
    float y = in.position.y - uniforms.scrollY;
    float distance = abs(y - uniforms.focusY);
    float fadeDistance = uniforms.focusHeight;
    out.alpha = smoothstep(fadeDistance, 0.0, distance) * 0.5;
    
    return out;
}

fragment float4 focus_overlay_fragment(FocusVertexOut in [[stage_in]]) {
    return float4(0.0, 0.0, 0.0, in.alpha);
}

// Shader for rendering selection highlights
struct SelectionVertex {
    float2 position [[attribute(0)]];
};

vertex float4 selection_vertex(
    SelectionVertex in [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float4 worldPos = float4(in.position, 0.0, 1.0);
    worldPos.y -= uniforms.scrollY;
    return uniforms.projectionMatrix * worldPos;
}

fragment float4 selection_fragment() {
    return float4(0.2, 0.5, 1.0, 0.3); // Light blue selection color
}

// Shader for diff highlighting with animation
struct DiffVertex {
    float2 position [[attribute(0)]];
    float animationTime [[attribute(1)]];
};

struct DiffVertexOut {
    float4 position [[position]];
    float alpha;
    float3 color;
};

vertex DiffVertexOut diff_highlight_vertex(
    DiffVertex in [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    DiffVertexOut out;
    
    float4 worldPos = float4(in.position, 0.0, 1.0);
    worldPos.y -= uniforms.scrollY;
    out.position = uniforms.projectionMatrix * worldPos;
    
    // Animated fade out
    float elapsed = uniforms.time - in.animationTime;
    out.alpha = max(0.0, 1.0 - elapsed / 0.5); // 500ms fade
    
    // Green for additions, red for deletions
    out.color = float3(0.2, 0.8, 0.2); // Default to green
    
    return out;
}

fragment float4 diff_highlight_fragment(DiffVertexOut in [[stage_in]]) {
    return float4(in.color, in.alpha * 0.3);
}