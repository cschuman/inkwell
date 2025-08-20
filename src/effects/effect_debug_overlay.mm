#import <Cocoa/Cocoa.h>
#import "../../include/effects/effect_manager.h"

@interface EffectDebugOverlay : NSView
@property (nonatomic, strong) NSTextField* effectNameLabel;
@property (nonatomic, strong) NSTextField* performanceLabel;
@property (nonatomic, strong) NSTimer* updateTimer;
@end

@implementation EffectDebugOverlay

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self startMonitoring];
    }
    return self;
}

- (void)setupUI {
    self.wantsLayer = YES;
    self.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.8] CGColor];
    self.layer.cornerRadius = 8.0;
    
    // Effect name label
    self.effectNameLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 40, 200, 20)];
    self.effectNameLabel.bezeled = NO;
    self.effectNameLabel.drawsBackground = NO;
    self.effectNameLabel.editable = NO;
    self.effectNameLabel.selectable = NO;
    self.effectNameLabel.textColor = [NSColor whiteColor];
    self.effectNameLabel.font = [NSFont boldSystemFontOfSize:14];
    [self addSubview:self.effectNameLabel];
    
    // Performance label
    self.performanceLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 10, 200, 20)];
    self.performanceLabel.bezeled = NO;
    self.performanceLabel.drawsBackground = NO;
    self.performanceLabel.editable = NO;
    self.performanceLabel.selectable = NO;
    self.performanceLabel.textColor = [NSColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    self.performanceLabel.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
    [self addSubview:self.performanceLabel];
    
    // Add hotkey hints
    NSTextField* hintLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 70, 200, 40)];
    hintLabel.bezeled = NO;
    hintLabel.drawsBackground = NO;
    hintLabel.editable = NO;
    hintLabel.selectable = NO;
    hintLabel.textColor = [NSColor colorWithWhite:0.7 alpha:1.0];
    hintLabel.font = [NSFont systemFontOfSize:10];
    hintLabel.stringValue = @"⌘⇧E: Next Effect\n⌘⇧D: Previous Effect";
    [self addSubview:hintLabel];
}

- (void)startMonitoring {
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                         target:self
                                                       selector:@selector(updateDisplay)
                                                       userInfo:nil
                                                        repeats:YES];
    
    // Listen for effect changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(effectChanged:)
                                                 name:EffectManagerDidChangeEffectNotification
                                               object:nil];
}

- (void)updateDisplay {
    EffectManager* manager = [EffectManager sharedManager];
    
    if (manager.currentEffect) {
        // Update performance metrics
        CGFloat gpu = 0.0;
        NSUInteger memory = 0;
        
        if ([manager.currentEffect respondsToSelector:@selector(gpuUsagePercent)]) {
            gpu = [manager.currentEffect gpuUsagePercent];
        }
        
        if ([manager.currentEffect respondsToSelector:@selector(estimatedMemoryUsage)]) {
            memory = [manager.currentEffect estimatedMemoryUsage];
        }
        
        self.performanceLabel.stringValue = [NSString stringWithFormat:@"GPU: %.1f%% | MEM: %luKB", 
                                              gpu, (unsigned long)(memory / 1024)];
        
        // Color code based on performance
        if (gpu > 30.0) {
            self.performanceLabel.textColor = [NSColor redColor];
        } else if (gpu > 15.0) {
            self.performanceLabel.textColor = [NSColor yellowColor];
        } else {
            self.performanceLabel.textColor = [NSColor greenColor];
        }
    }
}

- (void)effectChanged:(NSNotification*)notification {
    EffectManager* manager = [EffectManager sharedManager];
    if (manager.currentEffect) {
        self.effectNameLabel.stringValue = [NSString stringWithFormat:@"Effect: %@", 
                                             [manager.currentEffect effectName]];
        
        // Brief flash animation
        CABasicAnimation* flash = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        flash.fromValue = (id)[[NSColor colorWithWhite:0.2 alpha:0.9] CGColor];
        flash.toValue = (id)[[NSColor colorWithWhite:0.0 alpha:0.8] CGColor];
        flash.duration = 0.3;
        [self.layer addAnimation:flash forKey:@"flash"];
    }
}

- (void)dealloc {
    [self.updateTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// Factory method to create and attach debug overlay
@interface EffectDebugOverlay (Factory)
+ (EffectDebugOverlay*)attachToView:(NSView*)parentView;
@end

@implementation EffectDebugOverlay (Factory)

+ (EffectDebugOverlay*)attachToView:(NSView*)parentView {
    NSRect overlayFrame = NSMakeRect(parentView.bounds.size.width - 230, 
                                      parentView.bounds.size.height - 130,
                                      220, 120);
    
    EffectDebugOverlay* overlay = [[EffectDebugOverlay alloc] initWithFrame:overlayFrame];
    overlay.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
    
    [parentView addSubview:overlay positioned:NSWindowAbove relativeTo:nil];
    
    return overlay;
}

@end