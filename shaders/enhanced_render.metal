#include <metal_stdlib>
#include <simd/simd.h>

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
    float2 screenPos;
};

struct Uniforms {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    float time;
    float2 resolution;
    float scrollOffset;
    float4 focusRect;  // x, y, width, height
    float focusIntensity;
    float blurRadius;
    float4 themeColor;
};

// Vertex shaders
vertex VertexOut enhanced_vertex(VertexIn in [[stage_in]],
                                constant Uniforms& uniforms [[buffer(0)]]) {
    VertexOut out;
    float4 worldPos = float4(in.position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPos;
    out.texCoord = in.texCoord;
    out.color = in.color;
    out.screenPos = in.position;
    return out;
}

// Gaussian blur helper
float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (sigma * sqrt(2.0 * M_PI_F));
}

// Fragment shaders

// Glass morphism effect
fragment float4 glass_fragment(VertexOut in [[stage_in]],
                              texture2d<float> backgroundTexture [[texture(0)]],
                              texture2d<float> noiseTexture [[texture(1)]],
                              sampler textureSampler [[sampler(0)]],
                              constant Uniforms& uniforms [[buffer(0)]]) {
    // Sample background with blur
    float4 color = float4(0.0);
    float blurSize = uniforms.blurRadius;
    float2 texelSize = 1.0 / uniforms.resolution;
    
    // 9-tap Gaussian blur
    float weights[9] = {
        0.0162, 0.0540, 0.1216, 0.1944, 0.2270,
        0.1944, 0.1216, 0.0540, 0.0162
    };
    
    for (int i = -4; i <= 4; i++) {
        float2 offset = float2(i, 0) * texelSize * blurSize;
        color += backgroundTexture.sample(textureSampler, in.texCoord + offset) * weights[i + 4];
    }
    
    // Add frosted glass effect
    float2 noiseCoord = in.texCoord * 10.0;
    float noise = noiseTexture.sample(textureSampler, noiseCoord).r;
    color.rgb += noise * 0.02;
    
    // Apply glass tint
    color.rgb = mix(color.rgb, uniforms.themeColor.rgb, 0.05);
    color.a = 0.95;
    
    return color;
}

// Gradient with animated shimmer
fragment float4 gradient_shimmer_fragment(VertexOut in [[stage_in]],
                                         constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    
    // Base gradient
    float3 color1 = float3(0.0, 0.48, 1.0);  // Blue
    float3 color2 = float3(0.35, 0.35, 0.84);  // Purple
    float3 gradient = mix(color1, color2, uv.x + uv.y * 0.5);
    
    // Animated shimmer
    float shimmer = sin(uv.x * 10.0 - uniforms.time * 2.0) * 0.5 + 0.5;
    shimmer *= sin(uv.y * 8.0 + uniforms.time * 1.5) * 0.5 + 0.5;
    shimmer = pow(shimmer, 3.0) * 0.1;
    
    gradient += shimmer;
    
    return float4(gradient, in.color.a);
}

// Neumorphism shadow effect
fragment float4 neumorphism_fragment(VertexOut in [[stage_in]],
                                    constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // Soft inner shadow
    float innerShadow = 1.0 - smoothstep(0.3, 0.5, dist);
    innerShadow *= 0.1;
    
    // Highlight on opposite corner
    float2 lightPos = float2(0.2, 0.2);
    float highlight = 1.0 - distance(uv, lightPos);
    highlight = pow(highlight, 3.0) * 0.2;
    
    float3 baseColor = uniforms.themeColor.rgb;
    float3 finalColor = baseColor * (1.0 - innerShadow) + highlight;
    
    return float4(finalColor, in.color.a);
}

// Focus mode with animated breathing effect
fragment float4 focus_mode_fragment(VertexOut in [[stage_in]],
                                   texture2d<float> contentTexture [[texture(0)]],
                                   sampler textureSampler [[sampler(0)]],
                                   constant Uniforms& uniforms [[buffer(0)]]) {
    float4 color = contentTexture.sample(textureSampler, in.texCoord);
    
    // Calculate distance from focus area
    float2 focusCenter = uniforms.focusRect.xy + uniforms.focusRect.zw * 0.5;
    float2 pos = in.screenPos;
    
    float distToFocus = distance(pos, focusCenter);
    float focusRadius = length(uniforms.focusRect.zw) * 0.5;
    
    // Breathing animation
    float breathing = sin(uniforms.time * 2.0) * 0.1 + 1.0;
    focusRadius *= breathing;
    
    // Smooth falloff
    float dimming = smoothstep(focusRadius * 0.8, focusRadius * 1.5, distToFocus);
    dimming *= uniforms.focusIntensity;
    
    // Apply dimming
    color.rgb *= (1.0 - dimming * 0.5);
    
    // Add subtle vignette
    float vignette = 1.0 - dimming * 0.3;
    color.rgb *= vignette;
    
    return color;
}

// Smooth selection highlighting with glow
fragment float4 selection_glow_fragment(VertexOut in [[stage_in]],
                                       constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    
    // Animated glow pulse
    float pulse = sin(uniforms.time * 3.0) * 0.3 + 0.7;
    
    // Distance field for rounded rectangle
    float2 size = float2(1.0, 0.1);  // Selection size
    float2 d = abs(uv - 0.5) - size * 0.5;
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    
    // Soft glow
    float glow = 1.0 - smoothstep(0.0, 0.02, dist);
    glow *= pulse;
    
    float4 glowColor = uniforms.themeColor;
    glowColor.a *= glow * 0.3;
    
    return glowColor;
}

// Animated code block background
fragment float4 code_block_fragment(VertexOut in [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    
    // Subtle animated gradient
    float gradient = uv.x + sin(uniforms.time * 0.5 + uv.y * 3.0) * 0.02;
    
    // Grid pattern
    float grid = step(0.98, fract(uv.x * 50.0)) + step(0.98, fract(uv.y * 30.0));
    grid *= 0.02;
    
    float3 baseColor = uniforms.themeColor.rgb * 0.95;
    float3 color = baseColor + gradient * 0.02 + grid;
    
    return float4(color, 0.98);
}

// Smooth scrollbar with hover effect
fragment float4 scrollbar_fragment(VertexOut in [[stage_in]],
                                  constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    
    // Rounded rectangle distance field
    float2 size = float2(0.8, 1.0);
    float2 d = abs(uv - 0.5) - size * 0.5;
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    
    // Smooth edge
    float alpha = 1.0 - smoothstep(0.0, 0.02, dist);
    
    // Hover effect (controlled by focusIntensity)
    float hover = uniforms.focusIntensity;
    float3 color = mix(uniforms.themeColor.rgb * 0.3, 
                       uniforms.themeColor.rgb * 0.6, 
                       hover);
    
    return float4(color, alpha * (0.3 + hover * 0.4));
}

// Typewriter mode with cursor
fragment float4 typewriter_fragment(VertexOut in [[stage_in]],
                                   texture2d<float> contentTexture [[texture(0)]],
                                   sampler textureSampler [[sampler(0)]],
                                   constant Uniforms& uniforms [[buffer(0)]]) {
    float4 color = contentTexture.sample(textureSampler, in.texCoord);
    
    // Current line highlight
    float lineY = uniforms.focusRect.y;
    float lineHeight = uniforms.focusRect.w;
    
    float distToLine = abs(in.screenPos.y - lineY);
    float highlight = 1.0 - smoothstep(0.0, lineHeight, distToLine);
    
    // Add subtle highlight
    color.rgb += highlight * 0.05;
    
    // Blinking cursor
    float cursorX = uniforms.focusRect.x;
    float cursorBlink = step(0.5, fract(uniforms.time * 1.5));
    
    if (abs(in.screenPos.x - cursorX) < 1.0 && distToLine < lineHeight * 0.5) {
        color.rgb = mix(color.rgb, uniforms.themeColor.rgb, cursorBlink);
    }
    
    return color;
}

// Smooth diff highlighting
fragment float4 enhanced_diff_highlight_fragment(VertexOut in [[stage_in]],
                                       constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    
    // Animated stripe pattern for additions/deletions
    float stripe = step(0.5, fract((uv.x + uv.y) * 20.0 + uniforms.time * 0.5));
    stripe *= 0.03;
    
    // Determine if addition or deletion based on color
    bool isAddition = uniforms.themeColor.g > uniforms.themeColor.r;
    
    float3 color;
    if (isAddition) {
        color = float3(0.2, 0.8, 0.3) + stripe;  // Green for additions
    } else {
        color = float3(0.8, 0.2, 0.2) + stripe;  // Red for deletions
    }
    
    return float4(color, 0.2);
}

// Particle system for visual effects
struct Particle {
    float2 position;
    float2 velocity;
    float life;
    float size;
};

fragment float4 particle_fragment(VertexOut in [[stage_in]],
                                 constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float2 center = float2(0.5, 0.5);
    
    // Distance from center for circular particle
    float dist = distance(uv, center);
    float alpha = 1.0 - smoothstep(0.0, 0.5, dist);
    
    // Fade based on life
    alpha *= in.color.a;
    
    // Glow effect
    float glow = exp(-dist * 5.0) * 0.5;
    
    float3 color = uniforms.themeColor.rgb + glow;
    
    return float4(color, alpha);
}

// Loading spinner animation
fragment float4 spinner_fragment(VertexOut in [[stage_in]],
                               constant Uniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord - 0.5;
    float angle = atan2(uv.y, uv.x);
    float radius = length(uv);
    
    // Rotating gradient
    float rotation = uniforms.time * 2.0;
    float gradient = fract((angle + rotation) / (2.0 * M_PI_F));
    
    // Ring shape
    float ring = smoothstep(0.3, 0.35, radius) * (1.0 - smoothstep(0.45, 0.5, radius));
    
    // Fade in/out at edges
    gradient *= smoothstep(0.0, 0.2, gradient) * (1.0 - smoothstep(0.8, 1.0, gradient));
    
    float3 color = mix(uniforms.themeColor.rgb, 
                       uniforms.themeColor.rgb * 1.5, 
                       gradient);
    
    return float4(color, ring * gradient);
}