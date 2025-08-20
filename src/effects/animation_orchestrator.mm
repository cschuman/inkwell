#import "../../include/effects/animation_orchestrator.h"
#import <mach/mach_time.h>

@implementation AnimationCurve

+ (instancetype)linear {
    AnimationCurve* curve = [[AnimationCurve alloc] init];
    curve.function = EasingLinear;
    return curve;
}

+ (instancetype)easeInOutCubic {
    AnimationCurve* curve = [[AnimationCurve alloc] init];
    curve.function = EasingCubicInOut;
    return curve;
}

+ (instancetype)springWithDamping:(float)damping stiffness:(float)stiffness {
    AnimationCurve* curve = [[AnimationCurve alloc] init];
    curve.function = EasingSpring;
    curve.springDamping = damping;
    curve.springStiffness = stiffness;
    return curve;
}

+ (instancetype)elasticWithOvershoot:(float)overshoot {
    AnimationCurve* curve = [[AnimationCurve alloc] init];
    curve.function = EasingElasticOut;
    curve.overshoot = overshoot;
    return curve;
}

- (float)valueForProgress:(float)t {
    t = fmaxf(0.0f, fminf(1.0f, t));  // Clamp to [0, 1]
    
    switch (self.function) {
        case EasingLinear:
            return t;
            
        case EasingQuadraticIn:
            return t * t;
            
        case EasingQuadraticOut:
            return t * (2.0f - t);
            
        case EasingQuadraticInOut:
            return t < 0.5f ? 2.0f * t * t : -1.0f + (4.0f - 2.0f * t) * t;
            
        case EasingCubicIn:
            return t * t * t;
            
        case EasingCubicOut: {
            float t1 = t - 1.0f;
            return t1 * t1 * t1 + 1.0f;
        }
            
        case EasingCubicInOut:
            return t < 0.5f ? 4.0f * t * t * t : (t - 1.0f) * (2.0f * t - 2.0f) * (2.0f * t - 2.0f) + 1.0f;
            
        case EasingQuarticIn:
            return t * t * t * t;
            
        case EasingQuarticOut: {
            float t1 = t - 1.0f;
            return 1.0f - t1 * t1 * t1 * t1;
        }
            
        case EasingQuarticInOut:
            return t < 0.5f ? 8.0f * t * t * t * t : 1.0f - 8.0f * (t - 1.0f) * (t - 1.0f) * (t - 1.0f) * (t - 1.0f);
            
        case EasingExponentialIn:
            return t == 0.0f ? 0.0f : powf(2.0f, 10.0f * (t - 1.0f));
            
        case EasingExponentialOut:
            return t == 1.0f ? 1.0f : 1.0f - powf(2.0f, -10.0f * t);
            
        case EasingExponentialInOut:
            if (t == 0.0f) return 0.0f;
            if (t == 1.0f) return 1.0f;
            return t < 0.5f ? 0.5f * powf(2.0f, 20.0f * t - 10.0f) : 1.0f - 0.5f * powf(2.0f, -20.0f * t + 10.0f);
            
        case EasingCircularIn:
            return 1.0f - sqrtf(1.0f - t * t);
            
        case EasingCircularOut:
            return sqrtf(1.0f - (t - 1.0f) * (t - 1.0f));
            
        case EasingCircularInOut:
            return t < 0.5f ? 0.5f * (1.0f - sqrtf(1.0f - 4.0f * t * t)) : 0.5f * (sqrtf(1.0f - 4.0f * (t - 1.0f) * (t - 1.0f)) + 1.0f);
            
        case EasingElasticIn: {
            if (t == 0.0f || t == 1.0f) return t;
            float p = 0.3f;
            float s = p / 4.0f;
            float t1 = t - 1.0f;
            return -powf(2.0f, 10.0f * t1) * sinf((t1 - s) * (2.0f * M_PI) / p);
        }
            
        case EasingElasticOut: {
            if (t == 0.0f || t == 1.0f) return t;
            float p = 0.3f;
            float s = p / 4.0f;
            return powf(2.0f, -10.0f * t) * sinf((t - s) * (2.0f * M_PI) / p) + 1.0f;
        }
            
        case EasingElasticInOut: {
            if (t == 0.0f || t == 1.0f) return t;
            float p = 0.45f;
            float s = p / 4.0f;
            
            if (t < 0.5f) {
                float t1 = 2.0f * t - 1.0f;
                return -0.5f * powf(2.0f, 10.0f * t1) * sinf((t1 - s) * (2.0f * M_PI) / p);
            } else {
                float t1 = 2.0f * t - 1.0f;
                return 0.5f * powf(2.0f, -10.0f * t1) * sinf((t1 - s) * (2.0f * M_PI) / p) + 1.0f;
            }
        }
            
        case EasingBackIn: {
            float s = self.overshoot > 0 ? self.overshoot : 1.70158f;
            return t * t * ((s + 1.0f) * t - s);
        }
            
        case EasingBackOut: {
            float s = self.overshoot > 0 ? self.overshoot : 1.70158f;
            float t1 = t - 1.0f;
            return t1 * t1 * ((s + 1.0f) * t1 + s) + 1.0f;
        }
            
        case EasingBackInOut: {
            float s = (self.overshoot > 0 ? self.overshoot : 1.70158f) * 1.525f;
            
            if (t < 0.5f) {
                return 2.0f * t * t * ((s + 1.0f) * 2.0f * t - s);
            } else {
                float t1 = 2.0f * t - 2.0f;
                return 0.5f * (t1 * t1 * ((s + 1.0f) * t1 + s) + 2.0f);
            }
        }
            
        case EasingBounceIn:
            return 1.0f - [self bounceOut:1.0f - t];
            
        case EasingBounceOut:
            return [self bounceOut:t];
            
        case EasingBounceInOut:
            return t < 0.5f ? 0.5f * (1.0f - [self bounceOut:1.0f - 2.0f * t]) : 0.5f * [self bounceOut:2.0f * t - 1.0f] + 0.5f;
            
        case EasingSpring: {
            // Critically damped spring
            float omega = self.springStiffness;
            float zeta = self.springDamping;
            float envelope = expf(-zeta * omega * t);
            float oscillation = cosf(omega * sqrtf(1.0f - zeta * zeta) * t);
            return 1.0f - envelope * oscillation;
        }
    }
    
    return t;
}

- (float)bounceOut:(float)t {
    if (t < 1.0f / 2.75f) {
        return 7.5625f * t * t;
    } else if (t < 2.0f / 2.75f) {
        float t1 = t - 1.5f / 2.75f;
        return 7.5625f * t1 * t1 + 0.75f;
    } else if (t < 2.5f / 2.75f) {
        float t1 = t - 2.25f / 2.75f;
        return 7.5625f * t1 * t1 + 0.9375f;
    } else {
        float t1 = t - 2.625f / 2.75f;
        return 7.5625f * t1 * t1 + 0.984375f;
    }
}

@end

@implementation AnimationChannel

- (instancetype)init {
    if (self = [super init]) {
        _identifier = [[NSUUID UUID] UUIDString];
        _curve = [AnimationCurve linear];
    }
    return self;
}

- (void)updateWithDeltaTime:(NSTimeInterval)dt {
    if (self.isComplete) return;
    
    self.elapsed += dt;
    
    if (self.elapsed >= self.duration) {
        self.elapsed = self.duration;
        self.isComplete = YES;
    }
    
    float progress = self.duration > 0 ? self.elapsed / self.duration : 1.0f;
    float easedProgress = [self.curve valueForProgress:progress];
    
    self.currentValue = self.startValue + (self.endValue - self.startValue) * easedProgress;
    
    if (self.updateBlock) {
        self.updateBlock(self.currentValue);
    }
    
    if (self.isComplete && self.completionBlock) {
        self.completionBlock();
        self.completionBlock = nil;  // Prevent multiple calls
    }
}

- (void)reset {
    self.elapsed = 0;
    self.isComplete = NO;
    self.currentValue = self.startValue;
}

@end

@implementation BezierPath

- (instancetype)init {
    if (self = [super init]) {
        _controlPoints = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)pathWithStart:(simd_float2)start end:(simd_float2)end {
    BezierPath* path = [[BezierPath alloc] init];
    [path.controlPoints addObject:[NSValue valueWithBytes:&start objCType:@encode(simd_float2)]];
    [path.controlPoints addObject:[NSValue valueWithBytes:&end objCType:@encode(simd_float2)]];
    return path;
}

- (void)addControlPoint:(simd_float2)point {
    [self.controlPoints addObject:[NSValue valueWithBytes:&point objCType:@encode(simd_float2)]];
}

- (simd_float2)pointAtProgress:(float)t {
    if (self.controlPoints.count < 2) return simd_make_float2(0, 0);
    
    if (self.controlPoints.count == 2) {
        // Linear interpolation
        simd_float2 p0, p1;
        [self.controlPoints[0] getValue:&p0];
        [self.controlPoints[1] getValue:&p1];
        return simd_mix(p0, p1, t);
    }
    
    if (self.controlPoints.count == 3) {
        // Quadratic Bézier
        simd_float2 p0, p1, p2;
        [self.controlPoints[0] getValue:&p0];
        [self.controlPoints[1] getValue:&p1];
        [self.controlPoints[2] getValue:&p2];
        
        float oneMinusT = 1.0f - t;
        return p0 * oneMinusT * oneMinusT + p1 * 2.0f * oneMinusT * t + p2 * t * t;
    }
    
    if (self.controlPoints.count == 4) {
        // Cubic Bézier
        simd_float2 p0, p1, p2, p3;
        [self.controlPoints[0] getValue:&p0];
        [self.controlPoints[1] getValue:&p1];
        [self.controlPoints[2] getValue:&p2];
        [self.controlPoints[3] getValue:&p3];
        
        return CubicBezier2D(t, p0, p1, p2, p3);
    }
    
    // For more points, use Catmull-Rom spline
    NSInteger segment = (NSInteger)(t * (self.controlPoints.count - 1));
    segment = MIN(segment, self.controlPoints.count - 2);
    
    float localT = (t * (self.controlPoints.count - 1)) - segment;
    
    simd_float2 p0, p1, p2, p3;
    
    NSInteger i0 = MAX(0, segment - 1);
    NSInteger i1 = segment;
    NSInteger i2 = MIN(self.controlPoints.count - 1, segment + 1);
    NSInteger i3 = MIN(self.controlPoints.count - 1, segment + 2);
    
    [self.controlPoints[i0] getValue:&p0];
    [self.controlPoints[i1] getValue:&p1];
    [self.controlPoints[i2] getValue:&p2];
    [self.controlPoints[i3] getValue:&p3];
    
    return CatmullRom2D(localT, p0, p1, p2, p3);
}

- (simd_float2)tangentAtProgress:(float)t {
    float dt = 0.001f;
    simd_float2 p0 = [self pointAtProgress:fmaxf(0.0f, t - dt)];
    simd_float2 p1 = [self pointAtProgress:fminf(1.0f, t + dt)];
    return simd_normalize(p1 - p0);
}

- (float)curvatureAtProgress:(float)t {
    float dt = 0.001f;
    simd_float2 tangent0 = [self tangentAtProgress:fmaxf(0.0f, t - dt)];
    simd_float2 tangent1 = [self tangentAtProgress:fminf(1.0f, t + dt)];
    float angle = acosf(simd_dot(tangent0, tangent1));
    return angle / (2.0f * dt);
}

- (float)arcLength {
    // Approximate arc length using numerical integration
    float length = 0;
    NSInteger segments = 100;
    simd_float2 previousPoint = [self pointAtProgress:0];
    
    for (NSInteger i = 1; i <= segments; i++) {
        float t = (float)i / segments;
        simd_float2 currentPoint = [self pointAtProgress:t];
        length += simd_distance(previousPoint, currentPoint);
        previousPoint = currentPoint;
    }
    
    return length;
}

@end

@interface AnimationOrchestrator ()
@property (nonatomic) NSMutableArray<AnimationChannel*>* activeAnimations;
@property (nonatomic) NSMutableDictionary<NSString*, AnimationChannel*>* animationsByID;
@property (nonatomic) NSTimeInterval lastFrameTime;
@property (nonatomic) NSTimeInterval totalTime;
@property (nonatomic) NSMutableArray<NSNumber*>* recentFrameTimes;
@property (nonatomic) NSInteger targetFPS;
@property (nonatomic) mach_timebase_info_data_t timebaseInfo;
@property (nonatomic) NSTimer* displayTimer;
@end

@implementation AnimationOrchestrator
@synthesize delegate = _delegate;

- (instancetype)init {
    if (self = [super init]) {
        _activeAnimations = [NSMutableArray array];
        _animationsByID = [NSMutableDictionary dictionary];
        _recentFrameTimes = [NSMutableArray array];
        _targetFPS = 60;
        _adaptiveQuality = YES;
        
        mach_timebase_info(&_timebaseInfo);
    }
    return self;
}

- (void)dealloc {
    [self stop];
    [_displayTimer release];
    [_activeAnimations release];
    [_animationsByID release];
    [_recentFrameTimes release];
    [super dealloc];
}

- (void)start {
    if (_displayTimer) return;
    
    NSTimeInterval interval = 1.0 / (NSTimeInterval)_targetFPS;
    _displayTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(tick:)
                                                  userInfo:nil
                                                   repeats:YES];
    
    _lastFrameTime = CACurrentMediaTime();
    _frameCount = 0;
    _totalTime = 0;
}

- (void)pause {
    [_displayTimer invalidate];
    _displayTimer = nil;
}

- (void)resume {
    [self start];
    _lastFrameTime = CACurrentMediaTime();  // Reset to avoid huge delta
}

- (void)stop {
    [_displayTimer invalidate];
    _displayTimer = nil;
    [self cancelAllAnimations];
}

- (void)tick:(NSTimer*)timer {
    NSTimeInterval currentTime = CACurrentMediaTime();
    NSTimeInterval deltaTime = currentTime - _lastFrameTime;
    
    // Cap delta time to prevent instability
    deltaTime = fmin(deltaTime, 1.0 / 30.0);
    
    _deltaTime = deltaTime;
    _currentTime = currentTime;
    _lastFrameTime = currentTime;
    _totalTime += deltaTime;
    _frameCount++;
    
    // Track FPS
    [_recentFrameTimes addObject:@(deltaTime)];
    if (_recentFrameTimes.count > 60) {
        [_recentFrameTimes removeObjectAtIndex:0];
    }
    
    // Calculate average FPS
    if (_recentFrameTimes.count > 0) {
        NSTimeInterval avgFrameTime = 0;
        for (NSNumber* time in _recentFrameTimes) {
            avgFrameTime += time.doubleValue;
        }
        avgFrameTime /= _recentFrameTimes.count;
        _averageFPS = avgFrameTime > 0 ? 1.0 / avgFrameTime : 60.0;
    }
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(animationOrchestrator:willBeginFrame:)]) {
        [self.delegate animationOrchestrator:self willBeginFrame:currentTime];
    }
    
    // Update all animations
    NSMutableArray* completedAnimations = [NSMutableArray array];
    
    for (AnimationChannel* channel in self.activeAnimations) {
        [channel updateWithDeltaTime:deltaTime];
        
        if (channel.isComplete) {
            [completedAnimations addObject:channel];
        }
    }
    
    // Remove completed animations
    for (AnimationChannel* channel in completedAnimations) {
        [self.activeAnimations removeObject:channel];
        [self.animationsByID removeObjectForKey:channel.identifier];
        
        if ([self.delegate respondsToSelector:@selector(animationOrchestrator:didCompleteAnimation:)]) {
            [self.delegate animationOrchestrator:self didCompleteAnimation:channel.identifier];
        }
    }
    
    // Notify delegate of update
    if ([self.delegate respondsToSelector:@selector(animationOrchestrator:didUpdateWithDeltaTime:)]) {
        [self.delegate animationOrchestrator:self didUpdateWithDeltaTime:deltaTime];
    }
    
    // Adaptive quality
    if (self.adaptiveQuality && _averageFPS < _targetFPS * 0.9) {
        // Notify effects to reduce quality
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReduceEffectQuality" object:nil];
    }
}

- (AnimationChannel*)animateValue:(float)from 
                              to:(float)to
                        duration:(NSTimeInterval)duration
                           curve:(AnimationCurve*)curve
                          update:(void (^)(float))update
                      completion:(void (^)(void))completion {
    AnimationChannel* channel = [[AnimationChannel alloc] init];
    channel.startValue = from;
    channel.endValue = to;
    channel.currentValue = from;
    channel.duration = duration;
    channel.curve = curve ?: [AnimationCurve linear];
    channel.updateBlock = update;
    channel.completionBlock = completion;
    
    [self.activeAnimations addObject:channel];
    self.animationsByID[channel.identifier] = channel;
    
    return [channel autorelease];
}

- (AnimationChannel*)animateValue:(float)from
                              to:(float)to
                        duration:(NSTimeInterval)duration
                          update:(void (^)(float))update {
    return [self animateValue:from to:to duration:duration curve:nil update:update completion:nil];
}

- (void)cancelAnimation:(NSString*)identifier {
    AnimationChannel* channel = self.animationsByID[identifier];
    if (channel) {
        [self.activeAnimations removeObject:channel];
        [self.animationsByID removeObjectForKey:identifier];
    }
}

- (void)cancelAllAnimations {
    [self.activeAnimations removeAllObjects];
    [self.animationsByID removeAllObjects];
}

- (void)animateAlongPath:(BezierPath*)path
                duration:(NSTimeInterval)duration
                  update:(void (^)(simd_float2, simd_float2))update
              completion:(void (^)(void))completion {
    [self animateValue:0 to:1 duration:duration curve:[AnimationCurve easeInOutCubic] update:^(float t) {
        simd_float2 position = [path pointAtProgress:t];
        simd_float2 tangent = [path tangentAtProgress:t];
        if (update) {
            update(position, tangent);
        }
    } completion:completion];
}

- (void)springAnimateValue:(float)from
                       to:(float)to
                  damping:(float)damping
                stiffness:(float)stiffness
                   update:(void (^)(float))update {
    AnimationCurve* springCurve = [AnimationCurve springWithDamping:damping stiffness:stiffness];
    
    // Calculate approximate duration based on spring parameters
    float settlingTime = 4.0f / (damping * stiffness);
    
    [self animateValue:from to:to duration:settlingTime curve:springCurve update:update completion:nil];
}

- (void)sequence:(NSArray<void (^)(void)>*)animations withDelay:(NSTimeInterval)delay {
    __block NSInteger currentIndex = 0;
    __block void (^runNext)(void);
    
    runNext = ^{
        if (currentIndex < animations.count) {
            void (^animation)(void) = animations[currentIndex];
            currentIndex++;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                animation();
                runNext();
            });
        }
    };
    
    runNext();
}

- (void)setTargetFPS:(NSInteger)fps {
    _targetFPS = fps;
    if (_displayTimer) {
        [self stop];
        [self start];
    }
}

- (float)currentLoad {
    if (_targetFPS <= 0) return 0;
    
    float targetFrameTime = 1.0f / _targetFPS;
    float actualFrameTime = _deltaTime;
    
    return fminf(1.0f, actualFrameTime / targetFrameTime);
}

@end

// Utility implementations

float CubicBezier(float t, float p0, float p1, float p2, float p3) {
    float oneMinusT = 1.0f - t;
    float oneMinusTSq = oneMinusT * oneMinusT;
    float oneMinusTCu = oneMinusTSq * oneMinusT;
    float tSq = t * t;
    float tCu = tSq * t;
    
    return oneMinusTCu * p0 + 3.0f * oneMinusTSq * t * p1 + 3.0f * oneMinusT * tSq * p2 + tCu * p3;
}

simd_float2 CubicBezier2D(float t, simd_float2 p0, simd_float2 p1, simd_float2 p2, simd_float2 p3) {
    float x = CubicBezier(t, p0.x, p1.x, p2.x, p3.x);
    float y = CubicBezier(t, p0.y, p1.y, p2.y, p3.y);
    return simd_make_float2(x, y);
}

float CatmullRom(float t, float p0, float p1, float p2, float p3) {
    float tSq = t * t;
    float tCu = tSq * t;
    
    return 0.5f * ((2.0f * p1) +
                   (-p0 + p2) * t +
                   (2.0f * p0 - 5.0f * p1 + 4.0f * p2 - p3) * tSq +
                   (-p0 + 3.0f * p1 - 3.0f * p2 + p3) * tCu);
}

simd_float2 CatmullRom2D(float t, simd_float2 p0, simd_float2 p1, simd_float2 p2, simd_float2 p3) {
    float x = CatmullRom(t, p0.x, p1.x, p2.x, p3.x);
    float y = CatmullRom(t, p0.y, p1.y, p2.y, p3.y);
    return simd_make_float2(x, y);
}