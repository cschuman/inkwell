#import <Cocoa/Cocoa.h>
#include <memory>
#include <string>

@interface MainWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTextView *textView;

- (instancetype)initWithWindow:(NSWindow *)window;
- (void)setupUI;
- (void)loadMarkdownFile:(NSString *)filePath;

@end

@implementation MainWindowController

- (instancetype)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    NSWindow *window = self.window;
    [window setDelegate:self];
    
    // Create scroll view and text view
    self.scrollView = [[NSScrollView alloc] init];
    [self.scrollView setHasVerticalScroller:YES];
    [self.scrollView setHasHorizontalScroller:YES];
    [self.scrollView setAutohidesScrollers:YES];
    
    self.textView = [[NSTextView alloc] init];
    [self.textView setFont:[NSFont fontWithName:@"SF Mono" size:14]];
    [self.textView setString:@"# Welcome to Inkwell\n\nA fast, native markdown viewer for macOS."];
    [self.textView setAutomaticQuoteSubstitutionEnabled:NO];
    [self.textView setAutomaticDashSubstitutionEnabled:NO];
    [self.textView setAutomaticTextReplacementEnabled:NO];
    [self.textView setEditable:NO];  // Read-only viewer
    
    [self.scrollView setDocumentView:self.textView];
    
    // Set as window content
    [window setContentView:self.scrollView];
    
    // Setup auto layout
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSView *contentView = window.contentView;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor]
    ]];
}

- (void)loadMarkdownFile:(NSString *)filePath {
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:filePath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    if (content && !error) {
        [self.textView setString:content];
        [self.window setTitle:[filePath lastPathComponent]];
    }
}

// Window delegate methods
- (BOOL)windowShouldClose:(NSWindow *)sender {
    return YES;
}

@end

// C++ interface
namespace mdviewer {
namespace platform {

class MainWindow {
public:
    static void* create_main_window(void* window) {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        MainWindowController* controller = [[MainWindowController alloc] initWithWindow:nsWindow];
        return (__bridge_retained void*)controller;
    }
    
    static void load_file(void* controller, const std::string& file_path) {
        MainWindowController* windowController = (__bridge MainWindowController*)controller;
        NSString* path = [NSString stringWithUTF8String:file_path.c_str()];
        [windowController loadMarkdownFile:path];
    }
};

} // namespace platform
} // namespace mdviewer