#ifndef EFFECTS_ANIMATION_ORCHESTRATOR_H
#define EFFECTS_ANIMATION_ORCHESTRATOR_H

#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

// Sophisticated animation timing and interpolation system
// Provides frame-perfect animations synchronized with display refresh

typedef NS_ENUM(NSInteger, EasingFunction) {
    EasingLinear,
    EasingQuadraticIn,
    EasingQuadraticOut,
    EasingQuadraticInOut,
    EasingCubicIn,
    EasingCubicOut,
    EasingCubicInOut,
    EasingQuarticIn,
    EasingQuarticOut,
    EasingQuarticInOut,
    EasingExponentialIn,
    EasingExponentialOut,
    EasingExponentialInOut,
    EasingCircularIn,
    EasingCircularOut,
    EasingCircularInOut,
    EasingElasticIn,
    EasingElasticOut,
    EasingElasticInOut,
    EasingBackIn,
    EasingBackOut,
    EasingBackInOut,
    EasingBounceIn,
    EasingBounceOut,
    EasingBounceInOut,
    EasingSpring  // Custom spring physics
};

@interface AnimationCurve : NSObject
@property (nonatomic) EasingFunction function;
@property (nonatomic) float springDamping;     // For spring animations
@property (nonatomic) float springStiffness;   // For spring animations
@property (nonatomic) float overshoot;         // For back/elastic animations

+ (instancetype)linear;
+ (instancetype)easeInOutCubic;
+ (instancetype)springWithDamping:(float)damping stiffness:(float)stiffness;
+ (instancetype)elasticWithOvershoot:(float)overshoot;

- (float)valueForProgress:(float)t;
@end

@interface AnimationChannel : NSObject
@property (nonatomic, copy) NSString* identifier;
@property (nonatomic) float startValue;
@property (nonatomic) float endValue;
@property (nonatomic) float currentValue;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval elapsed;
@property (nonatomic) AnimationCurve* curve;
@property (nonatomic) BOOL isComplete;
@property (nonatomic, copy) void (^updateBlock)(float value);
@property (nonatomic, copy) void (^completionBlock)(void);

- (void)updateWithDeltaTime:(NSTimeInterval)dt;
- (void)reset;
@end

@interface BezierPath : NSObject
@property (nonatomic, readonly) NSMutableArray<NSValue*>* controlPoints;

+ (instancetype)pathWithStart:(simd_float2)start end:(simd_float2)end;
- (void)addControlPoint:(simd_float2)point;
- (simd_float2)pointAtProgress:(float)t;
- (simd_float2)tangentAtProgress:(float)t;
- (float)curvatureAtProgress:(float)t;
- (float)arcLength;
@end

@protocol AnimationOrchestrorDelegate <NSObject>
@optional
- (void)animationOrchestrator:(id)orchestrator willBeginFrame:(NSTimeInterval)timestamp;
- (void)animationOrchestrator:(id)orchestrator didUpdateWithDeltaTime:(NSTimeInterval)dt;
- (void)animationOrchestrator:(id)orchestrator didCompleteAnimation:(NSString*)identifier;
@end

@interface AnimationOrchestrator : NSObject

@property (nonatomic, assign) id<AnimationOrchestrorDelegate> delegate;
@property (nonatomic, readonly) NSTimer* displayTimer;
@property (nonatomic, readonly) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval deltaTime;
@property (nonatomic, readonly) NSUInteger frameCount;
@property (nonatomic, readonly) float averageFPS;
@property (nonatomic) BOOL adaptiveQuality;  // Reduce quality if FPS drops

// Lifecycle
- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

// Animation channels
- (AnimationChannel*)animateValue:(float)from 
                              to:(float)to
                        duration:(NSTimeInterval)duration
                           curve:(AnimationCurve*)curve
                          update:(void (^)(float value))update
                      completion:(void (^)(void))completion;

- (AnimationChannel*)animateValue:(float)from
                              to:(float)to
                        duration:(NSTimeInterval)duration
                          update:(void (^)(float value))update;

- (void)cancelAnimation:(NSString*)identifier;
- (void)cancelAllAnimations;

// Path animations
- (void)animateAlongPath:(BezierPath*)path
                duration:(NSTimeInterval)duration
                  update:(void (^)(simd_float2 position, simd_float2 tangent))update
              completion:(void (^)(void))completion;

// Spring physics animations
- (void)springAnimateValue:(float)from
                       to:(float)to
                  damping:(float)damping
                stiffness:(float)stiffness
                   update:(void (^)(float value))update;

// Sequencing
- (void)sequence:(NSArray<void (^)(void)>*)animations 
       withDelay:(NSTimeInterval)delay;

// Performance
- (void)setTargetFPS:(NSInteger)fps;
- (float)currentLoad;  // 0.0 to 1.0 representing animation load

@end

// Utility functions for complex interpolations
float CubicBezier(float t, float p0, float p1, float p2, float p3);
simd_float2 CubicBezier2D(float t, simd_float2 p0, simd_float2 p1, simd_float2 p2, simd_float2 p3);
float CatmullRom(float t, float p0, float p1, float p2, float p3);
simd_float2 CatmullRom2D(float t, simd_float2 p0, simd_float2 p1, simd_float2 p2, simd_float2 p3);

#endif // EFFECTS_ANIMATION_ORCHESTRATOR_H