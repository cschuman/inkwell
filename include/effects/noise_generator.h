#ifndef EFFECTS_NOISE_GENERATOR_H
#define EFFECTS_NOISE_GENERATOR_H

#import <Foundation/Foundation.h>
#import <simd/simd.h>

// High-quality noise generation for organic, natural-looking animations
// Implements Perlin, Simplex, and custom noise functions

@interface NoiseGenerator : NSObject

// Perlin noise - smooth, organic noise with good properties
+ (float)perlinNoise1D:(float)x;
+ (float)perlinNoise2D:(simd_float2)point;
+ (float)perlinNoise3D:(simd_float3)point;

// Simplex noise - faster than Perlin with fewer artifacts
+ (float)simplexNoise2D:(simd_float2)point;
+ (float)simplexNoise3D:(simd_float3)point;

// Fractional Brownian Motion - layered noise for complexity
+ (float)fbm2D:(simd_float2)point octaves:(NSInteger)octaves persistence:(float)persistence;
+ (float)fbm3D:(simd_float3)point octaves:(NSInteger)octaves persistence:(float)persistence;

// Turbulence - absolute value noise for sharp features
+ (float)turbulence2D:(simd_float2)point octaves:(NSInteger)octaves;

// Voronoi/Worley noise - cellular patterns
+ (float)voronoiNoise2D:(simd_float2)point;
+ (simd_float2)voronoiCell2D:(simd_float2)point;

// Flow field generation for particle systems
+ (simd_float2)flowField2D:(simd_float2)point time:(float)time;
+ (simd_float3)flowField3D:(simd_float3)point time:(float)time;

// Curl noise - divergence-free noise for fluid-like motion
+ (simd_float2)curlNoise2D:(simd_float2)point time:(float)time;

// Custom artistic noise functions
+ (float)electricNoise:(simd_float2)point time:(float)time;  // Lightning-like
+ (float)liquidNoise:(simd_float2)point time:(float)time;    // Water-like
+ (float)crystalNoise:(simd_float2)point time:(float)time;   // Crystalline patterns

@end

#endif // EFFECTS_NOISE_GENERATOR_H