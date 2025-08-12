#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#include "ui/design_system.h"
#include <cmath>
#include <algorithm>

using namespace mdviewer::ui;

@interface MDSmoothScrollView : NSScrollView {
    AnimationController* _animator;
    CGFloat _velocity;
    CGFloat _targetOffset;
    CGFloat _currentOffset;
    BOOL _isDecelerating;
    BOOL _isDragging;
    CGPoint _lastDragPoint;
    NSTimeInterval _lastDragTime;
    CGFloat _rubberBandOffset;
    
    // Momentum parameters
    CGFloat _friction;
    CGFloat _springStiffness;
    CGFloat _springDamping;
    
    // Visual feedback
    CAGradientLayer* _overscrollGradient;
    CALayer* _scrollIndicator;
}

@property (nonatomic) BOOL enableMomentum;
@property (nonatomic) BOOL enableRubberBand;
@property (nonatomic) CGFloat scrollSensitivity;

- (void)updateScrollPosition;
- (void)startMomentumScrolling;
- (void)applyRubberBandEffect;
- (void)animateScrollIndicator;

@end

@implementation MDSmoothScrollView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _animator = new AnimationController();
        _enableMomentum = YES;
        _enableRubberBand = YES;
        _scrollSensitivity = 1.0;
        
        // Physics parameters
        _friction = 0.95;  // Deceleration rate
        _springStiffness = 200.0;  // Rubber band stiffness
        _springDamping = 20.0;  // Rubber band damping
        
        // Disable default scrollers for custom implementation
        self.hasVerticalScroller = NO;
        self.hasHorizontalScroller = NO;
        self.scrollerStyle = NSScrollerStyleOverlay;
        
        // Enable layer backing for smooth animations
        self.wantsLayer = YES;
        self.layer.masksToBounds = NO;
        
        // Create overscroll gradient effect
        _overscrollGradient = [CAGradientLayer layer];
        _overscrollGradient.colors = @[
            (__bridge id)[[NSColor clearColor] CGColor],
            (__bridge id)[[NSColor colorWithWhite:0 alpha:0.1] CGColor]
        ];
        _overscrollGradient.locations = @[@0.0, @1.0];
        _overscrollGradient.opacity = 0;
        [self.layer addSublayer:_overscrollGradient];
        
        // Create custom scroll indicator
        _scrollIndicator = [CALayer layer];
        _scrollIndicator.backgroundColor = [[NSColor colorWithWhite:0 alpha:0.3] CGColor];
        _scrollIndicator.cornerRadius = 3;
        _scrollIndicator.opacity = 0;
        [self.layer addSublayer:_scrollIndicator];
        
        // Set up display link for smooth animations
        CVDisplayLinkRef displayLink;
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
        CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, (__bridge void*)self);
        CVDisplayLinkStart(displayLink);
        
        // Track scrolling gestures
        // Touch events configuration
        if (@available(macOS 10.12.2, *)) {
            self.allowedTouchTypes = NSTouchTypeMaskDirect | NSTouchTypeMaskIndirect;
        } else {
            [self setAcceptsTouchEvents:YES];
        }
    }
    return self;
}

- (void)dealloc {
    delete _animator;
    [super dealloc];
}

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                   const CVTimeStamp* now,
                                   const CVTimeStamp* outputTime,
                                   CVOptionFlags flagsIn,
                                   CVOptionFlags* flagsOut,
                                   void* displayLinkContext) {
    @autoreleasepool {
        MDSmoothScrollView* scrollView = (__bridge MDSmoothScrollView*)displayLinkContext;
        dispatch_async(dispatch_get_main_queue(), ^{
            [scrollView updateScrollPosition];
        });
    }
    return kCVReturnSuccess;
}

- (void)scrollWheel:(NSEvent*)event {
    if (!_enableMomentum) {
        [super scrollWheel:event];
        return;
    }
    
    CGFloat deltaY = event.scrollingDeltaY * _scrollSensitivity;
    
    // Handle different scroll phases
    switch (event.phase) {
        case NSEventPhaseBegan:
            _isDragging = YES;
            _isDecelerating = NO;
            _lastDragPoint = NSMakePoint(event.scrollingDeltaX, event.scrollingDeltaY);
            _lastDragTime = event.timestamp;
            [self animateScrollIndicator];
            break;
            
        case NSEventPhaseChanged:
            _currentOffset += deltaY;
            _velocity = deltaY / (event.timestamp - _lastDragTime);
            _lastDragTime = event.timestamp;
            
            // Apply rubber band effect at boundaries
            if (_enableRubberBand) {
                [self applyRubberBandEffect];
            }
            
            [self updateScrollPosition];
            break;
            
        case NSEventPhaseEnded:
        case NSEventPhaseCancelled:
            _isDragging = NO;
            [self startMomentumScrolling];
            break;
            
        default:
            break;
    }
    
    // Handle momentum phase
    if (event.momentumPhase != NSEventPhaseNone) {
        if (event.momentumPhase == NSEventPhaseBegan) {
            _isDecelerating = YES;
        } else if (event.momentumPhase == NSEventPhaseEnded ||
                   event.momentumPhase == NSEventPhaseCancelled) {
            _isDecelerating = NO;
            [self hideScrollIndicator];
        }
    }
    
    // Add haptic feedback for boundaries
    NSRect documentRect = self.documentView.frame;
    NSRect visibleRect = self.documentVisibleRect;
    
    if (_currentOffset <= 0 || _currentOffset >= documentRect.size.height - visibleRect.size.height) {
        HapticFeedback::perform(HapticFeedback::Light);
    }
}

- (void)updateScrollPosition {
    if (!_isDragging && _isDecelerating) {
        // Apply friction to velocity
        _velocity *= _friction;
        
        // Stop when velocity is negligible
        if (fabs(_velocity) < 0.5) {
            _velocity = 0;
            _isDecelerating = NO;
            [self hideScrollIndicator];
        }
        
        _currentOffset += _velocity;
    }
    
    // Apply constraints and rubber band
    NSRect documentRect = self.documentView.frame;
    NSRect visibleRect = self.documentVisibleRect;
    CGFloat maxOffset = MAX(0, documentRect.size.height - visibleRect.size.height);
    
    if (_enableRubberBand) {
        if (_currentOffset < 0) {
            // Top boundary rubber band
            _rubberBandOffset = _currentOffset;
            _currentOffset = 0;
            [self animateRubberBandReturn];
        } else if (_currentOffset > maxOffset) {
            // Bottom boundary rubber band
            _rubberBandOffset = _currentOffset - maxOffset;
            _currentOffset = maxOffset;
            [self animateRubberBandReturn];
        }
    } else {
        _currentOffset = fmax(0, fmin(maxOffset, _currentOffset));
    }
    
    // Apply the scroll
    NSPoint newOrigin = NSMakePoint(0, _currentOffset);
    [self.contentView scrollToPoint:newOrigin];
    [self reflectScrolledClipView:self.contentView];
    
    // Update scroll indicator position
    [self updateScrollIndicator];
    
    // Update overscroll effect
    [self updateOverscrollEffect];
}

- (void)startMomentumScrolling {
    if (fabs(_velocity) < 10) {
        _isDecelerating = NO;
        return;
    }
    
    _isDecelerating = YES;
    
    // Calculate deceleration curve
    AnimationCurve curve;
    curve.type = AnimationCurve::EaseOut;
    curve.duration = 2.0;
    
    CGFloat initialVelocity = _velocity;
    CGFloat decelerationDistance = (initialVelocity * initialVelocity) / (2 * (1 - _friction));
    _targetOffset = _currentOffset + decelerationDistance;
    
    _animator->animate(_currentOffset, _targetOffset, curve.duration, curve,
        [self](float offset) {
            self->_currentOffset = offset;
            [self updateScrollPosition];
        },
        [self]() {
            self->_isDecelerating = NO;
            self->_velocity = 0;
            [self hideScrollIndicator];
        }
    );
}

- (void)applyRubberBandEffect {
    NSRect documentRect = self.documentView.frame;
    NSRect visibleRect = self.documentVisibleRect;
    CGFloat maxOffset = MAX(0, documentRect.size.height - visibleRect.size.height);
    
    CGFloat resistance = 0.5;  // Rubber band resistance factor
    
    if (_currentOffset < 0) {
        // Apply resistance at top
        CGFloat overflow = -_currentOffset;
        CGFloat resistedOverflow = overflow * resistance;
        _currentOffset = -resistedOverflow;
        
        // Visual feedback
        _overscrollGradient.startPoint = CGPointMake(0.5, 0);
        _overscrollGradient.endPoint = CGPointMake(0.5, 0.2);
        _overscrollGradient.opacity = MIN(1.0, resistedOverflow / 50.0);
        
    } else if (_currentOffset > maxOffset) {
        // Apply resistance at bottom
        CGFloat overflow = _currentOffset - maxOffset;
        CGFloat resistedOverflow = overflow * resistance;
        _currentOffset = maxOffset + resistedOverflow;
        
        // Visual feedback
        _overscrollGradient.startPoint = CGPointMake(0.5, 0.8);
        _overscrollGradient.endPoint = CGPointMake(0.5, 1.0);
        _overscrollGradient.opacity = MIN(1.0, resistedOverflow / 50.0);
    }
}

- (void)animateRubberBandReturn {
    if (fabs(_rubberBandOffset) < 0.1) {
        _rubberBandOffset = 0;
        return;
    }
    
    // Spring animation back to boundary
    _animator->spring_animate(_rubberBandOffset, 0, _springStiffness, _springDamping,
        [self](float offset) {
            self->_rubberBandOffset = offset;
            
            // Update visual feedback
            CGFloat opacity = MIN(1.0, fabs(offset) / 50.0);
            self->_overscrollGradient.opacity = opacity;
        },
        [self]() {
            self->_rubberBandOffset = 0;
            self->_overscrollGradient.opacity = 0;
        }
    );
}

- (void)animateScrollIndicator {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _scrollIndicator.opacity = 0.6;
    [CATransaction commit];
    
    CABasicAnimation* fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = @0.0;
    fadeIn.toValue = @0.6;
    fadeIn.duration = 0.15;
    fadeIn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [_scrollIndicator addAnimation:fadeIn forKey:@"fadeIn"];
}

- (void)hideScrollIndicator {
    CABasicAnimation* fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.fromValue = @(_scrollIndicator.opacity);
    fadeOut.toValue = @0.0;
    fadeOut.duration = 0.3;
    fadeOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    fadeOut.fillMode = kCAFillModeForwards;
    fadeOut.removedOnCompletion = NO;
    
    [_scrollIndicator addAnimation:fadeOut forKey:@"fadeOut"];
}

- (void)updateScrollIndicator {
    NSRect documentRect = self.documentView.frame;
    NSRect visibleRect = self.documentVisibleRect;
    
    if (documentRect.size.height <= visibleRect.size.height) {
        _scrollIndicator.hidden = YES;
        return;
    }
    
    _scrollIndicator.hidden = NO;
    
    // Calculate indicator size and position
    CGFloat scrollableHeight = documentRect.size.height - visibleRect.size.height;
    CGFloat scrollProgress = _currentOffset / scrollableHeight;
    
    CGFloat indicatorHeight = (visibleRect.size.height / documentRect.size.height) * visibleRect.size.height;
    indicatorHeight = MAX(30, indicatorHeight);  // Minimum height
    
    CGFloat indicatorY = scrollProgress * (visibleRect.size.height - indicatorHeight);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _scrollIndicator.frame = CGRectMake(
        visibleRect.size.width - 8,
        indicatorY,
        6,
        indicatorHeight
    );
    [CATransaction commit];
}

- (void)updateOverscrollEffect {
    _overscrollGradient.frame = self.bounds;
}

- (void)layout {
    [super layout];
    [self updateScrollIndicator];
    [self updateOverscrollEffect];
}

// Touch gesture support for trackpad
- (void)touchesBeganWithEvent:(NSEvent*)event {
    NSSet<NSTouch*>* touches = [event touchesMatchingPhase:NSTouchPhaseBegan inView:self];
    if (touches.count > 0) {
        _isDragging = YES;
        _isDecelerating = NO;
        [self animateScrollIndicator];
        
        // Haptic feedback
        HapticFeedback::perform(HapticFeedback::Selection);
    }
}

- (void)touchesMovedWithEvent:(NSEvent*)event {
    NSSet<NSTouch*>* touches = [event touchesMatchingPhase:NSTouchPhaseMoved inView:self];
    
    for (NSTouch* touch in touches) {
        NSPoint currentPos = touch.normalizedPosition;
        NSPoint previousPos = touch.normalizedPosition;  // Use current position as fallback
        
        CGFloat deltaY = (currentPos.y - previousPos.y) * self.frame.size.height;
        _currentOffset -= deltaY * _scrollSensitivity;
        _velocity = -deltaY / 0.016;  // Assuming 60fps
        
        [self updateScrollPosition];
    }
}

- (void)touchesEndedWithEvent:(NSEvent*)event {
    _isDragging = NO;
    [self startMomentumScrolling];
}

- (void)magnifyWithEvent:(NSEvent*)event {
    // Pinch-to-zoom support
    CGFloat magnification = 1.0 + event.magnification;
    
    // Animate zoom with spring effect
    AnimationCurve curve;
    curve.type = AnimationCurve::Spring;
    curve.stiffness = 300;
    curve.damping = 25;
    
    _animator->spring_animate(1.0, magnification, curve.stiffness, curve.damping,
        [self](float scale) {
            // Apply scale transform to content
            self.documentView.layer.transform = CATransform3DMakeScale(scale, scale, 1);
        },
        []() {
            HapticFeedback::perform(HapticFeedback::Light);
        }
    );
}

@end

