#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#include "core/markdown_parser.h"
#include "rendering/render_engine.h"
#include "rendering/markdown_renderer.h"
#include "platform/file_watcher.h"
#import "ui/command_palette.h"
#include "version.h"

// Simple command palette function
extern "C" void showSimpleCommandPalette();

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property (strong) NSWindow* window;
@property (strong) NSViewController* mainViewController;
- (void)createMenuBar;
- (void)openDocument:(id)sender;
- (void)showCommandPalette:(id)sender;
- (void)saveWindowFrame;
- (void)restoreWindowFrame;
@end

@interface TOCItem : NSObject
@property (strong) NSString* title;
@property (assign) NSInteger level;
@property (strong) NSMutableArray<TOCItem*>* children;
@property (assign) NSRange range;
@end

@implementation TOCItem
- (instancetype)init {
    self = [super init];
    if (self) {
        _children = [NSMutableArray array];
    }
    return self;
}
@end

// Forward declaration
@class MarkdownViewController;

@interface KeyHandlingView : NSView
@property (assign) NSViewController* controller;
@end

@implementation KeyHandlingView
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent*)event {
    NSString* key = event.charactersIgnoringModifiers;
    NSUInteger modifierFlags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    
    // Check for Cmd+K directly here
    if ([key isEqualToString:@"k"] && (modifierFlags & NSEventModifierFlagCommand)) {
        if ([self.controller respondsToSelector:@selector(showCommandPalette)]) {
            [(MarkdownViewController*)self.controller showCommandPalette];
            return;
        }
    }
    
    // Forward other key events to controller
    if ([self.controller respondsToSelector:@selector(keyDown:)]) {
        [self.controller performSelector:@selector(keyDown:) withObject:event];
    } else {
        [super keyDown:event];
    }
}
@end

// Custom NSTextView that handles vim navigation
@interface VimTextView : NSTextView
@property (assign) MarkdownViewController* markdownController;
@end

@implementation VimTextView

- (void)keyDown:(NSEvent*)event {
    NSString* key = event.charactersIgnoringModifiers;
    NSUInteger modifierFlags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    
    // Let the controller handle vim navigation keys when no modifiers are pressed
    if (modifierFlags == 0 && self.markdownController) {
        if ([key isEqualToString:@"j"] || [key isEqualToString:@"k"] || 
            [key isEqualToString:@"h"] || [key isEqualToString:@"l"] ||
            [key isEqualToString:@"g"]) {
            [self.markdownController keyDown:event];
            return;
        }
    }
    
    // Handle Shift+G for go to bottom
    if ([key isEqualToString:@"G"] && (modifierFlags & NSEventModifierFlagShift) && self.markdownController) {
        [self.markdownController keyDown:event];
        return;
    }
    
    // Handle Cmd+K for command palette
    if ([key isEqualToString:@"k"] && (modifierFlags & NSEventModifierFlagCommand) && self.markdownController) {
        [self.markdownController keyDown:event];
        return;
    }
    
    // Handle Cmd+. for focus mode
    if ([key isEqualToString:@"."] && (modifierFlags & NSEventModifierFlagCommand) && self.markdownController) {
        [self.markdownController keyDown:event];
        return;
    }
    
    // For other keys, use default behavior
    [super keyDown:event];
}

@end

@interface MarkdownViewController : NSViewController <NSDraggingDestination, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSearchFieldDelegate, NSTextViewDelegate, CommandPaletteDelegate>
- (void)applySyntaxHighlighting;
- (void)openFile:(NSString*)path;
- (void)updateAppearance;
- (void)buildTOCFromDocument;
- (void)toggleTOCSidebar;
- (void)showSearchBar;
- (void)hideSearchBar;
- (void)showCommandPalette:(id)sender;
- (void)performSearch:(NSString*)searchTerm;
- (void)findNext;
- (void)findPrevious;
- (void)exportAsPDF:(id)sender;
- (void)exportAsHTML:(id)sender;
- (void)print:(id)sender;
- (void)goBack:(id)sender;
- (void)goForward:(id)sender;
- (void)goToTop:(id)sender;
- (void)goToBottom:(id)sender;
- (void)openRecentFile:(id)sender;
- (void)clearRecentFiles:(id)sender;
- (void)updateRecentFilesMenu;
- (void)addToRecentFiles:(NSString*)path;
- (void)zoomIn:(id)sender;
- (void)zoomOut:(id)sender;
- (void)resetZoom:(id)sender;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    // Create menu bar
    [self createMenuBar];
    
    // Create main window with modern styling
    NSRect frame = NSMakeRect(0, 0, 1000, 700);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | 
                             NSWindowStyleMaskClosable | 
                             NSWindowStyleMaskMiniaturizable | 
                             NSWindowStyleMaskResizable |
                             NSWindowStyleMaskFullSizeContentView;
    
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    NSString* title = [NSString stringWithFormat:@"Markdown Viewer v%s (Build %d)", 
                       mdviewer::getVersionString(), 
                       mdviewer::getBuildNumber()];
    [self.window setTitle:title];
    
    // Set window delegate for position persistence
    [self.window setDelegate:self];
    
    // Restore window position/size from user defaults
    [self restoreWindowFrame];
    
    // Log version info
    NSLog(@"Inkwell Version: %s", mdviewer::getVersionString());
    NSLog(@"Build Number: %d", mdviewer::getBuildNumber());
    NSLog(@"Build Date: %s", mdviewer::getBuildDate());
    
    // Modern macOS window appearance
    self.window.titlebarAppearsTransparent = YES;
    // Show the title so we can see version info
    self.window.titleVisibility = NSWindowTitleVisible;
    self.window.backgroundColor = [NSColor windowBackgroundColor];
    self.window.minSize = NSMakeSize(600, 400);
    
    // Add toolbar with unified style
    NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainToolbar"];
    toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    toolbar.showsBaselineSeparator = NO;
    self.window.toolbar = toolbar;
    self.window.toolbarStyle = NSWindowToolbarStyleUnified;
    
    // Create view controller
    self.mainViewController = [[MarkdownViewController alloc] init];
    [self.window setContentViewController:self.mainViewController];
    
    // Enable drag and drop on window
    [self.window registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    
    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
    return YES;
}

- (BOOL)application:(NSApplication*)sender openFile:(NSString*)filename {
    // Handle file opening
    MarkdownViewController* vc = (MarkdownViewController*)self.mainViewController;
    [vc openFile:filename];
    return YES;
}

- (void)createMenuBar {
    NSMenu* mainMenu = [[NSMenu alloc] init];
    
    // Application menu (first menu)
    NSMenuItem* appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];
    
    NSMenu* appMenu = [[NSMenu alloc] init];
    [appMenuItem setSubmenu:appMenu];
    
    NSString* aboutTitle = [NSString stringWithFormat:@"About Inkwell (v%s)", 
                           mdviewer::getVersionString()];
    NSMenuItem* aboutItem = [appMenu addItemWithTitle:aboutTitle
                                                action:@selector(showAbout:) 
                                         keyEquivalent:@"i"];
    [aboutItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand | NSEventModifierFlagShift];
    [aboutItem setTarget:self];
    
    [appMenu addItem:[NSMenuItem separatorItem]];
    
    [appMenu addItemWithTitle:@"Quit Markdown Viewer" 
                       action:@selector(terminate:) 
                keyEquivalent:@"q"];
    
    // File menu
    NSMenuItem* fileMenuItem = [[NSMenuItem alloc] init];
    [fileMenuItem setTitle:@"File"];
    [mainMenu addItem:fileMenuItem];
    
    NSMenu* fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    [fileMenuItem setSubmenu:fileMenu];
    
    [fileMenu addItemWithTitle:@"Open..." 
                        action:@selector(openDocument:) 
                 keyEquivalent:@"o"];
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    // Recent Files submenu
    NSMenuItem* recentMenuItem = [[NSMenuItem alloc] init];
    [recentMenuItem setTitle:@"Open Recent"];
    [fileMenu addItem:recentMenuItem];
    
    NSMenu* recentFilesMenu = [[NSMenu alloc] initWithTitle:@"Open Recent"];
    [recentMenuItem setSubmenu:recentFilesMenu];
    [recentMenuItem setTag:1001];  // Tag to find it later
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* exportMenuItem = [[NSMenuItem alloc] init];
    [exportMenuItem setTitle:@"Export"];
    [fileMenu addItem:exportMenuItem];
    
    NSMenu* exportMenu = [[NSMenu alloc] initWithTitle:@"Export"];
    [exportMenuItem setSubmenu:exportMenu];
    
    NSMenuItem* exportPDFItem = [exportMenu addItemWithTitle:@"Export as PDF..." 
                                                       action:@selector(exportAsPDF:) 
                                                keyEquivalent:@""];
    [exportPDFItem setTarget:nil];
    
    NSMenuItem* exportHTMLItem = [exportMenu addItemWithTitle:@"Export as HTML..." 
                                                        action:@selector(exportAsHTML:) 
                                                 keyEquivalent:@""];
    [exportHTMLItem setTarget:nil];
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* printItem = [fileMenu addItemWithTitle:@"Print..." 
                                                 action:@selector(print:) 
                                          keyEquivalent:@"p"];
    [printItem setTarget:nil];
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    // Edit menu
    NSMenuItem* editMenuItem = [[NSMenuItem alloc] init];
    [editMenuItem setTitle:@"Edit"];
    [mainMenu addItem:editMenuItem];
    
    NSMenu* editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];
    
    NSMenuItem* commandPaletteItem = [editMenu addItemWithTitle:@"Command Palette..." 
                                                          action:@selector(showCommandPalette:) 
                                                   keyEquivalent:@"k"];
    [commandPaletteItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    // Set AppDelegate (self) as target
    [commandPaletteItem setTarget:self];
    
    [editMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* findItem = [editMenu addItemWithTitle:@"Find..." 
                                                action:@selector(showSearchBar) 
                                         keyEquivalent:@"f"];
    [findItem setTarget:nil];
    
    // Go menu
    NSMenuItem* goMenuItem = [[NSMenuItem alloc] init];
    [goMenuItem setTitle:@"Go"];
    [mainMenu addItem:goMenuItem];
    
    NSMenu* goMenu = [[NSMenu alloc] initWithTitle:@"Go"];
    [goMenuItem setSubmenu:goMenu];
    
    NSMenuItem* goBackItem = [goMenu addItemWithTitle:@"Back" 
                                                action:@selector(goBack:) 
                                         keyEquivalent:@"["];
    [goBackItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [goBackItem setTarget:nil];
    
    NSMenuItem* goForwardItem = [goMenu addItemWithTitle:@"Forward" 
                                                   action:@selector(goForward:) 
                                            keyEquivalent:@"]"];
    [goForwardItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [goForwardItem setTarget:nil];
    
    [goMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* goTopItem = [goMenu addItemWithTitle:@"Go to Top" 
                                               action:@selector(goToTop:) 
                                        keyEquivalent:@""];
    [goTopItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand | NSEventModifierFlagFunction];
    // Home key
    [goTopItem setKeyEquivalent:[NSString stringWithFormat:@"%C", (unichar)NSHomeFunctionKey]];
    [goTopItem setTarget:nil];
    
    NSMenuItem* goBottomItem = [goMenu addItemWithTitle:@"Go to Bottom" 
                                                  action:@selector(goToBottom:) 
                                           keyEquivalent:@""];
    [goBottomItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand | NSEventModifierFlagFunction];
    // End key
    [goBottomItem setKeyEquivalent:[NSString stringWithFormat:@"%C", (unichar)NSEndFunctionKey]];
    [goBottomItem setTarget:nil];
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    [fileMenu addItemWithTitle:@"Close" 
                        action:@selector(performClose:) 
                 keyEquivalent:@"w"];
    
    // View menu
    NSMenuItem* viewMenuItem = [[NSMenuItem alloc] init];
    [viewMenuItem setTitle:@"View"];
    [mainMenu addItem:viewMenuItem];
    
    NSMenu* viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    [viewMenuItem setSubmenu:viewMenu];
    
    // Zoom controls
    NSMenuItem* zoomInItem = [viewMenu addItemWithTitle:@"Zoom In" 
                                                  action:@selector(zoomIn:) 
                                           keyEquivalent:@"+"];
    [zoomInItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [zoomInItem setTarget:nil];
    
    NSMenuItem* zoomOutItem = [viewMenu addItemWithTitle:@"Zoom Out" 
                                                   action:@selector(zoomOut:) 
                                            keyEquivalent:@"-"];
    [zoomOutItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [zoomOutItem setTarget:nil];
    
    NSMenuItem* resetZoomItem = [viewMenu addItemWithTitle:@"Reset Zoom" 
                                                     action:@selector(resetZoom:) 
                                              keyEquivalent:@"0"];
    [resetZoomItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [resetZoomItem setTarget:nil];
    
    [viewMenu addItem:[NSMenuItem separatorItem]];
    
    // TOC and Focus mode
    NSMenuItem* tocItem = [viewMenu addItemWithTitle:@"Toggle Table of Contents" 
                                               action:@selector(toggleTOCSidebar) 
                                        keyEquivalent:@"t"];
    [tocItem setKeyEquivalentModifierMask:(NSEventModifierFlagCommand | NSEventModifierFlagOption)];
    [tocItem setTarget:nil];
    
    NSMenuItem* focusItem = [viewMenu addItemWithTitle:@"Toggle Focus Mode" 
                                                 action:@selector(toggleFocusMode) 
                                          keyEquivalent:@"."];
    [focusItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [focusItem setTarget:nil];
    
    [NSApp setMainMenu:mainMenu];
}

- (void)openDocument:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:@[@"md", @"markdown", @"txt"]];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL* selectedFile = [openPanel URL];
            MarkdownViewController* vc = (MarkdownViewController*)self.mainViewController;
            [vc openFile:[selectedFile path]];
        }
    }];
}

- (void)showCommandPalette:(id)sender {
    NSLog(@"AppDelegate: showCommandPalette called - using simple version");
    
    // Use the simple command palette that works
    showSimpleCommandPalette();
}

- (void)showAbout:(id)sender {
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Inkwell"];
    
    NSString* info = [NSString stringWithFormat:
        @"Version: %s\n"
        @"Build: %d\n"
        @"Built: %s\n\n"
        @"A native macOS markdown viewer with a clean, minimal interface.\n\n"
        @"Working Features:\n"
        @"• Full-text search (Cmd+F)\n"
        @"• Vim navigation (j/k/g/G)\n"
        @"• File watching with auto-reload\n"
        @"• Export to PDF and HTML\n"
        @"• Command palette (Cmd+K)\n"
        @"• Dark/Light theme support\n\n"
        @"© 2024 Inkwell\n"
        @"Licensed under MIT License",
        mdviewer::getVersionString(),
        mdviewer::getBuildNumber(),
        mdviewer::getBuildDate()];
    
    [alert setInformativeText:info];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[NSImage imageNamed:NSImageNameInfo]];
    [alert runModal];
}

- (void)saveWindowFrame {
    NSString* frameString = NSStringFromRect(self.window.frame);
    [[NSUserDefaults standardUserDefaults] setObject:frameString forKey:@"InkwellWindowFrame"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreWindowFrame {
    NSString* frameString = [[NSUserDefaults standardUserDefaults] stringForKey:@"InkwellWindowFrame"];
    if (frameString) {
        NSRect frame = NSRectFromString(frameString);
        // Verify the frame is visible on at least one screen
        BOOL isVisible = NO;
        for (NSScreen* screen in [NSScreen screens]) {
            if (NSIntersectsRect(frame, screen.frame)) {
                isVisible = YES;
                break;
            }
        }
        
        if (isVisible) {
            [self.window setFrame:frame display:NO];
        } else {
            // If not visible, center the window
            [self.window center];
        }
    } else {
        [self.window center];
    }
}

// NSWindowDelegate methods
- (void)windowDidMove:(NSNotification*)notification {
    [self saveWindowFrame];
}

- (void)windowDidResize:(NSNotification*)notification {
    [self saveWindowFrame];
}

- (void)windowWillClose:(NSNotification*)notification {
    [self saveWindowFrame];
}

@end

@implementation MarkdownViewController {
    // MTKView* _metalView;  // Commented out for now
    NSTextView* _textView;
    NSScrollView* _scrollView;
    NSTextField* _statusLabel;
    // NSTextField* _readingTimeLabel; // Removed - no floating badge
    NSView* _topScrollIndicator;
    NSView* _bottomScrollIndicator;
    BOOL _focusModeEnabled;
    // NSView* _focusOverlay; // Removed - no focus overlay/vignette
    NSSplitView* _splitView;
    NSOutlineView* _tocOutlineView;
    NSScrollView* _tocScrollView;
    NSMutableArray* _tocItems;
    
    // Font size management
    CGFloat _currentFontSize;
    CGFloat _baseFontSize;
    // Search UI
    NSView* _searchBar;
    NSSearchField* _searchField;
    NSButton* _nextButton;
    NSButton* _previousButton;
    NSTextField* _searchResultLabel;
    NSMutableArray* _searchResults;
    NSInteger _currentSearchIndex;
    // id<MTLDevice> _device;  // Commented out for now
    // id<MTLCommandQueue> _commandQueue;  // Commented out for now
    std::unique_ptr<mdviewer::MarkdownParser> _parser;
    // std::unique_ptr<mdviewer::RenderEngine> _renderEngine;  // Commented out for now
    std::unique_ptr<mdviewer::FileWatcher> _fileWatcher;
    std::unique_ptr<mdviewer::Document> _currentDocument;
    
    // Navigation history
    NSMutableArray<NSString*>* _navigationHistory;
    NSInteger _currentHistoryIndex;
    BOOL _isNavigatingHistory;
    
    // Recent files
    NSMutableArray<NSString*>* _recentFiles;
    
    // Command Palette
    CommandPaletteController* _commandPalette;
    
    // Performance metrics
    NSString* _currentFilePath;
    NSUInteger _currentFileSize;
    NSUInteger _currentLineCount;
    NSTimeInterval _lastParseTime;
    NSTimeInterval _lastRenderTime;
    NSTimer* _fpsTimer;
    NSInteger _frameCount;
    CGFloat _currentFPS;
    NSUInteger _memoryUsage;
    CGFloat _cacheHitRate;
    CGFloat _cpuUsage;
    NSDate* _lastFPSUpdate;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _parser = std::make_unique<mdviewer::MarkdownParser>();
        // _renderEngine = std::make_unique<mdviewer::RenderEngine>();  // Commented out for now
        _fileWatcher = std::make_unique<mdviewer::FileWatcher>();
        
        // Initialize search arrays with retained instance
        _searchResults = [[NSMutableArray alloc] init];
        _currentSearchIndex = -1;
        
        // Initialize TOC items
        _tocItems = [NSMutableArray array];
        
        // Initialize navigation history
        _navigationHistory = [[NSMutableArray array] retain];
        _currentHistoryIndex = -1;
        _isNavigatingHistory = NO;
        
        // Initialize performance metrics
        _currentFPS = 120.0;
        _lastParseTime = 0;
        _lastRenderTime = 0;
        _currentFileSize = 0;
        
        // Initialize Command Palette
        _commandPalette = [[CommandPaletteController alloc] init];
        _commandPalette.delegate = self;
        _currentLineCount = 0;
        _memoryUsage = 0;
        _cacheHitRate = 0;
        _cpuUsage = 0;
        
        // Initialize recent files from user defaults
        NSArray* savedRecentFiles = [[NSUserDefaults standardUserDefaults] arrayForKey:@"RecentFiles"];
        if (savedRecentFiles) {
            _recentFiles = [[savedRecentFiles mutableCopy] retain];
        } else {
            _recentFiles = [[NSMutableArray array] retain];
        }
        
        // _device = MTLCreateSystemDefaultDevice();  // Commented out for now
        // _commandQueue = [_device newCommandQueue];  // Commented out for now
    }
    return self;
}

- (void)dealloc {
    [self stopFPSTracking];
    [_navigationHistory release];
    [_recentFiles release];
    if (_searchResults) {
        [_searchResults release];
        _searchResults = nil;
    }
    [_tocItems release];
    [super dealloc];
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)loadView {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    KeyHandlingView* view = [[KeyHandlingView alloc] initWithFrame:frame];
    view.controller = self;
    
    // Create search bar (hidden by default, at top)
    NSRect searchFrame = NSMakeRect(0, frame.size.height - 40, frame.size.width, 40);
    _searchBar = [[NSView alloc] initWithFrame:searchFrame];
    [_searchBar setWantsLayer:YES];
    _searchBar.layer.backgroundColor = [[NSColor controlBackgroundColor] CGColor];
    _searchBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [_searchBar setHidden:YES];
    
    // Search field
    _searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(10, 8, 250, 24)];
    [_searchField setPlaceholderString:@"Search"];
    [_searchField setDelegate:self];
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchFieldDidChange:)];
    [_searchBar addSubview:_searchField];
    
    // Previous button
    _previousButton = [[NSButton alloc] initWithFrame:NSMakeRect(270, 8, 30, 24)];
    [_previousButton setTitle:@"◀"];
    [_previousButton setBezelStyle:NSBezelStyleRounded];
    [_previousButton setTarget:self];
    [_previousButton setAction:@selector(findPrevious)];
    [_searchBar addSubview:_previousButton];
    
    // Next button  
    _nextButton = [[NSButton alloc] initWithFrame:NSMakeRect(305, 8, 30, 24)];
    [_nextButton setTitle:@"▶"];
    [_nextButton setBezelStyle:NSBezelStyleRounded];
    [_nextButton setTarget:self];
    [_nextButton setAction:@selector(findNext)];
    [_searchBar addSubview:_nextButton];
    
    // Results label
    _searchResultLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(345, 8, 150, 24)];
    [_searchResultLabel setEditable:NO];
    [_searchResultLabel setBordered:NO];
    [_searchResultLabel setBackgroundColor:[NSColor clearColor]];
    [_searchResultLabel setStringValue:@""];
    [_searchBar addSubview:_searchResultLabel];
    
    // Close button
    NSButton* closeButton = [[NSButton alloc] initWithFrame:NSMakeRect(frame.size.width - 35, 8, 25, 24)];
    [closeButton setTitle:@"✕"];
    [closeButton setBezelStyle:NSBezelStyleRounded];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(hideSearchBar)];
    closeButton.autoresizingMask = NSViewMinXMargin;
    [_searchBar addSubview:closeButton];
    
    [view addSubview:_searchBar];
    
    // Create status bar first (at bottom)
    NSRect statusFrame = NSMakeRect(0, 0, frame.size.width, 22);
    _statusLabel = [[NSTextField alloc] initWithFrame:statusFrame];
    [_statusLabel setEditable:NO];
    [_statusLabel setBordered:NO];
    [_statusLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [_statusLabel setFont:[NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular]];
    NSString* statusText = [NSString stringWithFormat:@"Ready | v%s Build %d", 
                            mdviewer::getVersionString(), 
                            mdviewer::getBuildNumber()];
    [_statusLabel setStringValue:statusText];
    
    // Reading time label removed - no floating badge in top right
    _statusLabel.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    [view addSubview:_statusLabel];
    
    // Create split view to hold TOC and content
    NSRect splitFrame = NSMakeRect(0, 22, frame.size.width, frame.size.height - 22);
    _splitView = [[NSSplitView alloc] initWithFrame:splitFrame];
    [_splitView setDividerStyle:NSSplitViewDividerStyleThin];
    [_splitView setVertical:YES];
    _splitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    // Create TOC outline view
    _tocScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 200, splitFrame.size.height)];
    [_tocScrollView setHasVerticalScroller:YES];
    [_tocScrollView setAutohidesScrollers:YES];
    
    _tocOutlineView = [[NSOutlineView alloc] initWithFrame:NSMakeRect(0, 0, 200, splitFrame.size.height)];
    [_tocOutlineView setHeaderView:nil];
    [_tocOutlineView setIndentationPerLevel:16];
    [_tocOutlineView setFloatsGroupRows:NO];
    
    NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    [column setWidth:180];
    [_tocOutlineView addTableColumn:column];
    [_tocOutlineView setOutlineTableColumn:column];
    
    [_tocOutlineView setDataSource:self];
    [_tocOutlineView setDelegate:self];
    [_tocOutlineView setTarget:self];
    [_tocOutlineView setDoubleAction:@selector(tocItemDoubleClicked:)];
    
    [_tocScrollView setDocumentView:_tocOutlineView];
    
    // Don't hide TOC with setHidden - control visibility with split position
    // [_tocScrollView setHidden:YES];  // Removed - causes issues with split view
    
    // Create main content scroll view  
    NSRect scrollFrame = NSMakeRect(0, 0, frame.size.width, splitFrame.size.height);
    _scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:YES];
    [_scrollView setAutohidesScrollers:YES];
    _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    // Add glass effect background
    NSVisualEffectView* contentBackground = [[NSVisualEffectView alloc] initWithFrame:scrollFrame];
    contentBackground.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    contentBackground.material = NSVisualEffectMaterialUnderWindowBackground;
    contentBackground.state = NSVisualEffectStateActive;
    [_scrollView addSubview:contentBackground positioned:NSWindowBelow relativeTo:nil];
    
    // Add views to split view
    [_splitView addSubview:_tocScrollView];
    [_splitView addSubview:_scrollView];
    
    // Set initial split position
    [_splitView setPosition:0 ofDividerAtIndex:0];
    
    [view addSubview:_splitView];
    
    // Create text view for displaying markdown content
    _textView = [[VimTextView alloc] initWithFrame:NSMakeRect(0, 0, scrollFrame.size.width, scrollFrame.size.height)];
    [(VimTextView*)_textView setMarkdownController:self];
    [_textView setEditable:NO];
    [_textView setSelectable:YES];
    
    // Initialize font size tracking
    _baseFontSize = 14.0;
    _currentFontSize = _baseFontSize;
    [_textView setFont:[NSFont systemFontOfSize:_currentFontSize]];
    
    [_textView setBackgroundColor:[NSColor textBackgroundColor]];
    [_textView setTextColor:[NSColor textColor]];
    [_textView setString:@"Ready - Use File → Open to load a markdown file"];
    [_textView setDelegate:self];
    
    // Enable automatic link detection
    [_textView setAutomaticLinkDetectionEnabled:YES];
    [_textView setDisplaysLinkToolTips:YES];
    
    // Set text container properties for better rendering
    [[_textView textContainer] setContainerSize:NSMakeSize(scrollFrame.size.width - 40, FLT_MAX)];
    [[_textView textContainer] setWidthTracksTextView:YES];
    [_textView setTextContainerInset:NSMakeSize(20, 20)];
    
    [_scrollView setDocumentView:_textView];
    
    // Setup command palette
    [self setupCommandPalette];
    
    self.view = view;
    
    // Create edge scroll indicators (after view is set)
    [self setupEdgeScrollIndicators];
    
    // Setup focus mode
    [self setupFocusMode];
    
    // Setup scroll monitoring for edge indicators
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollViewDidScroll:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:[_scrollView contentView]];
    
    // Reading time label removed - no longer added to view
    
    // Add edge indicators on top
    if (_topScrollIndicator && _bottomScrollIndicator) {
        [view addSubview:_topScrollIndicator positioned:NSWindowAbove relativeTo:nil];
        [view addSubview:_bottomScrollIndicator positioned:NSWindowAbove relativeTo:nil];
    }
    
    // Initial update of scroll indicators
    [self updateScrollIndicators];
    
    // Enable drag and drop on the view
    [view registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    
    // Make view first responder when window appears
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.window makeFirstResponder:self.view];
    });
    
    // Setup appearance monitoring
    [self updateAppearance];
    
    // Metal initialization commented out for now
    // _renderEngine->initialize((__bridge void*)_device, (__bridge void*)_metalView.layer);
    
    // Setup file watcher
    _fileWatcher->set_callback([self](const std::string& path) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadFile:[NSString stringWithUTF8String:path.c_str()]];
        });
    });
    
    // Initialize default status
    [self updateStatusBar];
}

- (void)applySyntaxHighlighting {
    // Increment frame count for FPS tracking
    [self incrementFrameCount];
    
    @autoreleasepool {
        @try {
            NSString* text = [_textView string];
            if (!text || [text length] == 0) {
                return;
            }
            
            NSUInteger textLength = [text length];
            NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:text];
            
            // Base font and color
            NSFont* baseFont = [NSFont fontWithName:@"SF Mono" size:13] ?: [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightRegular];
            if (!baseFont) {
                baseFont = [NSFont systemFontOfSize:13];
            }
            
            NSDictionary* baseAttributes = @{
                NSFontAttributeName: baseFont,
                NSForegroundColorAttributeName: [NSColor textColor]
            };
            [attributedString addAttributes:baseAttributes range:NSMakeRange(0, textLength)];
            
            // Define colors for different elements
            NSColor* headerColor = [NSColor systemBlueColor];
            NSColor* codeBackgroundColor = [NSColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
            
            // Dark mode adjustments
            if (@available(macOS 10.14, *)) {
                NSAppearance* appearance = [NSApp effectiveAppearance];
                if (appearance && ([appearance.name isEqualToString:NSAppearanceNameDarkAqua] ||
                    [appearance.name isEqualToString:NSAppearanceNameVibrantDark])) {
                    codeBackgroundColor = [NSColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
                }
            }
            
            // Helper function to validate range
            BOOL (^isValidRange)(NSRange) = ^BOOL(NSRange range) {
                return range.location != NSNotFound && 
                       range.location < textLength && 
                       NSMaxRange(range) <= textLength;
            };
            
            // 1. Headers - Simple string-based approach
            NSArray* lines = [text componentsSeparatedByString:@"\n"];
            NSUInteger currentPosition = 0;
            
            for (NSString* line in lines) {
                NSUInteger lineLength = [line length];
                NSRange lineRange = NSMakeRange(currentPosition, lineLength);
                
                // Validate line range
                if (!isValidRange(lineRange)) {
                    currentPosition += lineLength + 1; // +1 for newline
                    continue;
                }
                
                // Check if line starts with #
                if (lineLength > 0 && [line characterAtIndex:0] == '#') {
                    NSUInteger hashCount = 0;
                    NSUInteger i = 0;
                    
                    // Count hash symbols
                    while (i < lineLength && i < 6 && [line characterAtIndex:i] == '#') {
                        hashCount++;
                        i++;
                    }
                    
                    if (hashCount > 0 && i < lineLength && [line characterAtIndex:i] == ' ') {
                        // Hash symbols range
                        NSRange hashRange = NSMakeRange(currentPosition, hashCount);
                        if (isValidRange(hashRange)) {
                            [attributedString addAttribute:NSForegroundColorAttributeName 
                                                     value:headerColor 
                                                     range:hashRange];
                        }
                        
                        // Header text range (skip space after hashes)
                        NSRange textRange = NSMakeRange(currentPosition + hashCount + 1, 
                                                       lineLength - hashCount - 1);
                        if (isValidRange(textRange)) {
                            CGFloat fontSize = 13 + (6 - hashCount);
                            NSFont* headerFont = [NSFont fontWithName:@"SF Mono" size:fontSize] ?: 
                                               [NSFont systemFontOfSize:fontSize weight:NSFontWeightBold];
                            if (headerFont) {
                                [attributedString addAttribute:NSFontAttributeName 
                                                         value:headerFont 
                                                         range:textRange];
                                [attributedString addAttribute:NSForegroundColorAttributeName 
                                                         value:headerColor 
                                                         range:textRange];
                            }
                        }
                    }
                }
                
                currentPosition += lineLength + 1; // +1 for newline
            }
            
            // 2. Bold text (**text**) - Simple string search
            NSString* searchText = text;
            NSUInteger searchStart = 0;
            
            while (searchStart < textLength) {
                NSRange boldStart = [searchText rangeOfString:@"**" 
                                                      options:0 
                                                        range:NSMakeRange(searchStart, textLength - searchStart)];
                if (boldStart.location == NSNotFound) break;
                
                // Find closing **
                NSUInteger closeSearchStart = boldStart.location + 2;
                if (closeSearchStart >= textLength) break;
                
                NSRange boldEnd = [searchText rangeOfString:@"**" 
                                                    options:0 
                                                      range:NSMakeRange(closeSearchStart, textLength - closeSearchStart)];
                if (boldEnd.location == NSNotFound) break;
                
                // Content between ** markers
                NSRange contentRange = NSMakeRange(boldStart.location + 2, 
                                                  boldEnd.location - boldStart.location - 2);
                
                if (isValidRange(contentRange) && contentRange.length > 0) {
                    NSFont* boldFont = [NSFont fontWithName:@"SF Mono" size:13] ?: [NSFont systemFontOfSize:13];
                    if (boldFont) {
                        boldFont = [[NSFontManager sharedFontManager] convertFont:boldFont 
                                                                      toHaveTrait:NSBoldFontMask];
                        if (boldFont) {
                            [attributedString addAttribute:NSFontAttributeName 
                                                     value:boldFont 
                                                     range:contentRange];
                        }
                    }
                }
                
                searchStart = boldEnd.location + 2;
            }
            
            // 3. Inline code (`code`) - Simple string search
            searchStart = 0;
            
            while (searchStart < textLength) {
                NSRange codeStart = [searchText rangeOfString:@"`" 
                                                      options:0 
                                                        range:NSMakeRange(searchStart, textLength - searchStart)];
                if (codeStart.location == NSNotFound) break;
                
                // Find closing `
                NSUInteger closeSearchStart = codeStart.location + 1;
                if (closeSearchStart >= textLength) break;
                
                NSRange codeEnd = [searchText rangeOfString:@"`" 
                                                    options:0 
                                                      range:NSMakeRange(closeSearchStart, textLength - closeSearchStart)];
                if (codeEnd.location == NSNotFound) break;
                
                // Content between ` markers
                NSRange contentRange = NSMakeRange(codeStart.location + 1, 
                                                  codeEnd.location - codeStart.location - 1);
                
                if (isValidRange(contentRange) && contentRange.length > 0) {
                    NSFont* monoFont = [NSFont fontWithName:@"SF Mono" size:12] ?: 
                                     [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
                    if (monoFont) {
                        [attributedString addAttribute:NSFontAttributeName 
                                                 value:monoFont 
                                                 range:contentRange];
                        [attributedString addAttribute:NSBackgroundColorAttributeName 
                                                 value:codeBackgroundColor 
                                                 range:contentRange];
                    }
                }
                
                searchStart = codeEnd.location + 1;
            }
            
            // Apply the highlighted text safely
            if (attributedString) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @try {
                        [[_textView textStorage] setAttributedString:attributedString];
                    } @catch (NSException* e) {
                        NSLog(@"Error applying attributed string: %@", e.description);
                    }
                });
            }
            
        } @catch (NSException* exception) {
            NSLog(@"Error in applySyntaxHighlighting: %@", exception.description);
            // Fall back to plain text if highlighting fails
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString* text = [_textView string];
                if (text) {
                    NSFont* baseFont = [NSFont fontWithName:@"SF Mono" size:13] ?: [NSFont systemFontOfSize:13];
                    NSDictionary* baseAttributes = @{
                        NSFontAttributeName: baseFont,
                        NSForegroundColorAttributeName: [NSColor textColor]
                    };
                    NSAttributedString* plainText = [[NSAttributedString alloc] initWithString:text attributes:baseAttributes];
                    [[_textView textStorage] setAttributedString:plainText];
                }
            });
        }
    }
}

- (void)openFile:(NSString*)path {
    
    // Store file info
    _currentFilePath = path;
    
    // Add to navigation history if not navigating through history
    if (!_isNavigatingHistory) {
        // Remove any forward history when opening a new file
        if (_currentHistoryIndex < [_navigationHistory count] - 1) {
            NSRange rangeToRemove = NSMakeRange(_currentHistoryIndex + 1, 
                                               [_navigationHistory count] - _currentHistoryIndex - 1);
            [_navigationHistory removeObjectsInRange:rangeToRemove];
        }
        
        // Add the new path to history
        [_navigationHistory addObject:path];
        _currentHistoryIndex = [_navigationHistory count] - 1;
        
        // Limit history to 50 items
        if ([_navigationHistory count] > 50) {
            [_navigationHistory removeObjectAtIndex:0];
            _currentHistoryIndex--;
        }
    }
    
    // Add to recent files
    [self addToRecentFiles:path];
    
    NSError* error = nil;
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    
    if (error) {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error opening file"];
        [alert setInformativeText:error.localizedDescription];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    // Make sure content is not nil
    if (!content) {
        content = @"";
    }
    
    // Get file stats
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    _currentFileSize = [fileAttributes[NSFileSize] unsignedIntegerValue];
    _currentLineCount = [[content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
    
    // Try to parse markdown with error handling
    NSDate* parseStart = [NSDate date];
    @try {
        const char* markdownCStr = [content UTF8String];
        if (markdownCStr && strlen(markdownCStr) > 0) {
            std::string markdown(markdownCStr);
            _currentDocument = _parser->parse(markdown);
        } else {
            // Create empty document for empty files
            _currentDocument = std::make_unique<mdviewer::Document>();
        }
    } @catch (NSException* exception) {
        NSLog(@"Error parsing markdown: %@", exception.description);
        // Fall back to empty document
        _currentDocument = std::make_unique<mdviewer::Document>();
    } @catch (...) {
        NSLog(@"Unknown error parsing markdown");
        // Fall back to empty document
        _currentDocument = std::make_unique<mdviewer::Document>();
    }
    _lastParseTime = -[parseStart timeIntervalSinceNow] * 1000; // Convert to milliseconds
    
    // If document is still null, create an empty one
    if (!_currentDocument) {
        _currentDocument = std::make_unique<mdviewer::Document>();
    }
    
    // Check if dark mode is enabled
    BOOL isDarkMode = NO;
    if (@available(macOS 10.14, *)) {
        NSAppearance* appearance = [NSApp effectiveAppearance];
        isDarkMode = appearance && ([appearance.name isEqualToString:NSAppearanceNameDarkAqua] ||
                                   [appearance.name isEqualToString:NSAppearanceNameVibrantDark]);
    }
    
    // Render the markdown document
    NSDate* renderStart = [NSDate date];
    NSAttributedString* renderedContent = nil;
    if (_currentDocument && _currentDocument->get_root()) {
        renderedContent = mdviewer::renderMarkdownDocument(_currentDocument.get(), isDarkMode);
    }
    
    if (renderedContent && [renderedContent length] > 0) {
        [[_textView textStorage] setAttributedString:renderedContent];
    } else {
        // Fallback to raw content with syntax highlighting if rendering fails
        [_textView setString:content];
        [self applySyntaxHighlighting];
    }
    _lastRenderTime = -[renderStart timeIntervalSinceNow] * 1000; // Convert to milliseconds
    
    // Build Table of Contents from the parsed document
    [self buildTOCFromDocument];
    
    // Update comprehensive status bar
    [self updateStatusBar];
    
    // Start watching file
    _fileWatcher->watch([path UTF8String]);
    _fileWatcher->start();
    
    // Make text view first responder to enable vim navigation immediately
    [[self.view window] makeFirstResponder:_textView];
    
    // Metal rendering commented out for now
    // [_metalView setNeedsDisplay:YES];
}

- (void)reloadFile:(NSString*)path {
    [self openFile:path];
    
    // Update status bar after reload
    [self updateStatusBar];
    
    // Diff highlighting commented out for now
    // mdviewer::DiffHighlighter::highlight_changes({}, std::chrono::milliseconds(500));
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    // Start FPS tracking
    [self startFPSTracking];
    
    // Check if we have a file to open from command line
    NSString* fileToOpen = [[NSUserDefaults standardUserDefaults] stringForKey:@"FileToOpenAtLaunch"];
    if (fileToOpen) {
        // Clear the flag
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FileToOpenAtLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Open the file after a short delay to ensure window is ready
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Opening command-line file: %@", fileToOpen);
            [self openFile:fileToOpen];
        });
    }
    
    // Update recent files menu on startup - delay to ensure menu is ready
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateRecentFilesMenu];
    });
    
    // Register for appearance change notifications
    if (@available(macOS 10.14, *)) {
        [NSDistributedNotificationCenter.defaultCenter addObserver:self 
            selector:@selector(appearanceDidChange:) 
            name:@"AppleInterfaceThemeChangedNotification" 
            object:nil];
    }
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    
    // Stop FPS tracking
    [self stopFPSTracking];
    
    // Unregister from notifications
    [NSDistributedNotificationCenter.defaultCenter removeObserver:self];
}

- (void)appearanceDidChange:(NSNotification*)notification {
    [self updateAppearance];
    
    // Re-render current document if we have one
    if (_currentDocument && _currentDocument->get_root()) {
        NSString* currentPath = [_statusLabel stringValue];
        NSRange range = [currentPath rangeOfString:@" - "];
        if (range.location != NSNotFound) {
            NSString* path = [currentPath substringToIndex:range.location];
            [self openFile:path];
        }
    }
}

- (void)updateAppearance {
    BOOL isDarkMode = NO;
    if (@available(macOS 10.14, *)) {
        NSAppearance* appearance = [NSApp effectiveAppearance];
        isDarkMode = appearance && ([appearance.name isEqualToString:NSAppearanceNameDarkAqua] ||
                                   [appearance.name isEqualToString:NSAppearanceNameVibrantDark]);
    }
    
    // Update background colors
    if (isDarkMode) {
        [_textView setBackgroundColor:[NSColor colorWithWhite:0.1 alpha:1.0]];
        [_scrollView setBackgroundColor:[NSColor colorWithWhite:0.1 alpha:1.0]];
    } else {
        [_textView setBackgroundColor:[NSColor textBackgroundColor]];
        [_scrollView setBackgroundColor:[NSColor controlBackgroundColor]];
    }
}

- (void)keyDown:(NSEvent*)event {
    NSString* key = event.charactersIgnoringModifiers;
    NSUInteger modifierFlags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    
    // Check for Cmd+K
    if ([key isEqualToString:@"k"] && (modifierFlags & NSEventModifierFlagCommand)) {
        // Show command palette (Cmd+K)
        [self showCommandPalette];
        return;
    } else if ([key isEqualToString:@"."] && (modifierFlags & NSEventModifierFlagCommand)) {
        // Toggle focus mode (Cmd+.)
        [self toggleFocusMode];
        return;
    } else if ([key isEqualToString:@"f"] && (modifierFlags & NSEventModifierFlagCommand)) {
        // Show search bar
        [self showSearchBar];
        return;
    } else if ([key isEqualToString:@"g"] && (modifierFlags & NSEventModifierFlagCommand)) {
        // Find next (Cmd+G)
        if (![_searchBar isHidden]) {
            if (modifierFlags & NSEventModifierFlagShift) {
                [self findPrevious];  // Cmd+Shift+G for find previous
            } else {
                [self findNext];
            }
        }
        return;
    } else if (event.keyCode == 53) { // ESC key
        // Hide search bar
        if (![_searchBar isHidden]) {
            [self hideSearchBar];
        }
        return;
    }
    
    // Vim-style navigation (no modifiers)
    if (modifierFlags == 0) {
        NSLog(@"Vim key pressed: %@", key);
        if ([key isEqualToString:@"j"]) {
            // Scroll down
            NSLog(@"Scrolling down with j");
            NSScrollView* scrollView = [_textView enclosingScrollView];
            NSPoint currentPoint = scrollView.documentVisibleRect.origin;
            currentPoint.y += 40; // Scroll by 40 points
            [[scrollView documentView] scrollPoint:currentPoint];
            [self updateScrollIndicators];
            return;
        } else if ([key isEqualToString:@"k"]) {
            // Scroll up
            NSScrollView* scrollView = [_textView enclosingScrollView];
            NSPoint currentPoint = scrollView.documentVisibleRect.origin;
            currentPoint.y -= 40; // Scroll by 40 points
            if (currentPoint.y < 0) currentPoint.y = 0;
            [[scrollView documentView] scrollPoint:currentPoint];
            [self updateScrollIndicators];
            return;
        } else if ([key isEqualToString:@"h"]) {
            // Scroll left (if needed)
            NSScrollView* scrollView = [_textView enclosingScrollView];
            NSPoint currentPoint = scrollView.documentVisibleRect.origin;
            currentPoint.x -= 40;
            if (currentPoint.x < 0) currentPoint.x = 0;
            [[scrollView documentView] scrollPoint:currentPoint];
            [self updateScrollIndicators];
            return;
        } else if ([key isEqualToString:@"l"]) {
            // Scroll right (if needed)
            NSScrollView* scrollView = [_textView enclosingScrollView];
            NSPoint currentPoint = scrollView.documentVisibleRect.origin;
            currentPoint.x += 40;
            [[scrollView documentView] scrollPoint:currentPoint];
            [self updateScrollIndicators];
            return;
        } else if ([key isEqualToString:@"g"]) {
            // gg - go to top (would need to track double-g)
            static NSTimeInterval lastGPress = 0;
            NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
            if (now - lastGPress < 0.5) { // Double-g within 500ms
                // Go to top
                NSScrollView* scrollView = [_textView enclosingScrollView];
                [[scrollView documentView] scrollPoint:NSMakePoint(0, 0)];
                lastGPress = 0;
            } else {
                lastGPress = now;
            }
            return;
        }
    }
    
    // Shift+G - go to bottom
    if ([key isEqualToString:@"G"] && (modifierFlags & NSEventModifierFlagShift)) {
        NSScrollView* scrollView = [_textView enclosingScrollView];
        NSView* documentView = [scrollView documentView];
        CGFloat maxY = documentView.frame.size.height - scrollView.documentVisibleRect.size.height;
        [[scrollView documentView] scrollPoint:NSMakePoint(0, maxY)];
        return;
    }
    
    [super keyDown:event];
}

// MARK: - Search Implementation

- (void)controlTextDidEndEditing:(NSNotification*)notification {
    // Handle search field losing focus - don't crash
    if ([notification object] == _searchField) {
        // Just ensure arrays are valid, don't clear highlights yet
        if (!_searchResults) {
            _searchResults = [NSMutableArray array];
        }
    }
}

- (void)showSearchBar {
    // Animate search bar slide down
    _searchBar.alphaValue = 0;
    _searchBar.hidden = NO;
    
    CABasicAnimation* slideDown = [CABasicAnimation animationWithKeyPath:@"position.y"];
    slideDown.fromValue = @(_searchBar.frame.origin.y - 20);
    slideDown.toValue = @(_searchBar.frame.origin.y);
    slideDown.duration = 0.25;
    slideDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    CABasicAnimation* fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = @0;
    fadeIn.toValue = @1;
    fadeIn.duration = 0.25;
    
    [_searchBar.layer addAnimation:slideDown forKey:@"slideDown"];
    [_searchBar.layer addAnimation:fadeIn forKey:@"fadeIn"];
    _searchBar.alphaValue = 1;
    
    // Adjust scroll view frame to make room for search bar
    NSRect scrollFrame = _scrollView.frame;
    scrollFrame.size.height = self.view.frame.size.height - 22 - 40; // status bar + search bar
    [_scrollView setFrame:scrollFrame];
    
    // Focus on search field
    [_searchField becomeFirstResponder];
    
    // Initialize search with retained instance
    if (_searchResults) {
        [_searchResults removeAllObjects];
    } else {
        _searchResults = [[NSMutableArray alloc] init];
    }
    _currentSearchIndex = -1;
}

- (void)hideSearchBar {
    // Animate search bar disappearance
    CABasicAnimation* slideUp = [CABasicAnimation animationWithKeyPath:@"position.y"];
    slideUp.fromValue = @(_searchBar.frame.origin.y);
    slideUp.toValue = @(_searchBar.frame.origin.y - 20);
    slideUp.duration = 0.2;
    slideUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    CABasicAnimation* fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOut.fromValue = @1;
    fadeOut.toValue = @0;
    fadeOut.duration = 0.2;
    fadeOut.fillMode = kCAFillModeForwards;
    fadeOut.removedOnCompletion = NO;
    
    [_searchBar.layer addAnimation:slideUp forKey:@"slideUp"];
    [_searchBar.layer addAnimation:fadeOut forKey:@"fadeOut"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_searchBar setHidden:YES];
    });
    
    // Restore scroll view frame
    NSRect scrollFrame = _scrollView.frame;
    scrollFrame.size.height = self.view.frame.size.height - 22; // just status bar
    [_scrollView setFrame:scrollFrame];
    
    // Clear highlights before clearing the array
    [self clearSearchHighlights];
    
    // Clear search state - reset to empty array instead of nil for safety
    _searchResults = [NSMutableArray array];
    _currentSearchIndex = -1;
    [_searchResultLabel setStringValue:@""];
}

- (void)searchFieldDidChange:(id)sender {
    @try {
        NSString* searchTerm = [_searchField stringValue];
        if ([searchTerm length] > 0) {
            [self performSearch:searchTerm];
        } else {
            [self clearSearchHighlights];
            if (!_searchResults) {
                _searchResults = [[NSMutableArray alloc] init];
            } else {
                [_searchResults removeAllObjects];
            }
            _currentSearchIndex = -1;
            if (_searchResultLabel) {
                [_searchResultLabel setStringValue:@""];
            }
        }
    } @catch (NSException* exception) {
        NSLog(@"Error in searchFieldDidChange: %@", exception);
    }
}

- (void)performSearch:(NSString*)searchTerm {
    [self clearSearchHighlights];
    
    // Increment frame count for FPS tracking
    [self incrementFrameCount];
    
    if (!_searchResults) {
        _searchResults = [[NSMutableArray alloc] init];
    } else {
        [_searchResults removeAllObjects];
    }
    _currentSearchIndex = -1;
    
    if ([searchTerm length] == 0 || !_textView) {
        [_searchResultLabel setStringValue:@""];
        return;
    }
    
    NSString* content = [[_textView textStorage] string];
    if (!content || [content length] == 0) {
        [_searchResultLabel setStringValue:@""];
        return;
    }
    
    NSStringCompareOptions options = NSCaseInsensitiveSearch;
    
    NSRange searchRange = NSMakeRange(0, [content length]);
    NSRange foundRange;
    
    // Find all occurrences
    while (searchRange.location < [content length]) {
        foundRange = [content rangeOfString:searchTerm 
                                    options:options 
                                      range:searchRange];
        
        if (foundRange.location != NSNotFound) {
            [_searchResults addObject:[NSValue valueWithRange:foundRange]];
            searchRange.location = foundRange.location + foundRange.length;
            searchRange.length = [content length] - searchRange.location;
        } else {
            break;
        }
    }
    
    // Highlight all results
    for (NSValue* rangeValue in _searchResults) {
        NSRange range = [rangeValue rangeValue];
        if (range.location != NSNotFound && NSMaxRange(range) <= [content length]) {
            [[_textView textStorage] addAttribute:NSBackgroundColorAttributeName 
                                            value:[NSColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.3]
                                            range:range];
        }
    }
    
    // Update results label
    if ([_searchResults count] > 0) {
        _currentSearchIndex = 0;
        [self highlightCurrentSearchResult];
        [self updateSearchResultLabel];
        
        // Scroll to first result
        NSRange firstRange = [[_searchResults objectAtIndex:0] rangeValue];
        [_textView scrollRangeToVisible:firstRange];
        
        // Update status bar to reflect search activity
        [self updateStatusBar];
    } else {
        [_searchResultLabel setStringValue:@"No results"];
    }
}

- (void)findNext {
    if ([_searchResults count] == 0) return;
    
    _currentSearchIndex++;
    if (_currentSearchIndex >= [_searchResults count]) {
        _currentSearchIndex = 0; // Wrap around
    }
    
    [self highlightCurrentSearchResult];
    [self updateSearchResultLabel];
    
    NSRange range = [[_searchResults objectAtIndex:_currentSearchIndex] rangeValue];
    [_textView scrollRangeToVisible:range];
}

- (void)findPrevious {
    if ([_searchResults count] == 0) return;
    
    _currentSearchIndex--;
    if (_currentSearchIndex < 0) {
        _currentSearchIndex = [_searchResults count] - 1; // Wrap around
    }
    
    [self highlightCurrentSearchResult];
    [self updateSearchResultLabel];
    
    NSRange range = [[_searchResults objectAtIndex:_currentSearchIndex] rangeValue];
    [_textView scrollRangeToVisible:range];
}

- (void)clearSearchHighlights {
    // Don't remove all background attributes as it will remove code block backgrounds
    // Instead, only remove search highlight colors
    
    // Ensure _searchResults is always a valid array
    if (!_searchResults || ![_searchResults isKindOfClass:[NSArray class]]) {
        _searchResults = [NSMutableArray array];
        return;
    }
    
    // Early return if no results to clear
    if ([_searchResults count] == 0) return;
    
    // Check textView is valid
    if (!_textView || !_textView.textStorage) return;
    
    NSTextStorage* textStorage = [_textView textStorage];
    NSString* textString = [textStorage string];
    if (!textString || [textString length] == 0) return;
    
    NSUInteger textLength = [textString length];
    
    // Create a copy to avoid mutation during iteration
    NSArray* resultsCopy = [_searchResults copy];
    
    // Safely iterate through results
    for (id obj in resultsCopy) {
        // Skip non-NSValue objects
        if (![obj isKindOfClass:[NSValue class]]) continue;
        
        NSValue* value = (NSValue*)obj;
        NSRange range = [value rangeValue];
        
        // Validate range
        if (range.location == NSNotFound) continue;
        if (range.location >= textLength) continue;
        if (NSMaxRange(range) > textLength) continue;
        
        // Remove highlight
        [textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
    }
}

- (void)highlightCurrentSearchResult {
    @try {
        if (!_searchResults || !_textView) return;
        
        NSUInteger count = [_searchResults count];
        if (count == 0) return;
        
        NSTextStorage* textStorage = [_textView textStorage];
        if (!textStorage) return;
        
        NSUInteger textLength = [[textStorage string] length];
        
        // First, re-highlight all results with yellow
        for (NSInteger i = 0; i < count; i++) {
            @try {
                id obj = [_searchResults objectAtIndex:i];
                if (!obj || ![obj respondsToSelector:@selector(rangeValue)]) continue;
                
                NSRange range = [(NSValue*)obj rangeValue];
                
                if (range.location != NSNotFound && 
                    range.location < textLength && 
                    NSMaxRange(range) <= textLength) {
                    
                    NSColor* color = (i == _currentSearchIndex) ?
                        [NSColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.5] :  // Orange for current
                        [NSColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.3];   // Yellow for others
                    
                    [textStorage addAttribute:NSBackgroundColorAttributeName 
                                        value:color
                                        range:range];
                }
            } @catch (NSException* e) {
                continue;
            }
        }
    } @catch (NSException* exception) {
        NSLog(@"Error highlighting search result: %@", exception);
    }
}

- (void)updateSearchResultLabel {
    if ([_searchResults count] > 0) {
        NSString* text = [NSString stringWithFormat:@"%ld of %ld", 
                         _currentSearchIndex + 1, [_searchResults count]];
        [_searchResultLabel setStringValue:text];
    } else {
        [_searchResultLabel setStringValue:@""];
    }
}

// MARK: - Command Palette

- (void)showCommandPalette {
    NSLog(@"MarkdownViewController: showCommandPalette called");
    
    @try {
        // Check if command palette is initialized
        if (!_commandPalette) {
            NSLog(@"Command palette is nil, initializing...");
            _commandPalette = [[CommandPaletteController alloc] init];
            if (!_commandPalette) {
                NSLog(@"ERROR: Failed to create CommandPaletteController!");
                return;
            }
            _commandPalette.delegate = self;
            NSLog(@"Command palette created successfully");
            
            // Try to setup command palette
            @try {
                [self setupCommandPalette];
                NSLog(@"Command palette setup completed");
            } @catch (NSException *exception) {
                NSLog(@"ERROR setting up command palette: %@", exception);
                return;
            }
        }
        
        // Update recent documents
        if (_recentFiles) {
            NSLog(@"Updating recent documents: %lu items", (unsigned long)_recentFiles.count);
            [_commandPalette updateRecentDocuments:_recentFiles];
        }
        
        // Update headings from current document
        NSMutableArray* headings = [NSMutableArray array];
        if (_tocItems) {
            for (TOCItem* item in _tocItems) {
                [self addHeadingsFromItem:item toArray:headings];
            }
            NSLog(@"Updating headings: %lu items", (unsigned long)headings.count);
            [_commandPalette updateHeadings:headings];
        }
        
        // Show the palette
        NSLog(@"Attempting to show command palette...");
        [_commandPalette show];
        NSLog(@"Command palette show method completed");
        
    } @catch (NSException *exception) {
        NSLog(@"EXCEPTION in showCommandPalette: %@", exception);
        NSLog(@"Stack trace: %@", [exception callStackSymbols]);
    }
}

- (void)showCommandPalette:(id)sender {
    NSLog(@"showCommandPalette: called from menu");
    [self showCommandPalette];
}

- (void)addHeadingsFromItem:(TOCItem*)item toArray:(NSMutableArray*)headings {
    NSDictionary* heading = @{
        @"title": item.title,
        @"level": @(item.level),
        @"range": [NSValue valueWithRange:item.range]
    };
    [headings addObject:heading];
    
    for (TOCItem* child in item.children) {
        [self addHeadingsFromItem:child toArray:headings];
    }
}

- (void)setupCommandPalette {
    NSLog(@"Setting up command palette notifications...");
    
    @try {
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        
        // Only register observers that have implemented methods
        if ([self respondsToSelector:@selector(exportAsPDF:)]) {
            [nc addObserver:self selector:@selector(exportAsPDF:) name:@"ExportPDF" object:nil];
        }
        
        if ([self respondsToSelector:@selector(toggleTOCSidebar)]) {
            [nc addObserver:self selector:@selector(toggleTOCSidebar) name:@"ToggleTOC" object:nil];
        }
        
        if ([self respondsToSelector:@selector(showSearchBar)]) {
            [nc addObserver:self selector:@selector(showSearchBar) name:@"ShowSearch" object:nil];
        }
        
        NSLog(@"Command palette notifications setup completed");
    } @catch (NSException *exception) {
        NSLog(@"ERROR in setupCommandPalette: %@", exception);
    }
}

// Removed unimplemented notification methods that were causing crashes

#pragma mark - CommandPaletteDelegate

- (void)commandPaletteWillShow:(CommandPaletteController*)controller {
    // Optional: Pause any animations or updates
}

- (void)commandPaletteDidHide:(CommandPaletteController*)controller {
    // Optional: Resume any animations or updates
}

- (void)commandPalette:(CommandPaletteController*)controller didSelectCommand:(NSDictionary*)command {
    // Optional: Track command usage for frecency sorting
}

// MARK: - NSTextView Delegate

- (BOOL)textView:(NSTextView*)textView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex {
    if ([link isKindOfClass:[NSURL class]]) {
        [[NSWorkspace sharedWorkspace] openURL:(NSURL*)link];
        return YES; // We handled the link
    }
    return NO;
}


- (NSMenu*)textView:(NSTextView*)view menu:(NSMenu*)menu forEvent:(NSEvent*)event atIndex:(NSUInteger)charIndex {
    // Check if we're in a code block or mermaid diagram
    NSAttributedString* attrString = [view attributedString];
    if (charIndex < [attrString length]) {
        NSDictionary* attrs = [attrString attributesAtIndex:charIndex effectiveRange:NULL];
        
        // Check if this is a Mermaid diagram
        if (attrs[@"IsMermaid"] && [attrs[@"IsMermaid"] boolValue]) {
            NSString* mermaidCode = attrs[@"MermaidDiagram"];
            if (mermaidCode) {
                if (!menu) {
                    menu = [[NSMenu alloc] init];
                }
                
                NSMenuItem* viewMermaidItem = [[NSMenuItem alloc] initWithTitle:@"View Mermaid Diagram" 
                                                                        action:@selector(viewMermaidDiagram:) 
                                                                 keyEquivalent:@""];
                [viewMermaidItem setTarget:self];
                [viewMermaidItem setRepresentedObject:mermaidCode];
                [menu insertItem:viewMermaidItem atIndex:0];
                [menu insertItem:[NSMenuItem separatorItem] atIndex:1];
                
                NSMenuItem* copyMermaidItem = [[NSMenuItem alloc] initWithTitle:@"Copy Mermaid Code" 
                                                                        action:@selector(copyMermaidCode:) 
                                                                 keyEquivalent:@""];
                [copyMermaidItem setTarget:self];
                [copyMermaidItem setRepresentedObject:mermaidCode];
                [menu insertItem:copyMermaidItem atIndex:2];
                
                return menu;
            }
        }
        
        NSColor* bgColor = attrs[NSBackgroundColorAttributeName];
        
        // Check if this has a code block background color
        if (bgColor) {
            CGFloat white = 0;
            [bgColor getWhite:&white alpha:NULL];
            
            // Code blocks have specific background colors
            BOOL isDarkMode = white < 0.5;
            BOOL isCodeBlock = (isDarkMode && white < 0.2) || (!isDarkMode && white > 0.9);
            
            if (isCodeBlock) {
                // Find the full code block text
                NSRange codeRange = NSMakeRange(charIndex, 1);
                NSRange effectiveRange;
                [attrString attributesAtIndex:charIndex effectiveRange:&effectiveRange];
                
                // Add custom menu item for copying code
                if (!menu) {
                    menu = [[NSMenu alloc] init];
                }
                
                NSMenuItem* copyCodeItem = [[NSMenuItem alloc] initWithTitle:@"Copy Code" 
                                                                      action:@selector(copyCode:) 
                                                               keyEquivalent:@""];
                [copyCodeItem setTarget:self];
                [copyCodeItem setRepresentedObject:@{@"range": [NSValue valueWithRange:effectiveRange]}];
                
                if ([menu numberOfItems] > 0) {
                    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
                }
                [menu insertItem:copyCodeItem atIndex:0];
            }
        }
    }
    
    return menu;
}

- (void)copyCode:(NSMenuItem*)sender {
    NSDictionary* info = [sender representedObject];
    NSValue* rangeValue = info[@"range"];
    if (rangeValue) {
        NSRange range = [rangeValue rangeValue];
        NSString* codeText = [[[_textView textStorage] string] substringWithRange:range];
        
        // Clean up the code text - remove language indicators if present
        NSArray* lines = [codeText componentsSeparatedByString:@"\n"];
        NSMutableArray* cleanLines = [NSMutableArray array];
        
        for (NSString* line in lines) {
            // Skip language indicator lines (e.g., "// swift")
            if (![line hasPrefix:@"// "]) {
                [cleanLines addObject:line];
            }
        }
        
        NSString* cleanCode = [cleanLines componentsJoinedByString:@"\n"];
        
        // Copy to clipboard
        NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:cleanCode forType:NSPasteboardTypeString];
        
        // Optional: Show a brief notification or visual feedback
        NSLog(@"Code copied to clipboard");
    }
}

- (void)viewMermaidDiagramWithCode:(NSString*)mermaidCode {
    if (!mermaidCode) return;
    
    // Create a window to show the Mermaid diagram
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    NSWindow* mermaidWindow = [[NSWindow alloc] initWithContentRect:frame
                                                          styleMask:NSWindowStyleMaskTitled | 
                                                                   NSWindowStyleMaskClosable | 
                                                                   NSWindowStyleMaskResizable
                                                            backing:NSBackingStoreBuffered
                                                              defer:NO];
    [mermaidWindow setTitle:@"Mermaid Diagram"];
    [mermaidWindow center];
    
    // Create WebView to render Mermaid
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
    WKWebView* webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
    
    // Check if dark mode is enabled
    BOOL isDarkMode = NO;
    if (@available(macOS 10.14, *)) {
        NSAppearance* appearance = [NSApp effectiveAppearance];
        isDarkMode = appearance && ([appearance.name isEqualToString:NSAppearanceNameDarkAqua] ||
                                   [appearance.name isEqualToString:NSAppearanceNameVibrantDark]);
    }
    
    NSString* theme = isDarkMode ? @"dark" : @"default";
    NSString* bgColor = isDarkMode ? @"#1e1e1e" : @"white";
    
    // Create HTML with Mermaid.js
    NSString* html = [NSString stringWithFormat:@
        "<!DOCTYPE html>"
        "<html>"
        "<head>"
        "  <script src='https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js'></script>"
        "  <style>"
        "    body { margin: 20px; background: %@; display: flex; justify-content: center; align-items: center; min-height: 100vh; }"
        "    .mermaid { text-align: center; }"
        "  </style>"
        "</head>"
        "<body>"
        "  <div class='mermaid'>%@</div>"
        "  <script>"
        "    mermaid.initialize({ startOnLoad: true, theme: '%@' });"
        "  </script>"
        "</body>"
        "</html>", bgColor, mermaidCode, theme];
    
    [webView loadHTMLString:html baseURL:nil];
    [mermaidWindow setContentView:webView];
    [mermaidWindow makeKeyAndOrderFront:nil];
}

- (void)viewMermaidDiagram:(NSMenuItem*)sender {
    NSString* mermaidCode = [sender representedObject];
    [self viewMermaidDiagramWithCode:mermaidCode];
}

- (void)copyMermaidCode:(NSMenuItem*)sender {
    NSString* mermaidCode = [sender representedObject];
    if (mermaidCode) {
        NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:mermaidCode forType:NSPasteboardTypeString];
        NSLog(@"Mermaid code copied to clipboard");
    }
}

// MARK: - TOC Implementation

- (void)buildTOCFromDocument {
    if (!_currentDocument || !_currentDocument->get_root()) {
        _tocItems = [NSMutableArray array];
        [_tocOutlineView reloadData];
        return;
    }
    
    _tocItems = [NSMutableArray array];
    
    // Traverse the document and find all headings
    std::function<void(const mdviewer::Document::Node*, NSMutableArray*)> findHeadings = 
        [&findHeadings](const mdviewer::Document::Node* node, NSMutableArray* items) {
            if (node->type == mdviewer::Document::NodeType::Heading) {
                TOCItem* item = [[TOCItem alloc] init];
                item.level = node->heading_level;
                
                // Build title from text children
                NSMutableString* title = [NSMutableString string];
                for (const auto& child : node->children) {
                    if (child->type == mdviewer::Document::NodeType::Text) {
                        [title appendString:[NSString stringWithUTF8String:child->content.c_str()]];
                    }
                }
                
                item.title = title;
                
                // For now, just add all items at the top level
                // We can implement hierarchy later
                [items addObject:item];
            }
            
            // Recursively process children
            for (const auto& child : node->children) {
                findHeadings(child.get(), items);
            }
        };
    
    const mdviewer::Document::Node* root = _currentDocument->get_root();
    findHeadings(root, _tocItems);
    
    [_tocOutlineView reloadData];
    [_tocOutlineView expandItem:nil expandChildren:YES];
}

- (void)toggleTOCSidebar {
    // Check if TOC is visible by checking the frame width
    NSRect tocFrame = [_tocScrollView frame];
    
    if (tocFrame.size.width < 10) {  // TOC is hidden
        // Show TOC
        [_splitView setPosition:200 ofDividerAtIndex:0];
        
        // Build/refresh TOC
        [self buildTOCFromDocument];
    } else {
        // Hide TOC
        [_splitView setPosition:0 ofDividerAtIndex:0];
    }
}

- (void)tocItemDoubleClicked:(id)sender {
    TOCItem* item = [_tocOutlineView itemAtRow:[_tocOutlineView clickedRow]];
    if (item) {
        // Find the heading in the text and scroll to it
        NSString* searchText = item.title;
        NSString* content = [[_textView textStorage] string];
        
        NSRange searchRange = [content rangeOfString:searchText 
                                             options:NSCaseInsensitiveSearch];
        
        if (searchRange.location != NSNotFound) {
            [_textView scrollRangeToVisible:searchRange];
            
            // Optionally highlight the heading briefly
            [_textView setSelectedRange:searchRange];
        }
    }
}

// MARK: - NSOutlineView DataSource & Delegate

- (NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return [_tocItems count];
    }
    if ([item isKindOfClass:[TOCItem class]]) {
        return [[(TOCItem*)item children] count];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return [_tocItems objectAtIndex:index];
    }
    if ([item isKindOfClass:[TOCItem class]]) {
        return [[(TOCItem*)item children] objectAtIndex:index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[TOCItem class]]) {
        return [[(TOCItem*)item children] count] > 0;
    }
    return NO;
}

- (NSView*)outlineView:(NSOutlineView*)outlineView viewForTableColumn:(NSTableColumn*)tableColumn item:(id)item {
    NSTextField* textField = [[NSTextField alloc] init];
    [textField setEditable:NO];
    [textField setBordered:NO];
    [textField setBackgroundColor:[NSColor clearColor]];
    
    if ([item isKindOfClass:[TOCItem class]]) {
        TOCItem* tocItem = (TOCItem*)item;
        
        // Format based on heading level
        NSFont* font;
        switch (tocItem.level) {
            case 1:
                font = [NSFont boldSystemFontOfSize:14];
                break;
            case 2:
                font = [NSFont systemFontOfSize:13];
                break;
            default:
                font = [NSFont systemFontOfSize:12];
                break;
        }
        
        [textField setFont:font];
        [textField setStringValue:tocItem.title];
    }
    
    return textField;
}

// MARK: - Drag and Drop Support

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSPasteboard* pasteboard = [sender draggingPasteboard];
    
    if ([pasteboard canReadObjectForClasses:@[[NSURL class]] options:nil]) {
        NSArray* urls = [pasteboard readObjectsForClasses:@[[NSURL class]] options:nil];
        for (NSURL* url in urls) {
            NSString* pathExtension = [[url pathExtension] lowercaseString];
            if ([pathExtension isEqualToString:@"md"] || 
                [pathExtension isEqualToString:@"markdown"] || 
                [pathExtension isEqualToString:@"txt"]) {
                return NSDragOperationCopy;
            }
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard* pasteboard = [sender draggingPasteboard];
    NSArray* urls = [pasteboard readObjectsForClasses:@[[NSURL class]] options:nil];
    
    if ([urls count] > 0) {
        NSURL* url = [urls firstObject];
        NSString* pathExtension = [[url pathExtension] lowercaseString];
        if ([pathExtension isEqualToString:@"md"] || 
            [pathExtension isEqualToString:@"markdown"] || 
            [pathExtension isEqualToString:@"txt"]) {
            [self openFile:[url path]];
            return YES;
        }
    }
    
    return NO;
}

// MARK: - Export Functions

- (void)exportAsPDF:(id)sender {
    if (!_textView || [[_textView string] length] == 0) {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No content to export"];
        [alert setInformativeText:@"Please open a markdown file first."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
    [savePanel setNameFieldStringValue:@"document.pdf"];
    
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL* url = [savePanel URL];
            [self exportTextViewToPDF:url];
        }
    }];
}

- (void)exportTextViewToPDF:(NSURL*)url {
    NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin:72];
    [printInfo setBottomMargin:72];
    [printInfo setLeftMargin:72];
    [printInfo setRightMargin:72];
    [printInfo setHorizontalPagination:NSPrintingPaginationModeFit];
    [printInfo setVerticalPagination:NSPrintingPaginationModeAutomatic];
    
    NSMutableDictionary* printOpts = [NSMutableDictionary dictionary];
    [printOpts setObject:url forKey:NSPrintJobSavingURL];
    [printOpts setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
    [printInfo setDictionary:printOpts];
    
    NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:_textView printInfo:printInfo];
    [printOp setShowsPrintPanel:NO];
    [printOp setShowsProgressPanel:YES];
    
    [printOp runOperationModalForWindow:self.view.window 
                                delegate:self 
                          didRunSelector:@selector(printOperationDidRun:success:contextInfo:) 
                             contextInfo:NULL];
}

- (void)printOperationDidRun:(NSPrintOperation*)printOperation 
                      success:(BOOL)success 
                  contextInfo:(void*)contextInfo {
    if (success) {
        [_statusLabel setStringValue:@"Export completed successfully"];
    } else {
        [_statusLabel setStringValue:@"Export failed"];
    }
}

- (void)exportAsHTML:(id)sender {
    if (!_textView || [[_textView string] length] == 0) {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No content to export"];
        [alert setInformativeText:@"Please open a markdown file first."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"html"]];
    [savePanel setNameFieldStringValue:@"document.html"];
    
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL* url = [savePanel URL];
            [self exportTextViewToHTML:url];
        }
    }];
}

- (void)exportTextViewToHTML:(NSURL*)url {
    NSAttributedString* attrString = [_textView attributedString];
    
    // Convert attributed string to HTML
    NSError* error = nil;
    NSData* htmlData = [attrString dataFromRange:NSMakeRange(0, [attrString length])
                               documentAttributes:@{
                                   NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                   NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                               }
                                            error:&error];
    
    if (error) {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Export failed"];
        [alert setInformativeText:[error localizedDescription]];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    // Create a complete HTML document with proper styling
    NSString* htmlContent = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    NSString* fullHTML = [NSString stringWithFormat:@
        "<!DOCTYPE html>\n"
        "<html>\n"
        "<head>\n"
        "  <meta charset=\"UTF-8\">\n"
        "  <title>Markdown Document</title>\n"
        "  <style>\n"
        "    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; "
        "           max-width: 900px; margin: 0 auto; padding: 20px; line-height: 1.6; }\n"
        "    pre { background: #f6f8fa; padding: 16px; overflow: auto; border-radius: 6px; }\n"
        "    code { background: #f6f8fa; padding: 2px 4px; border-radius: 3px; }\n"
        "    blockquote { border-left: 4px solid #dfe2e5; margin: 0; padding-left: 16px; color: #6a737d; }\n"
        "    table { border-collapse: collapse; width: 100%%; }\n"
        "    th, td { border: 1px solid #dfe2e5; padding: 6px 13px; }\n"
        "    th { background: #f6f8fa; }\n"
        "  </style>\n"
        "</head>\n"
        "<body>\n%@\n</body>\n"
        "</html>", htmlContent];
    
    NSData* fullHTMLData = [fullHTML dataUsingEncoding:NSUTF8StringEncoding];
    
    if ([fullHTMLData writeToURL:url atomically:YES]) {
        [_statusLabel setStringValue:@"HTML export completed successfully"];
    } else {
        [_statusLabel setStringValue:@"HTML export failed"];
    }
}

- (void)print:(id)sender {
    if (!_textView || [[_textView string] length] == 0) {
        NSAlert* alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No content to print"];
        [alert setInformativeText:@"Please open a markdown file first."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:_textView];
    [printOp runOperationModalForWindow:self.view.window 
                                delegate:nil 
                          didRunSelector:nil 
                             contextInfo:NULL];
}

// MARK: - Navigation Functions

- (void)goBack:(id)sender {
    if (_currentHistoryIndex > 0 && _navigationHistory.count > 0) {
        _currentHistoryIndex--;
        _isNavigatingHistory = YES;
        NSString* path = _navigationHistory[_currentHistoryIndex];
        [self openFile:path];
        _isNavigatingHistory = NO;
    }
}

- (void)goForward:(id)sender {
    if (_currentHistoryIndex < _navigationHistory.count - 1) {
        _currentHistoryIndex++;
        _isNavigatingHistory = YES;
        NSString* path = _navigationHistory[_currentHistoryIndex];
        [self openFile:path];
        _isNavigatingHistory = NO;
    }
}

- (void)goToTop:(id)sender {
    if (_scrollView) {
        NSPoint topPoint = NSMakePoint(0, NSMaxY([[_scrollView documentView] frame]) - NSHeight([[_scrollView contentView] bounds]));
        [[_scrollView contentView] scrollToPoint:topPoint];
        [_scrollView reflectScrolledClipView:[_scrollView contentView]];
    }
}

- (void)goToBottom:(id)sender {
    if (_scrollView) {
        NSPoint bottomPoint = NSMakePoint(0, 0);
        [[_scrollView contentView] scrollToPoint:bottomPoint];
        [_scrollView reflectScrolledClipView:[_scrollView contentView]];
    }
}

// MARK: - Recent Files Management

- (void)addToRecentFiles:(NSString*)path {
    // Remove if already exists
    [_recentFiles removeObject:path];
    
    // Add to beginning
    [_recentFiles insertObject:path atIndex:0];
    
    // Limit to 10 recent files
    if ([_recentFiles count] > 10) {
        [_recentFiles removeLastObject];
    }
    
    // Save to user defaults
    [[NSUserDefaults standardUserDefaults] setObject:_recentFiles forKey:@"RecentFiles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Update menu
    [self updateRecentFilesMenu];
}

- (void)updateRecentFilesMenu {
    // Find the recent files menu in the app menu
    NSMenu* mainMenu = [NSApp mainMenu];
    if (!mainMenu || [mainMenu numberOfItems] < 2) {
        return;
    }
    
    NSMenu* fileMenu = [[mainMenu itemAtIndex:1] submenu];
    if (!fileMenu) {
        return;
    }
    
    NSMenuItem* recentMenuItem = [fileMenu itemWithTag:1001];
    
    if (recentMenuItem) {
        NSMenu* recentMenu = [recentMenuItem submenu];
        [recentMenu removeAllItems];
        
        if ([_recentFiles count] == 0) {
            NSMenuItem* emptyItem = [[NSMenuItem alloc] initWithTitle:@"No Recent Files" 
                                                               action:nil 
                                                        keyEquivalent:@""];
            [emptyItem setEnabled:NO];
            [recentMenu addItem:emptyItem];
        } else {
            for (NSInteger i = 0; i < [_recentFiles count]; i++) {
                NSString* path = _recentFiles[i];
                NSString* filename = [path lastPathComponent];
                
                NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:filename 
                                                               action:@selector(openRecentFile:) 
                                                        keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:i];
                [item setToolTip:path];
                
                if (i < 9) {
                    // Add keyboard shortcuts for first 9 items (Cmd+1 through Cmd+9)
                    [item setKeyEquivalent:[NSString stringWithFormat:@"%ld", (long)(i + 1)]];
                    [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
                }
                
                [recentMenu addItem:item];
            }
            
            [recentMenu addItem:[NSMenuItem separatorItem]];
            
            NSMenuItem* clearItem = [[NSMenuItem alloc] initWithTitle:@"Clear Recent Files" 
                                                               action:@selector(clearRecentFiles:) 
                                                        keyEquivalent:@""];
            [clearItem setTarget:self];
            [recentMenu addItem:clearItem];
        }
    }
}

- (void)openRecentFile:(id)sender {
    NSMenuItem* item = (NSMenuItem*)sender;
    NSInteger index = [item tag];
    
    if (index >= 0 && index < [_recentFiles count]) {
        NSString* path = _recentFiles[index];
        
        // Check if file still exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [self openFile:path];
        } else {
            // File doesn't exist, remove from recent files
            [_recentFiles removeObjectAtIndex:index];
            [[NSUserDefaults standardUserDefaults] setObject:_recentFiles forKey:@"RecentFiles"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self updateRecentFilesMenu];
            
            NSAlert* alert = [[NSAlert alloc] init];
            [alert setMessageText:@"File not found"];
            [alert setInformativeText:[NSString stringWithFormat:@"The file '%@' could not be found.", [path lastPathComponent]]];
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
        }
    }
}

- (void)clearRecentFiles:(id)sender {
    [_recentFiles removeAllObjects];
    [[NSUserDefaults standardUserDefaults] setObject:_recentFiles forKey:@"RecentFiles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateRecentFilesMenu];
}

// MARK: - Zoom Functions

- (void)zoomIn:(id)sender {
    _currentFontSize = MIN(_currentFontSize + 2.0, 48.0); // Max size 48
    [self updateFontSize];
}

- (void)zoomOut:(id)sender {
    _currentFontSize = MAX(_currentFontSize - 2.0, 8.0); // Min size 8
    [self updateFontSize];
}

- (void)resetZoom:(id)sender {
    _currentFontSize = _baseFontSize;
    [self updateFontSize];
}

- (void)updateFontSize {
    if (!_textView) return;
    
    // Update the font while preserving other attributes
    NSFont* newFont = [NSFont systemFontOfSize:_currentFontSize];
    
    // Get current attributed string
    NSMutableAttributedString* content = [[NSMutableAttributedString alloc] 
        initWithAttributedString:[_textView textStorage]];
    
    // Update font throughout the document
    [content enumerateAttribute:NSFontAttributeName 
                        inRange:NSMakeRange(0, [content length]) 
                        options:0 
                     usingBlock:^(id value, NSRange range, BOOL* stop) {
        if (value) {
            NSFont* oldFont = (NSFont*)value;
            NSFontDescriptor* descriptor = [oldFont fontDescriptor];
            NSFont* scaledFont = [NSFont fontWithDescriptor:descriptor size:_currentFontSize];
            [content addAttribute:NSFontAttributeName value:scaledFont range:range];
        }
    }];
    
    [[_textView textStorage] setAttributedString:content];
    
    // Update status with zoom level
    NSInteger zoomPercent = (NSInteger)((_currentFontSize / _baseFontSize) * 100);
    NSLog(@"Zoom: %ld%%", (long)zoomPercent);
}

// MARK: - Focus Mode

- (void)setupFocusMode {
    // Focus mode disabled - no vignette or overlay effects
    _focusModeEnabled = NO;
}

- (void)toggleFocusMode {
    _focusModeEnabled = !_focusModeEnabled;
    
    // Focus mode simplified - no overlay or vignette effects
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
        context.duration = 0.5;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        if (_focusModeEnabled) {
            // Enter focus mode - just subtle UI changes
            _tocScrollView.animator.alphaValue = 0.3;
            _statusLabel.animator.alphaValue = 0.3;
            
            // Hide scroll indicators temporarily
            _topScrollIndicator.animator.alphaValue = 0.0;
            _bottomScrollIndicator.animator.alphaValue = 0.0;
            
            // Post notification for other UI updates
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FocusModeEnabled" object:nil];
        } else {
            // Exit focus mode
            
            // Restore UI elements
            _tocScrollView.animator.alphaValue = 1.0;
            _statusLabel.animator.alphaValue = 1.0;
            
            // Update scroll indicators
            [self updateScrollIndicators];
            
            // Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FocusModeDisabled" object:nil];
        }
    }];
    
    // Update status
    NSString* modeStatus = _focusModeEnabled ? @"Focus Mode: ON" : @"Focus Mode: OFF";
    NSLog(@"%@", modeStatus);
}

// MARK: - Edge Scroll Indicators

- (void)setupEdgeScrollIndicators {
    if (!self.view) return;
    NSRect frame = self.view.frame;
    
    // Top scroll indicator with gradient
    _topScrollIndicator = [[NSView alloc] initWithFrame:NSMakeRect(0, frame.size.height - 80, frame.size.width, 80)];
    _topScrollIndicator.wantsLayer = YES;
    _topScrollIndicator.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    
    // Create gradient layer for top indicator
    CAGradientLayer* topGradient = [CAGradientLayer layer];
    topGradient.frame = _topScrollIndicator.bounds;
    topGradient.colors = @[
        (id)[[NSColor blackColor] colorWithAlphaComponent:0.15].CGColor,
        (id)[[NSColor blackColor] colorWithAlphaComponent:0.05].CGColor,
        (id)[NSColor clearColor].CGColor
    ];
    topGradient.locations = @[@0.0, @0.5, @1.0];
    _topScrollIndicator.layer = topGradient;
    _topScrollIndicator.alphaValue = 0.0; // Initially hidden
    
    // Bottom scroll indicator with gradient  
    _bottomScrollIndicator = [[NSView alloc] initWithFrame:NSMakeRect(0, 22, frame.size.width, 80)];
    _bottomScrollIndicator.wantsLayer = YES;
    _bottomScrollIndicator.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    
    // Create gradient layer for bottom indicator
    CAGradientLayer* bottomGradient = [CAGradientLayer layer];
    bottomGradient.frame = _bottomScrollIndicator.bounds;
    bottomGradient.colors = @[
        (id)[NSColor clearColor].CGColor,
        (id)[[NSColor blackColor] colorWithAlphaComponent:0.05].CGColor,
        (id)[[NSColor blackColor] colorWithAlphaComponent:0.15].CGColor
    ];
    bottomGradient.locations = @[@0.0, @0.5, @1.0];
    _bottomScrollIndicator.layer = bottomGradient;
    _bottomScrollIndicator.alphaValue = 0.0; // Initially hidden
}

- (void)scrollViewDidScroll:(NSNotification*)notification {
    [self updateScrollIndicators];
}

- (void)updateScrollIndicators {
    if (!_scrollView || !_textView) return;
    
    NSRect visibleRect = [_scrollView documentVisibleRect];
    NSRect documentRect = [[_scrollView documentView] frame];
    
    // Calculate scroll position
    CGFloat scrollTop = visibleRect.origin.y;
    CGFloat scrollBottom = NSMaxY(visibleRect);
    CGFloat documentHeight = documentRect.size.height;
    
    // Top indicator - show when not at top
    BOOL canScrollUp = scrollTop > 0;
    CGFloat topAlpha = canScrollUp ? MIN(scrollTop / 100.0, 1.0) : 0.0;
    
    // Bottom indicator - show when not at bottom
    BOOL canScrollDown = scrollBottom < documentHeight;
    CGFloat bottomAlpha = canScrollDown ? MIN((documentHeight - scrollBottom) / 100.0, 1.0) : 0.0;
    
    // Animate the alpha changes
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
        context.duration = 0.2;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        _topScrollIndicator.animator.alphaValue = topAlpha;
        _bottomScrollIndicator.animator.alphaValue = bottomAlpha;
    }];
}

// MARK: - Performance and Status Management

- (NSString*)calculateReadingTime {
    // Average reading speed: 200-250 words per minute for technical content
    // We'll use 225 WPM as a balanced estimate
    const NSInteger wordsPerMinute = 225;
    
    // Get the text content (without markdown syntax would be better, but this is good enough)
    NSString* text = [_textView string];
    if (!text || text.length == 0) {
        return @"📖 0 min read";
    }
    
    // Count words - split by whitespace and newlines
    NSCharacterSet* separators = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSArray* words = [text componentsSeparatedByCharactersInSet:separators];
    
    // Filter out empty strings
    NSInteger wordCount = 0;
    for (NSString* word in words) {
        if (word.length > 0) {
            wordCount++;
        }
    }
    
    // Calculate reading time in minutes
    NSInteger minutes = (wordCount + wordsPerMinute - 1) / wordsPerMinute; // Round up
    
    // Format the reading time string
    if (minutes == 0) {
        return @"📖 <1 min read";
    } else if (minutes == 1) {
        return @"📖 1 min read";
    } else if (minutes < 60) {
        return [NSString stringWithFormat:@"📖 %ld min read", (long)minutes];
    } else {
        NSInteger hours = minutes / 60;
        NSInteger remainingMinutes = minutes % 60;
        if (remainingMinutes == 0) {
            return [NSString stringWithFormat:@"📖 %ld hr read", (long)hours];
        } else {
            return [NSString stringWithFormat:@"📖 %ld hr %ld min", (long)hours, (long)remainingMinutes];
        }
    }
}

- (void)updateStatusBar {
    // Format file size
    NSString* fileSizeStr = [self formatFileSize:_currentFileSize];
    
    // Get filename
    NSString* filename = [_currentFilePath lastPathComponent] ?: @"Untitled";
    
    // Get memory usage
    _memoryUsage = [self getCurrentMemoryUsage];
    NSString* memoryStr = [self formatFileSize:_memoryUsage];
    
    // Calculate cache hit rate (simulated for now)
    _cacheHitRate = 94.0; // Will be replaced with real metrics later
    
    // Get CPU usage
    _cpuUsage = [self getCurrentCPUUsage];
    
    // Reading time calculation removed - no longer needed
    // NSString* readingTimeStr = [self calculateReadingTime];
    
    // Format the status bar
    NSString* status = [NSString stringWithFormat:
        @"[📄 %@ | %@ | %lu lines] [Parse: %.0fms | Render: %.0fms | FPS: %.0f] [Memory: %@ | Cache: %.0f%%] [CPU: %.0f%%]",
        filename,
        fileSizeStr, 
        (unsigned long)_currentLineCount,
        _lastParseTime,
        _lastRenderTime,
        _currentFPS > 0 ? _currentFPS : 120.0, // Default to 120 if not measured
        memoryStr,
        _cacheHitRate,
        _cpuUsage
    ];
    
    [_statusLabel setStringValue:status];
}

- (NSString*)formatFileSize:(NSUInteger)bytes {
    if (bytes < 1024) {
        return [NSString stringWithFormat:@"%luB", (unsigned long)bytes];
    } else if (bytes < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1fKB", bytes / 1024.0];
    } else if (bytes < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1fMB", bytes / (1024.0 * 1024.0)];
    } else {
        return [NSString stringWithFormat:@"%.1fGB", bytes / (1024.0 * 1024.0 * 1024.0)];
    }
}

- (NSUInteger)getCurrentMemoryUsage {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if (kerr == KERN_SUCCESS) {
        return info.resident_size;
    }
    return 0;
}

- (CGFloat)getCurrentCPUUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    
    task_basic_info_t basic_info;
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;
    
    basic_info = (task_basic_info_t)tinfo;
    
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    
    for (int j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                        (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            continue;
        }
        
        thread_basic_info_t basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
    }
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    
    return tot_cpu;
}

- (void)startFPSTracking {
    if (_fpsTimer) {
        [_fpsTimer invalidate];
    }
    
    _frameCount = 0;
    _lastFPSUpdate = [NSDate date];
    
    // Update FPS every second
    _fpsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(updateFPS:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopFPSTracking {
    if (_fpsTimer) {
        [_fpsTimer invalidate];
        _fpsTimer = nil;
    }
}

- (void)updateFPS:(NSTimer*)timer {
    NSTimeInterval elapsed = -[_lastFPSUpdate timeIntervalSinceNow];
    if (elapsed > 0) {
        _currentFPS = _frameCount / elapsed;
        _frameCount = 0;
        _lastFPSUpdate = [NSDate date];
        [self updateStatusBar];
    }
}

- (void)incrementFrameCount {
    _frameCount++;
}

@end

// MTKViewDelegate methods commented out for now
/*
@interface MarkdownViewController (MTKViewDelegate) <MTKViewDelegate>
@end

@implementation MarkdownViewController (MTKViewDelegate)

- (void)drawInMTKView:(MTKView*)view {
    if (!_currentDocument) return;
    
    // Get scroll position
    NSPoint scrollPos = _scrollView.contentView.bounds.origin;
    mdviewer::RenderEngine::ScrollPosition scroll{
        static_cast<float>(scrollPos.y),
        0.0f
    };
    
    // Render
    _renderEngine->render(scroll);
    
    // Update FPS counter
    const auto& stats = _renderEngine->get_stats();
    NSString* fpsText = [NSString stringWithFormat:@"%.1f FPS", stats.fps];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_statusLabel setStringValue:fpsText];
    });
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
    _renderEngine->resize(size.width, size.height);
}

@end
*/

int main(int argc, char* argv[]) {
    @autoreleasepool {
        NSLog(@"Inkwell starting...");
        
        // Check for command-line file argument
        NSString* fileToOpen = nil;
        if (argc > 1) {
            fileToOpen = [NSString stringWithUTF8String:argv[1]];
            NSLog(@"Command-line file specified: %@", fileToOpen);
            
            // Convert to absolute path if relative
            if (![fileToOpen isAbsolutePath]) {
                NSString* cwd = [[NSFileManager defaultManager] currentDirectoryPath];
                fileToOpen = [cwd stringByAppendingPathComponent:fileToOpen];
            }
            
            // Check if file exists
            if (![[NSFileManager defaultManager] fileExistsAtPath:fileToOpen]) {
                NSLog(@"Error: File not found: %@", fileToOpen);
                fileToOpen = nil;
            }
        }
        
        @try {
            NSApplication* app = [NSApplication sharedApplication];
            NSLog(@"NSApplication created");
            
            AppDelegate* delegate = [[AppDelegate alloc] init];
            NSLog(@"AppDelegate created");
            
            // Store the file path to open after window is ready
            if (fileToOpen) {
                [[NSUserDefaults standardUserDefaults] setObject:fileToOpen forKey:@"FileToOpenAtLaunch"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [app setDelegate:delegate];
            NSLog(@"Delegate set");
            
            [app run];
        } @catch (NSException* exception) {
            NSLog(@"Caught exception: %@", exception);
            NSLog(@"Stack trace: %@", [exception callStackSymbols]);
            return 1;
        }
    }
    return 0;
}