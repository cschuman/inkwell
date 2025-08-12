#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#include <memory>
#include <string>

@interface MainWindowController : NSWindowController <NSWindowDelegate, MTKViewDelegate>

@property (nonatomic, strong) MTKView *metalView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSSplitView *splitView;

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
    
    // Create split view
    self.splitView = [[NSSplitView alloc] init];
    [self.splitView setVertical:YES];
    [self.splitView setDividerStyle:NSSplitViewDividerStyleThin];
    
    // Create Metal view for rendering
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self.metalView = [[MTKView alloc] init];
    [self.metalView setDevice:device];
    [self.metalView setDelegate:self];
    [self.metalView setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
    [self.metalView setPaused:YES];
    [self.metalView setEnableSetNeedsDisplay:YES];
    
    // Create scroll view and text view for editing
    self.scrollView = [[NSScrollView alloc] init];
    [self.scrollView setHasVerticalScroller:YES];
    [self.scrollView setHasHorizontalScroller:YES];
    [self.scrollView setAutohidesScrollers:YES];
    
    self.textView = [[NSTextView alloc] init];
    [self.textView setFont:[NSFont fontWithName:@"SF Mono" size:14]];
    [self.textView setString:@"# Welcome to Markdown Viewer\n\nStart typing your markdown here..."];
    [self.textView setAutomaticQuoteSubstitutionEnabled:NO];
    [self.textView setAutomaticDashSubstitutionEnabled:NO];
    [self.textView setAutomaticTextReplacementEnabled:NO];
    [self.textView setRichText:NO];
    
    [self.scrollView setDocumentView:self.textView];
    
    // Add views to split view
    [self.splitView addSubview:self.scrollView];
    [self.splitView addSubview:self.metalView];
    
    // Set equal split initially
    [self.splitView setPosition:window.frame.size.width / 2.0 
                 ofDividerAtIndex:0];
    
    // Set as window content
    [window setContentView:self.splitView];
    
    // Setup auto layout
    [self.splitView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSView *contentView = window.contentView;
    [NSLayoutConstraint activateConstraints:@[
        [self.splitView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [self.splitView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [self.splitView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [self.splitView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor]
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

// MTKViewDelegate methods
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Handle resize
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    // Render markdown content here
    // For now, just clear to a light gray
    id<MTLCommandQueue> commandQueue = [view.device newCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor) {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1.0);
        
        id<MTLRenderCommandEncoder> renderEncoder = 
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}

// Window delegate methods
- (BOOL)windowShouldClose:(NSWindow *)sender {
    // TODO: Check if document needs saving
    return YES;
}

- (void)windowDidResize:(NSNotification *)notification {
    [self.metalView setNeedsDisplay:YES];
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
    
    static void set_content(void* controller, const std::string& content) {
        MainWindowController* windowController = (__bridge MainWindowController*)controller;
        NSString* text = [NSString stringWithUTF8String:content.c_str()];
        [windowController.textView setString:text];
    }
    
    static std::string get_content(void* controller) {
        MainWindowController* windowController = (__bridge MainWindowController*)controller;
        NSString* content = [windowController.textView string];
        return std::string([content UTF8String]);
    }
    
    static void set_title(void* controller, const std::string& title) {
        MainWindowController* windowController = (__bridge MainWindowController*)controller;
        NSString* titleString = [NSString stringWithUTF8String:title.c_str()];
        [windowController.window setTitle:titleString];
    }
    
    static void show_window(void* controller) {
        MainWindowController* windowController = (__bridge MainWindowController*)controller;
        [windowController.window makeKeyAndOrderFront:nil];
    }
    
    static void hide_window(void* controller) {
        MainWindowController* windowController = (__bridge MainWindowController*)controller;
        [windowController.window orderOut:nil];
    }
};

} // namespace platform
} // namespace mdviewer