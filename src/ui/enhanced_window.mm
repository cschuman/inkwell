#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#include "ui/design_system.h"

using namespace mdviewer::ui;

@interface MDEnhancedWindow : NSWindow
@property (nonatomic) AnimationController* animationController;
@property (nonatomic) Theme* currentTheme;
@property (nonatomic) Theme* targetTheme;
@property (assign) BOOL isTransitioning;
@end

@interface MDVibrancyView : NSVisualEffectView
@property (nonatomic, strong) CAGradientLayer* gradientLayer;
@property (nonatomic, strong) CALayer* noiseLayer;
@end

@interface MDFloatingPanel : NSView
@property (nonatomic, strong) NSVisualEffectView* backgroundView;
@property (nonatomic, strong) CALayer* shadowLayer;
@property (nonatomic) AnimationController* animator;
@property (assign) CGFloat targetAlpha;
@property (assign) CGPoint targetPosition;
@end

@interface MDAnimatedButton : NSButton
@property (nonatomic, strong) CAGradientLayer* gradientLayer;
@property (nonatomic, strong) CAShapeLayer* rippleLayer;
@property (nonatomic) AnimationController* animator;
@property (assign) BOOL isHovering;
@property (assign) CGFloat hoverProgress;
@end

@interface MDSidebarController : NSViewController
@property (nonatomic, strong) NSOutlineView* outlineView;
@property (nonatomic, strong) MDVibrancyView* backgroundView;
@property (nonatomic) AnimationController* animator;
@property (assign) CGFloat width;
@property (assign) BOOL isExpanded;
@end

@implementation MDEnhancedWindow

- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSWindowStyleMask)style
                            backing:(NSBackingStoreType)backingStoreType
                              defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect
                             styleMask:style | NSWindowStyleMaskFullSizeContentView
                               backing:backingStoreType
                                 defer:flag];
    
    if (self) {
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        self.backgroundColor = [NSColor clearColor];
        self.opaque = NO;
        
        // Enable vibrancy
        self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        
        // Initialize animation controller
        _animationController = new AnimationController();
        
        // Initialize themes
        _currentTheme = new Theme(Theme::light());
        _targetTheme = new Theme(Theme::light());
        
        // Set up window properties for award-winning design
        self.minSize = NSMakeSize(600, 400);
        self.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
        
        // Add subtle window shadow
        self.hasShadow = YES;
        NSShadow* shadow = [[NSShadow alloc] init];
        shadow.shadowOffset = NSMakeSize(0, -2);
        shadow.shadowBlurRadius = 20;
        shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.3];
        
        // Observe appearance changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appearanceDidChange:)
                                                     name:NSWindowDidChangeBackingPropertiesNotification
                                                   object:self];
    }
    
    return self;
}

- (void)dealloc {
    delete _animationController;
    delete _currentTheme;
    delete _targetTheme;
    [super dealloc];
}

- (void)appearanceDidChange:(NSNotification*)notification {
    [self animateThemeTransition];
}

- (void)animateThemeTransition {
    if (_isTransitioning) return;
    
    _isTransitioning = YES;
    
    // Determine target theme based on appearance
    BOOL isDark = [self.effectiveAppearance.name containsString:@"Dark"];
    *_targetTheme = isDark ? Theme::dark() : Theme::light();
    
    // Animate theme transition
    AnimationCurve curve;
    curve.type = AnimationCurve::EaseInOut;
    curve.duration = 0.5f;
    
    _animationController->animate(0, 1, curve.duration, curve,
        [self](float progress) {
            self->_currentTheme->interpolate(*self->_targetTheme, progress);
            [self updateWindowAppearance];
        },
        [self]() {
            self->_isTransitioning = NO;
        }
    );
}

- (void)updateWindowAppearance {
    // Update window background color
    CGFloat r = _currentTheme->colors.background.r;
    CGFloat g = _currentTheme->colors.background.g;
    CGFloat b = _currentTheme->colors.background.b;
    CGFloat a = _currentTheme->colors.background.a;
    
    self.backgroundColor = [NSColor colorWithRed:r green:g blue:b alpha:a];
    
    // Notify content view to update
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ThemeDidChange"
                                                        object:self
                                                      userInfo:nil];
}

- (void)makeKeyAndOrderFront:(id)sender {
    [super makeKeyAndOrderFront:sender];
    
    // Animate window appearance with scale and fade
    CABasicAnimation* scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = @(0.95);
    scaleAnimation.toValue = @(1.0);
    scaleAnimation.duration = 0.3;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    CABasicAnimation* opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = @(0.0);
    opacityAnimation.toValue = @(1.0);
    opacityAnimation.duration = 0.3;
    
    [self.contentView.layer addAnimation:scaleAnimation forKey:@"scale"];
    [self.contentView.layer addAnimation:opacityAnimation forKey:@"opacity"];
    
    // Play swoosh sound
    SoundEffects::play(SoundEffects::Swoosh, 0.3f);
}

@end

@implementation MDVibrancyView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        self.state = NSVisualEffectStateActive;
        self.material = NSVisualEffectMaterialSidebar;
        
        // Add gradient overlay
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[
            (__bridge id)[[NSColor whiteColor] colorWithAlphaComponent:0.05].CGColor,
            (__bridge id)[[NSColor whiteColor] colorWithAlphaComponent:0.0].CGColor
        ];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 1);
        
        // Add subtle noise texture for depth
        _noiseLayer = [CALayer layer];
        _noiseLayer.contents = (__bridge id)[self generateNoiseTexture];
        _noiseLayer.opacity = 0.02;
        _noiseLayer.compositingFilter = @"screenBlendMode";
        
        [self.layer addSublayer:_gradientLayer];
        [self.layer addSublayer:_noiseLayer];
    }
    return self;
}

- (CGImageRef)generateNoiseTexture {
    size_t width = 128;
    size_t height = 128;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    
    uint8_t* pixelData = (uint8_t*)calloc(width * height * bytesPerPixel, sizeof(uint8_t));
    
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t pixelIndex = y * bytesPerRow + x * bytesPerPixel;
            uint8_t noise = arc4random_uniform(256);
            pixelData[pixelIndex] = noise;      // R
            pixelData[pixelIndex + 1] = noise;  // G
            pixelData[pixelIndex + 2] = noise;  // B
            pixelData[pixelIndex + 3] = 255;    // A
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, width, height, 8,
                                                bytesPerRow, colorSpace,
                                                kCGImageAlphaPremultipliedLast);
    
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixelData);
    
    return image;
}

- (void)layout {
    [super layout];
    _gradientLayer.frame = self.bounds;
    _noiseLayer.frame = self.bounds;
}

@end

@implementation MDFloatingPanel

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        
        // Create background with vibrancy
        _backgroundView = [[NSVisualEffectView alloc] initWithFrame:self.bounds];
        _backgroundView.blendingMode = NSVisualEffectBlendingModeWithinWindow;
        _backgroundView.material = NSVisualEffectMaterialPopover;
        _backgroundView.state = NSVisualEffectStateActive;
        _backgroundView.wantsLayer = YES;
        _backgroundView.layer.cornerRadius = 12;
        _backgroundView.layer.masksToBounds = YES;
        
        [self addSubview:_backgroundView];
        
        // Add shadow
        _shadowLayer = [CALayer layer];
        _shadowLayer.shadowColor = [NSColor blackColor].CGColor;
        _shadowLayer.shadowOffset = CGSizeMake(0, -4);
        _shadowLayer.shadowRadius = 20;
        _shadowLayer.shadowOpacity = 0.2;
        
        self.layer.masksToBounds = NO;
        [self.layer insertSublayer:_shadowLayer below:_backgroundView.layer];
        
        _animator = new AnimationController();
        _targetAlpha = 1.0;
        _targetPosition = CGPointMake(0, 0);
    }
    return self;
}

- (void)dealloc {
    delete _animator;
    [super dealloc];
}

- (void)animateIn {
    self.alphaValue = 0;
    self.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1);
    
    AnimationCurve curve;
    curve.type = AnimationCurve::Spring;
    curve.stiffness = 300;
    curve.damping = 20;
    
    _animator->spring_animate(0, 1, curve.stiffness, curve.damping,
        [self](float progress) {
            self.alphaValue = progress;
            CGFloat scale = 0.9 + 0.1 * progress;
            self.layer.transform = CATransform3DMakeScale(scale, scale, 1);
        },
        []() {
            HapticFeedback::perform(HapticFeedback::Light);
        }
    );
}

- (void)animateOut {
    AnimationCurve curve;
    curve.type = AnimationCurve::EaseIn;
    curve.duration = 0.2;
    
    _animator->animate(1, 0, curve.duration, curve,
        [self](float progress) {
            self.alphaValue = progress;
            CGFloat scale = 0.9 + 0.1 * progress;
            self.layer.transform = CATransform3DMakeScale(scale, scale, 1);
        },
        [self]() {
            [self removeFromSuperview];
        }
    );
}

- (void)layout {
    [super layout];
    _backgroundView.frame = self.bounds;
    _shadowLayer.frame = self.bounds;
}

@end

@implementation MDAnimatedButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = 8;
        
        // Create gradient layer
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[
            (__bridge id)[NSColor colorWithRed:0 green:0.48 blue:1 alpha:1].CGColor,
            (__bridge id)[NSColor colorWithRed:0.35 green:0.35 blue:0.84 alpha:1].CGColor
        ];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 1);
        _gradientLayer.cornerRadius = 8;
        
        // Create ripple layer for click effects
        _rippleLayer = [CAShapeLayer layer];
        _rippleLayer.fillColor = [NSColor whiteColor].CGColor;
        _rippleLayer.opacity = 0;
        
        [self.layer insertSublayer:_gradientLayer atIndex:0];
        [self.layer addSublayer:_rippleLayer];
        
        _animator = new AnimationController();
        
        // Track mouse events
        NSTrackingArea* trackingArea = [[NSTrackingArea alloc]
            initWithRect:self.bounds
                 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                   owner:self
                userInfo:nil];
        [self addTrackingArea:trackingArea];
    }
    return self;
}

- (void)dealloc {
    delete _animator;
    [super dealloc];
}

- (void)mouseEntered:(NSEvent*)event {
    _isHovering = YES;
    
    AnimationCurve curve;
    curve.type = AnimationCurve::EaseOut;
    curve.duration = 0.2;
    
    _animator->animate(_hoverProgress, 1.0, curve.duration, curve,
        [self](float progress) {
            self->_hoverProgress = progress;
            self.layer.transform = CATransform3DMakeScale(1 + 0.05 * progress, 1 + 0.05 * progress, 1);
            self->_gradientLayer.opacity = 0.9 + 0.1 * progress;
        }
    );
    
    HapticFeedback::perform(HapticFeedback::Selection);
}

- (void)mouseExited:(NSEvent*)event {
    _isHovering = NO;
    
    AnimationCurve curve;
    curve.type = AnimationCurve::EaseOut;
    curve.duration = 0.3;
    
    _animator->animate(_hoverProgress, 0.0, curve.duration, curve,
        [self](float progress) {
            self->_hoverProgress = progress;
            self.layer.transform = CATransform3DMakeScale(1 + 0.05 * progress, 1 + 0.05 * progress, 1);
            self->_gradientLayer.opacity = 0.9 + 0.1 * progress;
        }
    );
}

- (void)mouseDown:(NSEvent*)event {
    // Create ripple effect
    CGPoint clickLocation = [self convertPoint:event.locationInWindow fromView:nil];
    
    CGFloat radius = MAX(self.bounds.size.width, self.bounds.size.height);
    // Create path for ripple effect
    if (@available(macOS 14.0, *)) {
        _rippleLayer.path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(
            clickLocation.x - radius,
            clickLocation.y - radius,
            radius * 2,
            radius * 2
        )].CGPath;
    } else {
        // Fallback for older macOS versions
        NSBezierPath* path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(
            clickLocation.x - radius,
            clickLocation.y - radius,
            radius * 2,
            radius * 2
        )];
        CGMutablePathRef cgPath = CGPathCreateMutable();
        NSInteger elementCount = [path elementCount];
        for (NSInteger i = 0; i < elementCount; i++) {
            NSPoint points[3];
            NSBezierPathElement element = [path elementAtIndex:i associatedPoints:points];
            switch (element) {
                case NSBezierPathElementMoveTo:
                    CGPathMoveToPoint(cgPath, NULL, points[0].x, points[0].y);
                    break;
                case NSBezierPathElementLineTo:
                    CGPathAddLineToPoint(cgPath, NULL, points[0].x, points[0].y);
                    break;
                case NSBezierPathElementCurveTo:
                    CGPathAddCurveToPoint(cgPath, NULL, points[0].x, points[0].y,
                                        points[1].x, points[1].y,
                                        points[2].x, points[2].y);
                    break;
                case NSBezierPathElementClosePath:
                    CGPathCloseSubpath(cgPath);
                    break;
                default:
                    break;
            }
        }
        _rippleLayer.path = cgPath;
        CGPathRelease(cgPath);
    }
    
    CABasicAnimation* scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = @(0.0);
    scaleAnimation.toValue = @(1.0);
    scaleAnimation.duration = 0.4;
    
    CABasicAnimation* opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = @(0.3);
    opacityAnimation.toValue = @(0.0);
    opacityAnimation.duration = 0.4;
    
    [_rippleLayer addAnimation:scaleAnimation forKey:@"scale"];
    [_rippleLayer addAnimation:opacityAnimation forKey:@"opacity"];
    
    SoundEffects::play(SoundEffects::Tap, 0.5f);
    HapticFeedback::perform(HapticFeedback::Medium);
    
    [super mouseDown:event];
}

- (void)layout {
    [super layout];
    _gradientLayer.frame = self.bounds;
}

@end

@implementation MDSidebarController

- (instancetype)init {
    self = [super init];
    if (self) {
        _width = 250;
        _isExpanded = YES;
        _animator = new AnimationController();
    }
    return self;
}

- (void)dealloc {
    delete _animator;
    [super dealloc];
}

- (void)loadView {
    NSView* view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, _width, 600)];
    view.wantsLayer = YES;
    
    // Create vibrancy background
    _backgroundView = [[MDVibrancyView alloc] initWithFrame:view.bounds];
    _backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [view addSubview:_backgroundView];
    
    // Create outline view for TOC
    NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:view.bounds];
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.borderType = NSNoBorder;
    scrollView.backgroundColor = [NSColor clearColor];
    scrollView.drawsBackground = NO;
    
    _outlineView = [[NSOutlineView alloc] initWithFrame:scrollView.bounds];
    _outlineView.floatsGroupRows = NO;
    _outlineView.rowSizeStyle = NSTableViewRowSizeStyleLarge;
    _outlineView.backgroundColor = [NSColor clearColor];
    _outlineView.gridColor = [NSColor clearColor];
    _outlineView.headerView = nil;
    
    NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    column.editable = NO;
    [_outlineView addTableColumn:column];
    _outlineView.outlineTableColumn = column;
    
    scrollView.documentView = _outlineView;
    [view addSubview:scrollView];
    
    self.view = view;
}

- (void)toggleSidebar {
    _isExpanded = !_isExpanded;
    CGFloat targetWidth = _isExpanded ? 250 : 0;
    
    AnimationCurve curve;
    curve.type = AnimationCurve::Spring;
    curve.stiffness = 400;
    curve.damping = 30;
    
    _animator->spring_animate(_width, targetWidth, curve.stiffness, curve.damping,
        [self](float width) {
            self->_width = width;
            NSRect frame = self.view.frame;
            frame.size.width = width;
            self.view.frame = frame;
            
            // Notify parent to adjust layout
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SidebarWidthChanged"
                                                                object:@(width)];
        },
        []() {
            SoundEffects::play(SoundEffects::Swoosh, 0.2f);
        }
    );
}

@end