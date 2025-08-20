#pragma once

#import <Foundation/Foundation.h>
#import "drag_effect_protocol.h"

// Notification names
extern NSString* const EffectManagerDidChangeEffectNotification;
extern NSString* const EffectManagerPerformanceWarningNotification;

@interface EffectManager : NSObject

// Singleton access
+ (instancetype)sharedManager;

// Effect management
@property (nonatomic, strong, readonly) NSMutableArray<id<DragEffectProtocol>>* availableEffects;
@property (nonatomic, strong) id<DragEffectProtocol> currentEffect;
@property (nonatomic, readonly) NSInteger currentEffectIndex;

// Registration and discovery
- (void)registerEffect:(id<DragEffectProtocol>)effect;
- (void)unregisterEffect:(id<DragEffectProtocol>)effect;
- (void)discoverBuiltInEffects;
- (void)loadPluginsFromDirectory:(NSString*)path;

// Effect switching
- (void)selectEffectAtIndex:(NSInteger)index;
- (void)selectEffectByName:(NSString*)name;
- (void)cycleToNextEffect;
- (void)cycleToPreviousEffect;

// Performance monitoring
@property (nonatomic) BOOL performanceMonitoringEnabled;
@property (nonatomic, readonly) NSDictionary* performanceMetrics;

// Configuration
- (void)saveCurrentConfiguration;
- (void)loadConfiguration;
- (NSDictionary*)effectConfiguration;

// Animation loop
- (void)startAnimationLoop;
- (void)stopAnimationLoop;
- (void)updateEffects:(NSTimeInterval)deltaTime;

// Debug/Demo modes
@property (nonatomic) BOOL debugModeEnabled;
@property (nonatomic) BOOL splitScreenDemoMode;
- (void)enableSplitScreenComparison:(id<DragEffectProtocol>)leftEffect 
                          rightEffect:(id<DragEffectProtocol>)rightEffect;

@end