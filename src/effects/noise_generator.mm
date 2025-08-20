#import "../../include/effects/noise_generator.h"
#import <vector>

// Permutation table for noise functions
static const int permutation[256] = {
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
    190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,
    20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,
    230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,
    169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,
    147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,
    2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,
    112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,
    107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,
    114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
};

@implementation NoiseGenerator

// Fade function for smooth interpolation
+ (float)fade:(float)t {
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
}

// Linear interpolation
+ (float)lerp:(float)a b:(float)b t:(float)t {
    return a + t * (b - a);
}

// Gradient calculation for Perlin noise
+ (float)grad1D:(int)hash x:(float)x {
    int h = hash & 15;
    float grad = 1.0f + (h & 7);  // Gradient value 1-8
    if (h & 8) grad = -grad;      // Randomly invert half
    return grad * x;
}

+ (float)grad2D:(int)hash x:(float)x y:(float)y {
    int h = hash & 7;
    float u = h < 4 ? x : y;
    float v = h < 4 ? y : x;
    return ((h & 1) ? -u : u) + ((h & 2) ? -v : v);
}

+ (float)grad3D:(int)hash x:(float)x y:(float)y z:(float)z {
    int h = hash & 15;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : h == 12 || h == 14 ? x : z;
    return ((h & 1) ? -u : u) + ((h & 2) ? -v : v);
}

#pragma mark - Perlin Noise

+ (float)perlinNoise1D:(float)x {
    int xi = (int)floorf(x) & 255;
    float xf = x - floorf(x);
    float u = [self fade:xf];
    
    int a = permutation[xi];
    int b = permutation[(xi + 1) & 255];
    
    float gradA = [self grad1D:a x:xf];
    float gradB = [self grad1D:b x:xf - 1.0f];
    
    return [self lerp:gradA b:gradB t:u];
}

+ (float)perlinNoise2D:(simd_float2)point {
    int xi = (int)floorf(point.x) & 255;
    int yi = (int)floorf(point.y) & 255;
    
    float xf = point.x - floorf(point.x);
    float yf = point.y - floorf(point.y);
    
    float u = [self fade:xf];
    float v = [self fade:yf];
    
    int aa = permutation[permutation[xi] + yi];
    int ab = permutation[permutation[xi] + ((yi + 1) & 255)];
    int ba = permutation[permutation[(xi + 1) & 255] + yi];
    int bb = permutation[permutation[(xi + 1) & 255] + ((yi + 1) & 255)];
    
    float x1 = [self lerp:[self grad2D:aa x:xf y:yf]
                        b:[self grad2D:ba x:xf - 1.0f y:yf]
                        t:u];
    float x2 = [self lerp:[self grad2D:ab x:xf y:yf - 1.0f]
                        b:[self grad2D:bb x:xf - 1.0f y:yf - 1.0f]
                        t:u];
    
    return [self lerp:x1 b:x2 t:v];
}

+ (float)perlinNoise3D:(simd_float3)point {
    int xi = (int)floorf(point.x) & 255;
    int yi = (int)floorf(point.y) & 255;
    int zi = (int)floorf(point.z) & 255;
    
    float xf = point.x - floorf(point.x);
    float yf = point.y - floorf(point.y);
    float zf = point.z - floorf(point.z);
    
    float u = [self fade:xf];
    float v = [self fade:yf];
    float w = [self fade:zf];
    
    int aaa = permutation[permutation[permutation[xi] + yi] + zi];
    int aba = permutation[permutation[permutation[xi] + ((yi + 1) & 255)] + zi];
    int aab = permutation[permutation[permutation[xi] + yi] + ((zi + 1) & 255)];
    int abb = permutation[permutation[permutation[xi] + ((yi + 1) & 255)] + ((zi + 1) & 255)];
    int baa = permutation[permutation[permutation[(xi + 1) & 255] + yi] + zi];
    int bba = permutation[permutation[permutation[(xi + 1) & 255] + ((yi + 1) & 255)] + zi];
    int bab = permutation[permutation[permutation[(xi + 1) & 255] + yi] + ((zi + 1) & 255)];
    int bbb = permutation[permutation[permutation[(xi + 1) & 255] + ((yi + 1) & 255)] + ((zi + 1) & 255)];
    
    float x1 = [self lerp:[self grad3D:aaa x:xf y:yf z:zf]
                        b:[self grad3D:baa x:xf - 1 y:yf z:zf]
                        t:u];
    float x2 = [self lerp:[self grad3D:aba x:xf y:yf - 1 z:zf]
                        b:[self grad3D:bba x:xf - 1 y:yf - 1 z:zf]
                        t:u];
    float y1 = [self lerp:x1 b:x2 t:v];
    
    x1 = [self lerp:[self grad3D:aab x:xf y:yf z:zf - 1]
                 b:[self grad3D:bab x:xf - 1 y:yf z:zf - 1]
                 t:u];
    x2 = [self lerp:[self grad3D:abb x:xf y:yf - 1 z:zf - 1]
                 b:[self grad3D:bbb x:xf - 1 y:yf - 1 z:zf - 1]
                 t:u];
    float y2 = [self lerp:x1 b:x2 t:v];
    
    return [self lerp:y1 b:y2 t:w];
}

#pragma mark - Simplex Noise

+ (float)simplexNoise2D:(simd_float2)point {
    const float F2 = 0.366025403784f;  // (sqrt(3) - 1) / 2
    const float G2 = 0.211324865405f;  // (3 - sqrt(3)) / 6
    
    float s = (point.x + point.y) * F2;
    float i = floorf(point.x + s);
    float j = floorf(point.y + s);
    
    float t = (i + j) * G2;
    float X0 = i - t;
    float Y0 = j - t;
    float x0 = point.x - X0;
    float y0 = point.y - Y0;
    
    int i1, j1;
    if (x0 > y0) {
        i1 = 1; j1 = 0;
    } else {
        i1 = 0; j1 = 1;
    }
    
    float x1 = x0 - i1 + G2;
    float y1 = y0 - j1 + G2;
    float x2 = x0 - 1.0f + 2.0f * G2;
    float y2 = y0 - 1.0f + 2.0f * G2;
    
    int ii = (int)i & 255;
    int jj = (int)j & 255;
    
    int gi0 = permutation[ii + permutation[jj]] % 12;
    int gi1 = permutation[ii + i1 + permutation[jj + j1]] % 12;
    int gi2 = permutation[ii + 1 + permutation[jj + 1]] % 12;
    
    float n0 = 0.0f;
    float t0 = 0.5f - x0 * x0 - y0 * y0;
    if (t0 >= 0.0f) {
        t0 *= t0;
        n0 = t0 * t0 * [self grad2D:gi0 x:x0 y:y0];
    }
    
    float n1 = 0.0f;
    float t1 = 0.5f - x1 * x1 - y1 * y1;
    if (t1 >= 0.0f) {
        t1 *= t1;
        n1 = t1 * t1 * [self grad2D:gi1 x:x1 y:y1];
    }
    
    float n2 = 0.0f;
    float t2 = 0.5f - x2 * x2 - y2 * y2;
    if (t2 >= 0.0f) {
        t2 *= t2;
        n2 = t2 * t2 * [self grad2D:gi2 x:x2 y:y2];
    }
    
    return 70.0f * (n0 + n1 + n2);
}

+ (float)simplexNoise3D:(simd_float3)point {
    // 3D simplex noise is more complex, using simplified version
    return [self perlinNoise3D:point] * 1.1f;  // Approximate with scaled Perlin
}

#pragma mark - Fractional Brownian Motion

+ (float)fbm2D:(simd_float2)point octaves:(NSInteger)octaves persistence:(float)persistence {
    float total = 0.0f;
    float amplitude = 1.0f;
    float frequency = 1.0f;
    float maxValue = 0.0f;
    
    for (NSInteger i = 0; i < octaves; i++) {
        total += [self perlinNoise2D:simd_make_float2(point.x * frequency, point.y * frequency)] * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0f;
    }
    
    return total / maxValue;
}

+ (float)fbm3D:(simd_float3)point octaves:(NSInteger)octaves persistence:(float)persistence {
    float total = 0.0f;
    float amplitude = 1.0f;
    float frequency = 1.0f;
    float maxValue = 0.0f;
    
    for (NSInteger i = 0; i < octaves; i++) {
        total += [self perlinNoise3D:point * frequency] * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0f;
    }
    
    return total / maxValue;
}

#pragma mark - Turbulence

+ (float)turbulence2D:(simd_float2)point octaves:(NSInteger)octaves {
    float total = 0.0f;
    float amplitude = 1.0f;
    float frequency = 1.0f;
    float maxValue = 0.0f;
    
    for (NSInteger i = 0; i < octaves; i++) {
        total += fabsf([self perlinNoise2D:simd_make_float2(point.x * frequency, point.y * frequency)]) * amplitude;
        maxValue += amplitude;
        amplitude *= 0.5f;
        frequency *= 2.0f;
    }
    
    return total / maxValue;
}

#pragma mark - Voronoi Noise

+ (float)voronoiNoise2D:(simd_float2)point {
    simd_float2 cell = [self voronoiCell2D:point];
    return simd_length(cell - point);
}

+ (simd_float2)voronoiCell2D:(simd_float2)point {
    float minDist = INFINITY;
    simd_float2 closest = point;
    
    int xi = (int)floorf(point.x);
    int yi = (int)floorf(point.y);
    
    // Check 3x3 grid around point
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            int cellX = xi + x;
            int cellY = yi + y;
            
            // Generate feature point in cell
            float hash = (float)permutation[(cellX & 255) + permutation[cellY & 255]] / 255.0f;
            float hash2 = (float)permutation[(cellY & 255) + permutation[cellX & 255]] / 255.0f;
            
            simd_float2 featurePoint = simd_make_float2(cellX + hash, cellY + hash2);
            float dist = simd_distance(point, featurePoint);
            
            if (dist < minDist) {
                minDist = dist;
                closest = featurePoint;
            }
        }
    }
    
    return closest;
}

#pragma mark - Flow Fields

+ (simd_float2)flowField2D:(simd_float2)point time:(float)time {
    float angle = [self perlinNoise3D:simd_make_float3(point.x * 0.1f, point.y * 0.1f, time * 0.1f)] * M_PI * 2.0f;
    float magnitude = [self perlinNoise3D:simd_make_float3(point.x * 0.15f + 100, point.y * 0.15f, time * 0.15f)] * 0.5f + 0.5f;
    
    return simd_make_float2(cosf(angle) * magnitude, sinf(angle) * magnitude);
}

+ (simd_float3)flowField3D:(simd_float3)point time:(float)time {
    simd_float3 offset = simd_make_float3(100, 200, 300);
    
    float x = [self perlinNoise3D:simd_make_float3(point.x * 0.1f, point.y * 0.1f, point.z * 0.1f + time * 0.1f)];
    float y = [self perlinNoise3D:(point + offset) * 0.1f + simd_make_float3(0, 0, time * 0.1f)];
    float z = [self perlinNoise3D:(point - offset) * 0.1f + simd_make_float3(0, 0, time * 0.1f)];
    
    return simd_make_float3(x, y, z);
}

#pragma mark - Curl Noise

+ (simd_float2)curlNoise2D:(simd_float2)point time:(float)time {
    const float epsilon = 0.01f;
    
    // Sample potential field at neighboring points
    float n1 = [self perlinNoise3D:simd_make_float3(point.x, point.y - epsilon, time)];
    float n2 = [self perlinNoise3D:simd_make_float3(point.x, point.y + epsilon, time)];
    float n3 = [self perlinNoise3D:simd_make_float3(point.x - epsilon, point.y, time)];
    float n4 = [self perlinNoise3D:simd_make_float3(point.x + epsilon, point.y, time)];
    
    // Compute curl (perpendicular to gradient)
    float dx = (n2 - n1) / (2.0f * epsilon);
    float dy = (n4 - n3) / (2.0f * epsilon);
    
    return simd_make_float2(dy, -dx);
}

#pragma mark - Artistic Noise Functions

+ (float)electricNoise:(simd_float2)point time:(float)time {
    // Jagged, electric-looking noise
    float noise = [self turbulence2D:point * 0.5f octaves:3];
    noise = powf(noise, 3.0f);  // Make it more dramatic
    
    // Add time-based flickering
    float flicker = sinf(time * 20.0f + noise * 10.0f) * 0.1f;
    
    // Add branching patterns
    float branches = [self fbm2D:point * 2.0f octaves:2 persistence:0.3f];
    branches = fmaxf(0.0f, branches - 0.3f) * 3.0f;
    
    return noise + flicker + branches;
}

+ (float)liquidNoise:(simd_float2)point time:(float)time {
    // Smooth, flowing liquid-like noise
    simd_float2 flow = [self flowField2D:point * 0.1f time:time * 0.5f];
    simd_float2 distortedPoint = point + flow * 10.0f;
    
    // Multiple layers of smooth noise
    float layer1 = [self simplexNoise2D:distortedPoint * 0.05f + simd_make_float2(time * 0.1f, 0)];
    float layer2 = [self simplexNoise2D:distortedPoint * 0.1f + simd_make_float2(0, time * 0.15f)] * 0.5f;
    float layer3 = [self simplexNoise2D:distortedPoint * 0.2f + simd_make_float2(time * 0.2f, time * 0.1f)] * 0.25f;
    
    // Combine with smooth interpolation
    float combined = (layer1 + layer2 + layer3) / 1.75f;
    
    // Add surface tension effect
    combined = [self fade:fabsf(combined)];
    
    return combined;
}

+ (float)crystalNoise:(simd_float2)point time:(float)time {
    // Sharp, crystalline patterns
    simd_float2 cell = [self voronoiCell2D:point * 0.1f];
    float voronoi = [self voronoiNoise2D:point * 0.1f];
    
    // Add faceted structure
    float facets = floorf(voronoi * 10.0f) / 10.0f;
    
    // Add internal refraction patterns
    float refraction = [self perlinNoise2D:cell * 5.0f + simd_make_float2(time * 0.05f, 0)];
    refraction = fabsf(refraction);
    refraction = powf(refraction, 2.0f);
    
    // Combine with sharp edges
    float crystal = facets * 0.7f + refraction * 0.3f;
    
    // Add sparkle effect
    float sparkle = sinf(time * 10.0f + voronoi * 100.0f) > 0.9f ? 1.0f : 0.0f;
    
    return crystal + sparkle * 0.2f;
}

@end