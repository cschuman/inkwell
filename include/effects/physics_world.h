#ifndef EFFECTS_PHYSICS_WORLD_H
#define EFFECTS_PHYSICS_WORLD_H

#import <Foundation/Foundation.h>
#import <simd/simd.h>

// High-performance physics calculations for drag effects
// Uses SIMD for vectorized operations and spatial hashing for efficiency

@interface PhysicsParticle : NSObject
@property (nonatomic) simd_float2 position;
@property (nonatomic) simd_float2 oldPosition;  // For Verlet integration
@property (nonatomic) simd_float2 acceleration;
@property (nonatomic) float mass;
@property (nonatomic) float damping;
@property (nonatomic) float lifetime;
@property (nonatomic) NSInteger gridIndex;  // Spatial hash index
@end

@interface SpringConstraint : NSObject
@property (nonatomic, assign) PhysicsParticle* particleA;
@property (nonatomic, assign) PhysicsParticle* particleB;
@property (nonatomic) float restLength;
@property (nonatomic) float stiffness;
@property (nonatomic) float damping;
@end

@interface VectorField : NSObject
- (simd_float2)forceAtPoint:(simd_float2)point time:(NSTimeInterval)time;
- (void)addAttractor:(simd_float2)position strength:(float)strength;
- (void)addVortex:(simd_float2)position strength:(float)strength radius:(float)radius;
- (void)clear;
@end

@interface PhysicsWorld : NSObject

@property (nonatomic) simd_float2 gravity;
@property (nonatomic) float airDensity;
@property (nonatomic) simd_float2 windVelocity;
@property (nonatomic, readonly) NSMutableArray<PhysicsParticle*>* particles;
@property (nonatomic, readonly) NSMutableArray<SpringConstraint*>* constraints;
@property (nonatomic, strong) VectorField* vectorField;

// Spatial hashing for collision detection
@property (nonatomic) NSInteger gridWidth;
@property (nonatomic) NSInteger gridHeight;
@property (nonatomic) float cellSize;

- (instancetype)initWithBounds:(CGRect)bounds cellSize:(float)cellSize;

// Particle management
- (PhysicsParticle*)addParticleAt:(simd_float2)position 
                          withMass:(float)mass;
- (void)removeParticle:(PhysicsParticle*)particle;
- (void)removeAllParticles;

// Spring constraints for elastic behaviors
- (SpringConstraint*)connectParticles:(PhysicsParticle*)a 
                                   to:(PhysicsParticle*)b 
                        withStiffness:(float)stiffness;

// Main physics step using Verlet integration
- (void)stepWithDeltaTime:(NSTimeInterval)dt;

// Apply forces
- (void)applyImpulseToParticle:(PhysicsParticle*)particle 
                       impulse:(simd_float2)impulse;
- (void)applyExplosionAt:(simd_float2)center 
                   force:(float)force 
                  radius:(float)radius;

// Spatial queries
- (NSArray<PhysicsParticle*>*)particlesNearPoint:(simd_float2)point 
                                           radius:(float)radius;
- (PhysicsParticle*)nearestParticleToPoint:(simd_float2)point 
                                  maxRadius:(float)maxRadius;

// Performance metrics
- (NSUInteger)activeParticleCount;
- (float)averageParticleSpeed;

@end

#endif // EFFECTS_PHYSICS_WORLD_H