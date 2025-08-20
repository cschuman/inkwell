#pragma once

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>

// Protocol that all drag effects must implement
@protocol DragEffectProtocol <NSObject>

@required
// Lifecycle methods
- (void)onDragEnter:(NSPoint)point;
- (void)onDragMove:(NSPoint)point;
- (void)onDragExit;
- (void)onDrop:(NSPoint)point;

// Rendering
- (void)renderToView:(NSView*)view;
- (void)updateWithTimeDelta:(NSTimeInterval)delta;

// Metadata
- (NSString*)effectName;
- (NSString*)effectDescription;
- (NSImage*)previewImage;

@optional
// Performance metrics
- (NSUInteger)estimatedMemoryUsage;
- (CGFloat)gpuUsagePercent;

// Configuration
- (NSDictionary*)currentSettings;
- (void)applySettings:(NSDictionary*)settings;

// Advanced rendering (for Metal-based effects)
- (void)renderWithEncoder:(id<MTLRenderCommandEncoder>)encoder;

@end

// Base class providing common functionality
@interface BaseDragEffect : NSObject <DragEffectProtocol>

@property (nonatomic) NSPoint currentDragPoint;
@property (nonatomic) BOOL isDragging;
@property (nonatomic) NSTimeInterval animationTime;
@property (nonatomic, assign) NSView* targetView;
@property (nonatomic, retain) NSView* dimmingOverlay;

// Subclasses override this for custom initialization
- (void)setupEffect;
- (void)cleanupEffect;

@end