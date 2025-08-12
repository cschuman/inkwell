#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>
#include <string>
#include <vector>

// C++ interface for Cocoa functionality
namespace mdviewer {
namespace cocoa {

class CocoaBridge {
public:
    // Window management
    static void* create_window(int width, int height, const std::string& title);
    static void show_window(void* window);
    static void hide_window(void* window);
    static void close_window(void* window);
    
    // Menu management
    static void create_menu_bar();
    static void* create_menu(const std::string& title);
    static void add_menu_item(void* menu, const std::string& title, const std::string& key_equivalent);
    
    // File dialogs
    static std::string open_file_dialog(const std::vector<std::string>& allowed_types);
    static std::string save_file_dialog(const std::string& default_name);
    
    // Font handling
    static void* create_font(const std::string& font_name, double size);
    static std::vector<std::string> get_available_fonts();
    
    // Color management
    static void* create_color(double red, double green, double blue, double alpha);
    
    // Pasteboard (clipboard)
    static void set_pasteboard_string(const std::string& text);
    static std::string get_pasteboard_string();
    
    // Notifications
    static void post_notification(const std::string& name, const std::string& object);
    
    // App lifecycle
    static void terminate_app();
};

} // namespace cocoa
} // namespace mdviewer

// Implementation
namespace mdviewer {
namespace cocoa {

void* CocoaBridge::create_window(int width, int height, const std::string& title) {
    NSRect frame = NSMakeRect(100, 100, width, height);
    NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:(NSWindowStyleMaskTitled | 
                                                            NSWindowStyleMaskClosable |
                                                            NSWindowStyleMaskMiniaturizable |
                                                            NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    
    [window setTitle:[NSString stringWithUTF8String:title.c_str()]];
    [window center];
    
    return (__bridge_retained void*)window;
}

void CocoaBridge::show_window(void* window) {
    NSWindow* nsWindow = (__bridge NSWindow*)window;
    [nsWindow makeKeyAndOrderFront:nil];
}

void CocoaBridge::hide_window(void* window) {
    NSWindow* nsWindow = (__bridge NSWindow*)window;
    [nsWindow orderOut:nil];
}

void CocoaBridge::close_window(void* window) {
    NSWindow* nsWindow = (__bridge_transfer NSWindow*)window;
    [nsWindow close];
}

void CocoaBridge::create_menu_bar() {
    NSMenu* mainMenu = [[NSMenu alloc] init];
    [NSApp setMainMenu:mainMenu];
    
    // App menu
    NSMenuItem* appMenuItem = [[NSMenuItem alloc] init];
    NSMenu* appMenu = [[NSMenu alloc] initWithTitle:@"Inkwell"];
    
    [appMenu addItemWithTitle:@"About Inkwell" action:nil keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit Inkwell" action:@selector(terminate:) keyEquivalent:@"q"];
    
    [appMenuItem setSubmenu:appMenu];
    [mainMenu addItem:appMenuItem];
}

void* CocoaBridge::create_menu(const std::string& title) {
    NSMenu* menu = [[NSMenu alloc] initWithTitle:[NSString stringWithUTF8String:title.c_str()]];
    return (__bridge_retained void*)menu;
}

void CocoaBridge::add_menu_item(void* menu, const std::string& title, const std::string& key_equivalent) {
    NSMenu* nsMenu = (__bridge NSMenu*)menu;
    NSString* titleString = [NSString stringWithUTF8String:title.c_str()];
    NSString* keyString = [NSString stringWithUTF8String:key_equivalent.c_str()];
    
    [nsMenu addItemWithTitle:titleString action:nil keyEquivalent:keyString];
}

std::string CocoaBridge::open_file_dialog(const std::vector<std::string>& allowed_types) {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    
    if (!allowed_types.empty()) {
        NSMutableArray* types = [[NSMutableArray alloc] init];
        for (const auto& type : allowed_types) {
            [types addObject:[NSString stringWithUTF8String:type.c_str()]];
        }
        [panel setAllowedFileTypes:types];
    }
    
    if ([panel runModal] == NSModalResponseOK) {
        NSURL* url = [[panel URLs] objectAtIndex:0];
        return std::string([[url path] UTF8String]);
    }
    
    return "";
}

std::string CocoaBridge::save_file_dialog(const std::string& default_name) {
    NSSavePanel* panel = [NSSavePanel savePanel];
    
    if (!default_name.empty()) {
        [panel setNameFieldStringValue:[NSString stringWithUTF8String:default_name.c_str()]];
    }
    
    if ([panel runModal] == NSModalResponseOK) {
        NSURL* url = [panel URL];
        return std::string([[url path] UTF8String]);
    }
    
    return "";
}

void* CocoaBridge::create_font(const std::string& font_name, double size) {
    NSString* fontName = [NSString stringWithUTF8String:font_name.c_str()];
    NSFont* font = [NSFont fontWithName:fontName size:size];
    
    if (!font) {
        font = [NSFont systemFontOfSize:size];
    }
    
    return (__bridge_retained void*)font;
}

std::vector<std::string> CocoaBridge::get_available_fonts() {
    std::vector<std::string> fonts;
    NSArray* fontFamilies = [[NSFontManager sharedFontManager] availableFontFamilies];
    
    for (NSString* family in fontFamilies) {
        fonts.push_back(std::string([family UTF8String]));
    }
    
    return fonts;
}

void* CocoaBridge::create_color(double red, double green, double blue, double alpha) {
    NSColor* color = [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
    return (__bridge_retained void*)color;
}

void CocoaBridge::set_pasteboard_string(const std::string& text) {
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:[NSString stringWithUTF8String:text.c_str()] forType:NSPasteboardTypeString];
}

std::string CocoaBridge::get_pasteboard_string() {
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    NSString* string = [pasteboard stringForType:NSPasteboardTypeString];
    
    if (string) {
        return std::string([string UTF8String]);
    }
    
    return "";
}

void CocoaBridge::post_notification(const std::string& name, const std::string& object) {
    NSString* notificationName = [NSString stringWithUTF8String:name.c_str()];
    NSString* notificationObject = [NSString stringWithUTF8String:object.c_str()];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName 
                                                        object:notificationObject];
}

void CocoaBridge::terminate_app() {
    [NSApp terminate:nil];
}

} // namespace cocoa
} // namespace mdviewer