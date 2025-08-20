#import "../../include/effects/effect_manager.h"
#import <QuartzCore/QuartzCore.h>

NSString* const EffectManagerDidChangeEffectNotification = @"EffectManagerDidChangeEffect";
NSString* const EffectManagerPerformanceWarningNotification = @"EffectManagerPerformanceWarning";

@interface EffectManager ()
@property (nonatomic, strong) NSMutableArray<id<DragEffectProtocol>>* availableEffects;
@property (nonatomic) NSInteger currentEffectIndex;
@property (nonatomic, strong) NSTimer* animationTimer;
@property (nonatomic) NSTimeInterval lastUpdateTime;
@property (nonatomic, strong) NSMutableDictionary* performanceMetrics;

// Split screen demo
@property (nonatomic, strong) id<DragEffectProtocol> leftDemoEffect;
@property (nonatomic, strong) id<DragEffectProtocol> rightDemoEffect;
@end

@implementation EffectManager

+ (instancetype)sharedManager {
    static EffectManager* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _availableEffects = [[NSMutableArray array] retain];
        _currentEffectIndex = 0;
        _performanceMetrics = [[NSMutableDictionary dictionary] retain];
        _performanceMonitoringEnabled = NO;
        _debugModeEnabled = NO;
        _splitScreenDemoMode = NO;
        
        [self discoverBuiltInEffects];
        [self loadConfiguration];
    }
    return self;
}

- (void)dealloc {
    [self stopAnimationLoop];
    
    // Release all effects
    for (id<DragEffectProtocol> effect in _availableEffects) {
        [effect release];
    }
    [_availableEffects release];
    
    [_currentEffect release];
    [_performanceMetrics release];
    [_leftDemoEffect release];
    [_rightDemoEffect release];
    
    [super dealloc];
}

#pragma mark - Effect Registration

- (void)registerEffect:(id<DragEffectProtocol>)effect {
    if (![self.availableEffects containsObject:effect]) {
        [effect retain]; // Retain the effect object
        [self.availableEffects addObject:effect];
        NSLog(@"Registered effect: %@", [effect effectName]);
    }
}

- (void)unregisterEffect:(id<DragEffectProtocol>)effect {
    if ([self.availableEffects containsObject:effect]) {
        [self.availableEffects removeObject:effect];
        [effect release]; // Release the effect object
    }
}

- (void)discoverBuiltInEffects {
    // This will be called to register our built-in effects
    // We'll implement the actual effects next
    NSLog(@"Discovering built-in effects...");
}

- (void)loadPluginsFromDirectory:(NSString*)path {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSError* error = nil;
    NSArray* files = [fm contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        NSLog(@"Error loading plugins: %@", error);
        return;
    }
    
    for (NSString* file in files) {
        if ([file hasSuffix:@".effect"]) {
            // In a real implementation, we'd dynamically load these
            NSLog(@"Found effect plugin: %@", file);
        }
    }
}

#pragma mark - Effect Selection

- (void)selectEffectAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.availableEffects.count) {
        _currentEffectIndex = index;
        id<DragEffectProtocol> newEffect = self.availableEffects[index];
        
        // Proper memory management for currentEffect
        if (self.currentEffect != newEffect) {
            [self.currentEffect release];
            self.currentEffect = [newEffect retain];
        }
        
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:EffectManagerDidChangeEffectNotification 
            object:self
            userInfo:@{@"effect": self.currentEffect}];
        
        NSLog(@"Selected effect at index %ld: %@ (class: %@)", 
              (long)index, 
              [self.currentEffect effectName],
              NSStringFromClass([self.currentEffect class]));
    } else {
        NSLog(@"ERROR: Invalid effect index %ld (available: %lu)", 
              (long)index, 
              (unsigned long)self.availableEffects.count);
    }
}

- (void)selectEffectByName:(NSString*)name {
    for (NSInteger i = 0; i < self.availableEffects.count; i++) {
        if ([[self.availableEffects[i] effectName] isEqualToString:name]) {
            [self selectEffectAtIndex:i];
            return;
        }
    }
}

- (void)cycleToNextEffect {
    NSInteger nextIndex = (self.currentEffectIndex + 1) % self.availableEffects.count;
    [self selectEffectAtIndex:nextIndex];
}

- (void)cycleToPreviousEffect {
    NSInteger prevIndex = self.currentEffectIndex - 1;
    if (prevIndex < 0) prevIndex = self.availableEffects.count - 1;
    [self selectEffectAtIndex:prevIndex];
}

#pragma mark - Animation Loop

- (void)startAnimationLoop {
    if (!self.animationTimer) {
        self.lastUpdateTime = CACurrentMediaTime();
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0  // 60 FPS
                                                                target:self 
                                                              selector:@selector(animationTimerCallback:)
                                                              userInfo:nil
                                                               repeats:YES];
    }
}

- (void)stopAnimationLoop {
    [self.animationTimer invalidate];
    self.animationTimer = nil;
}

- (void)animationTimerCallback:(NSTimer*)timer {
    NSTimeInterval currentTime = CACurrentMediaTime();
    NSTimeInterval deltaTime = currentTime - self.lastUpdateTime;
    self.lastUpdateTime = currentTime;
    
    [self updateEffects:deltaTime];
}

- (void)updateEffects:(NSTimeInterval)deltaTime {
    // Update current effect
    if (self.currentEffect) {
        [self.currentEffect updateWithTimeDelta:deltaTime];
    }
    
    // Update demo effects if in split screen mode
    if (self.splitScreenDemoMode) {
        [self.leftDemoEffect updateWithTimeDelta:deltaTime];
        [self.rightDemoEffect updateWithTimeDelta:deltaTime];
    }
    
    // Performance monitoring
    if (self.performanceMonitoringEnabled) {
        [self updatePerformanceMetrics];
    }
}

- (void)updatePerformanceMetrics {
    if ([self.currentEffect respondsToSelector:@selector(gpuUsagePercent)]) {
        CGFloat gpuUsage = [self.currentEffect gpuUsagePercent];
        [self.performanceMetrics setObject:@(gpuUsage) forKey:@"gpuUsage"];
        
        // Warn if GPU usage is too high
        if (gpuUsage > 50.0) {
            [[NSNotificationCenter defaultCenter] 
                postNotificationName:EffectManagerPerformanceWarningNotification
                object:self
                userInfo:@{@"gpuUsage": @(gpuUsage)}];
        }
    }
    
    if ([self.currentEffect respondsToSelector:@selector(estimatedMemoryUsage)]) {
        NSUInteger memUsage = [self.currentEffect estimatedMemoryUsage];
        [self.performanceMetrics setObject:@(memUsage) forKey:@"memoryUsage"];
    }
}

#pragma mark - Configuration

- (void)saveCurrentConfiguration {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.currentEffect effectName] forKey:@"SelectedEffect"];
    [defaults setBool:self.performanceMonitoringEnabled forKey:@"PerformanceMonitoring"];
    [defaults setBool:self.debugModeEnabled forKey:@"DebugMode"];
    [defaults synchronize];
}

- (void)loadConfiguration {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* selectedEffect = [defaults stringForKey:@"SelectedEffect"];
    if (selectedEffect) {
        [self selectEffectByName:selectedEffect];
    }
    
    self.performanceMonitoringEnabled = [defaults boolForKey:@"PerformanceMonitoring"];
    self.debugModeEnabled = [defaults boolForKey:@"DebugMode"];
}

- (NSDictionary*)effectConfiguration {
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    config[@"currentEffect"] = [self.currentEffect effectName];
    config[@"availableEffects"] = [self.availableEffects valueForKey:@"effectName"];
    config[@"performanceMetrics"] = self.performanceMetrics;
    return config;
}

#pragma mark - Demo Modes

- (void)enableSplitScreenComparison:(id<DragEffectProtocol>)leftEffect 
                          rightEffect:(id<DragEffectProtocol>)rightEffect {
    self.splitScreenDemoMode = YES;
    self.leftDemoEffect = leftEffect;
    self.rightDemoEffect = rightEffect;
    
    NSLog(@"Split screen demo: %@ vs %@", 
          [leftEffect effectName], 
          [rightEffect effectName]);
}

@end