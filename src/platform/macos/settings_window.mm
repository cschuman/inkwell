#import <Cocoa/Cocoa.h>
#include "ui/settings_manager.h"

@interface SettingsWindowController : NSWindowController

@property (strong) NSSegmentedControl* themeControl;

- (void)themeChanged:(id)sender;

@end

@implementation SettingsWindowController

- (instancetype)init {
    // Create the window
    NSRect frame = NSMakeRect(0, 0, 400, 200);
    NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:NSWindowStyleMaskTitled |
                                                              NSWindowStyleMaskClosable |
                                                              NSWindowStyleMaskMiniaturizable
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    
    self = [super initWithWindow:window];
    if (self) {
        [window setTitle:@"Settings"];
        [window center];
        
        // Create content view
        NSView* contentView = [[NSView alloc] initWithFrame:frame];
        [window setContentView:contentView];
        
        // Title label
        NSTextField* titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 150, 360, 24)];
        [titleLabel setStringValue:@"Appearance"];
        [titleLabel setBezeled:NO];
        [titleLabel setDrawsBackground:NO];
        [titleLabel setEditable:NO];
        [titleLabel setSelectable:NO];
        [titleLabel setFont:[NSFont boldSystemFontOfSize:16]];
        [contentView addSubview:titleLabel];
        
        // Theme label
        NSTextField* themeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 100, 100, 24)];
        [themeLabel setStringValue:@"Theme:"];
        [themeLabel setBezeled:NO];
        [themeLabel setDrawsBackground:NO];
        [themeLabel setEditable:NO];
        [themeLabel setSelectable:NO];
        [contentView addSubview:themeLabel];
        
        // Theme segmented control
        self.themeControl = [[NSSegmentedControl alloc] initWithFrame:NSMakeRect(130, 100, 240, 28)];
        [self.themeControl setSegmentCount:3];
        [self.themeControl setLabel:@"Light" forSegment:0];
        [self.themeControl setLabel:@"Dark" forSegment:1];
        [self.themeControl setLabel:@"System" forSegment:2];
        [self.themeControl setSegmentStyle:NSSegmentStyleTexturedRounded];
        [self.themeControl setTarget:self];
        [self.themeControl setAction:@selector(themeChanged:)];
        
        // Set current selection
        auto& settings = mdviewer::ui::SettingsManager::getInstance();
        NSInteger selectedIndex = static_cast<NSInteger>(settings.getThemeMode());
        [self.themeControl setSelectedSegment:selectedIndex];
        
        [contentView addSubview:self.themeControl];
        
        // Description label
        NSTextField* descLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 50, 360, 40)];
        [descLabel setStringValue:@"Choose how Inkwell appears. Select System to automatically switch between light and dark themes based on your system settings."];
        [descLabel setBezeled:NO];
        [descLabel setDrawsBackground:NO];
        [descLabel setEditable:NO];
        [descLabel setSelectable:NO];
        [descLabel setFont:[NSFont systemFontOfSize:11]];
        [descLabel setTextColor:[NSColor secondaryLabelColor]];
        [descLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [contentView addSubview:descLabel];
    }
    return self;
}

- (void)themeChanged:(id)sender {
    NSInteger selectedIndex = [self.themeControl selectedSegment];
    auto& settings = mdviewer::ui::SettingsManager::getInstance();
    settings.setThemeMode(static_cast<mdviewer::ui::ThemeMode>(selectedIndex));
}

@end

// Global settings window controller
static SettingsWindowController* g_settingsController = nil;

extern "C" void showSettingsWindow() {
    if (!g_settingsController) {
        g_settingsController = [[SettingsWindowController alloc] init];
    }
    
    [g_settingsController showWindow:nil];
    [[g_settingsController window] makeKeyAndOrderFront:nil];
}