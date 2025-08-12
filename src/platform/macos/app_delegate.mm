#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSWindow *mainWindow;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Create the main window
    NSRect frame = NSMakeRect(100, 100, 1200, 800);
    self.mainWindow = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:(NSWindowStyleMaskTitled | 
                                                           NSWindowStyleMaskClosable |
                                                           NSWindowStyleMaskMiniaturizable |
                                                           NSWindowStyleMaskResizable)
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
    
    [self.mainWindow setTitle:@"Markdown Viewer"];
    [self.mainWindow center];
    [self.mainWindow makeKeyAndOrderFront:nil];
    
    // Create menu bar
    [self createMenuBar];
}

- (void)createMenuBar {
    NSMenu *mainMenu = [[NSMenu alloc] init];
    [NSApp setMainMenu:mainMenu];
    
    // App menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Markdown Viewer"];
    
    [appMenu addItemWithTitle:@"About Markdown Viewer"
                       action:@selector(showAbout:)
                keyEquivalent:@""];
    
    [appMenu addItem:[NSMenuItem separatorItem]];
    
    [appMenu addItemWithTitle:@"Hide Markdown Viewer"
                       action:@selector(hide:)
                keyEquivalent:@"h"];
    
    [appMenu addItemWithTitle:@"Hide Others"
                       action:@selector(hideOtherApplications:)
                keyEquivalent:@"h"];
    [[appMenu itemAtIndex:[appMenu numberOfItems] - 1] 
        setKeyEquivalentModifierMask:(NSEventModifierFlagOption | NSEventModifierFlagCommand)];
    
    [appMenu addItemWithTitle:@"Show All"
                       action:@selector(unhideAllApplications:)
                keyEquivalent:@""];
    
    [appMenu addItem:[NSMenuItem separatorItem]];
    
    [appMenu addItemWithTitle:@"Quit Markdown Viewer"
                       action:@selector(terminate:)
                keyEquivalent:@"q"];
    
    [appMenuItem setSubmenu:appMenu];
    [mainMenu addItem:appMenuItem];
    
    // File menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    
    [fileMenu addItemWithTitle:@"Open..."
                        action:@selector(openDocument:)
                 keyEquivalent:@"o"];
    
    [fileMenu addItemWithTitle:@"Open Recent"
                        action:nil
                 keyEquivalent:@""];
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    [fileMenu addItemWithTitle:@"Save"
                        action:@selector(saveDocument:)
                 keyEquivalent:@"s"];
    
    [fileMenu addItemWithTitle:@"Save As..."
                        action:@selector(saveDocumentAs:)
                 keyEquivalent:@"S"];
    
    [fileMenu addItem:[NSMenuItem separatorItem]];
    
    [fileMenu addItemWithTitle:@"Export as HTML..."
                        action:@selector(exportAsHTML:)
                 keyEquivalent:@"e"];
    
    [fileMenu addItemWithTitle:@"Export as PDF..."
                        action:@selector(exportAsPDF:)
                 keyEquivalent:@""];
    
    [fileMenuItem setSubmenu:fileMenu];
    [mainMenu addItem:fileMenuItem];
    
    // Edit menu
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    
    [editMenu addItemWithTitle:@"Undo"
                        action:@selector(undo:)
                 keyEquivalent:@"z"];
    
    [editMenu addItemWithTitle:@"Redo"
                        action:@selector(redo:)
                 keyEquivalent:@"Z"];
    
    [editMenu addItem:[NSMenuItem separatorItem]];
    
    [editMenu addItemWithTitle:@"Cut"
                        action:@selector(cut:)
                 keyEquivalent:@"x"];
    
    [editMenu addItemWithTitle:@"Copy"
                        action:@selector(copy:)
                 keyEquivalent:@"c"];
    
    [editMenu addItemWithTitle:@"Paste"
                        action:@selector(paste:)
                 keyEquivalent:@"v"];
    
    [editMenu addItemWithTitle:@"Select All"
                        action:@selector(selectAll:)
                 keyEquivalent:@"a"];
    
    [editMenuItem setSubmenu:editMenu];
    [mainMenu addItem:editMenuItem];
    
    // View menu
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    
    [viewMenu addItemWithTitle:@"Show Table of Contents"
                        action:@selector(toggleTOC:)
                 keyEquivalent:@"t"];
    
    [viewMenu addItemWithTitle:@"Live Preview"
                        action:@selector(toggleLivePreview:)
                 keyEquivalent:@"l"];
    
    [viewMenu addItem:[NSMenuItem separatorItem]];
    
    [viewMenu addItemWithTitle:@"Zoom In"
                        action:@selector(zoomIn:)
                 keyEquivalent:@"+"];
    
    [viewMenu addItemWithTitle:@"Zoom Out"
                        action:@selector(zoomOut:)
                 keyEquivalent:@"-"];
    
    [viewMenu addItemWithTitle:@"Reset Zoom"
                        action:@selector(resetZoom:)
                 keyEquivalent:@"0"];
    
    [viewMenuItem setSubmenu:viewMenu];
    [mainMenu addItem:viewMenuItem];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

// Menu action stubs - to be implemented
- (IBAction)showAbout:(id)sender {
    // TODO: Show about dialog
}

- (IBAction)openDocument:(id)sender {
    // TODO: Show open dialog
}

- (IBAction)saveDocument:(id)sender {
    // TODO: Save current document
}

- (IBAction)saveDocumentAs:(id)sender {
    // TODO: Show save dialog
}

- (IBAction)exportAsHTML:(id)sender {
    // TODO: Export as HTML
}

- (IBAction)exportAsPDF:(id)sender {
    // TODO: Export as PDF
}

- (IBAction)toggleTOC:(id)sender {
    // TODO: Toggle table of contents
}

- (IBAction)toggleLivePreview:(id)sender {
    // TODO: Toggle live preview mode
}

- (IBAction)zoomIn:(id)sender {
    // TODO: Increase zoom level
}

- (IBAction)zoomOut:(id)sender {
    // TODO: Decrease zoom level
}

- (IBAction)resetZoom:(id)sender {
    // TODO: Reset zoom to 100%
}

@end

// C++ interface
namespace mdviewer {
namespace platform {

class AppDelegate_CPP {
public:
    static void* create_app_delegate() {
        AppDelegate* delegate = [[AppDelegate alloc] init];
        return (__bridge_retained void*)delegate;
    }
    
    static void set_app_delegate(void* delegate) {
        AppDelegate* appDelegate = (__bridge AppDelegate*)delegate;
        [NSApp setDelegate:appDelegate];
    }
    
    static void* get_main_window(void* delegate) {
        AppDelegate* appDelegate = (__bridge AppDelegate*)delegate;
        return (__bridge void*)appDelegate.mainWindow;
    }
};

} // namespace platform
} // namespace mdviewer