#import "mermaid_renderer.h"
#import <WebKit/WebKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

@interface MermaidRenderRequest : NSObject
@property (strong) NSString* cacheKey;
@property (strong) NSString* code;
@property (assign) BOOL isDarkMode;
@property (strong) WKWebView* webView;
@property (copy) void(^completion)(NSImage*);
@end

@implementation MermaidRenderRequest
@end

@interface MermaidRenderer () <WKNavigationDelegate, WKScriptMessageHandler>
@property (strong) NSMutableDictionary<NSString*, NSImage*>* imageCache;
@property (strong) NSMutableArray<WKWebView*>* webViewPool;
@property (strong) NSMutableDictionary<NSString*, NSMutableArray*>* pendingRequests;
@property (strong) NSMutableDictionary<NSValue*, MermaidRenderRequest*>* activeRenders;
@property (strong) dispatch_queue_t renderQueue;
@end

@implementation MermaidRenderer

+ (instancetype)sharedRenderer {
    static MermaidRenderer* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[MermaidRenderer alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _imageCache = [NSMutableDictionary dictionary];
        _webViewPool = [NSMutableArray array];
        _pendingRequests = [NSMutableDictionary dictionary];
        _activeRenders = [NSMutableDictionary dictionary];
        _renderQueue = dispatch_queue_create("com.mdviewer.mermaid", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)warmupWebViewPool {
    // Don't warmup the pool immediately - it can cause crashes
    // WebViews will be created on-demand instead
}

- (NSString*)cacheKeyForCode:(NSString*)code isDarkMode:(BOOL)isDarkMode {
    // Create a hash of the code + theme for caching
    NSString* combined = [NSString stringWithFormat:@"%@_%@", code, isDarkMode ? @"dark" : @"light"];
    const char* str = [combined UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(str, (CC_LONG)strlen(str), result);
#pragma clang diagnostic pop
    
    NSMutableString* hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", result[i]];
    }
    return hash;
}

- (NSImage*)cachedImageForCode:(NSString*)code isDarkMode:(BOOL)isDarkMode {
    NSString* key = [self cacheKeyForCode:code isDarkMode:isDarkMode];
    return self.imageCache[key];
}

- (void)renderMermaidCode:(NSString*)code 
                isDarkMode:(BOOL)isDarkMode
                completion:(void(^)(NSImage* image))completion {
    if (!code || code.length == 0) {
        if (completion) completion(nil);
        return;
    }
    
    NSString* cacheKey = [self cacheKeyForCode:code isDarkMode:isDarkMode];
    
    // Check cache first
    NSImage* cached = self.imageCache[cacheKey];
    if (cached) {
        if (completion) completion(cached);
        return;
    }
    
    // Check if we're already rendering this
    @synchronized(self.pendingRequests) {
        NSMutableArray* pending = self.pendingRequests[cacheKey];
        if (pending) {
            // Add to pending callbacks
            if (completion) {
                [pending addObject:[completion copy]];
            }
            return;
        } else {
            // Start new render
            pending = [NSMutableArray array];
            if (completion) {
                [pending addObject:[completion copy]];
            }
            self.pendingRequests[cacheKey] = pending;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performRenderForCode:code isDarkMode:isDarkMode cacheKey:cacheKey];
    });
}

- (void)performRenderForCode:(NSString*)code 
                  isDarkMode:(BOOL)isDarkMode 
                    cacheKey:(NSString*)cacheKey {
    
    // Create render request
    MermaidRenderRequest* request = [[MermaidRenderRequest alloc] init];
    request.cacheKey = cacheKey;
    request.code = code;
    request.isDarkMode = isDarkMode;
    
    // Get pending completions
    NSMutableArray* pending = nil;
    @synchronized(self.pendingRequests) {
        pending = self.pendingRequests[cacheKey];
        if (pending && pending.count > 0) {
            void(^firstCompletion)(NSImage*) = [pending firstObject];
            request.completion = firstCompletion;
            [pending removeObjectAtIndex:0];
        }
    }
    
    // Get or create a WebView
    WKWebView* webView = nil;
    if (self.webViewPool.count > 0) {
        webView = [self.webViewPool lastObject];
        [self.webViewPool removeLastObject];
    } else {
        WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
        // Add message handler
        [config.userContentController addScriptMessageHandler:self name:@"renderComplete"];
        webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600) 
                                      configuration:config];
        webView.navigationDelegate = self;
    }
    
    request.webView = webView;
    NSValue* webViewKey = [NSValue valueWithNonretainedObject:webView];
    self.activeRenders[webViewKey] = request;
    
    NSString* theme = isDarkMode ? @"dark" : @"default";
    NSString* bgColor = isDarkMode ? @"transparent" : @"transparent";
    
    // Calculate rough size based on diagram complexity
    NSInteger lineCount = [[code componentsSeparatedByString:@"\n"] count];
    NSInteger height = MAX(300, MIN(800, lineCount * 40));
    
    NSString* html = [NSString stringWithFormat:@
        "<!DOCTYPE html>"
        "<html>"
        "<head>"
        "  <meta charset='utf-8'>"
        "  <script src='https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js'></script>"
        "  <style>"
        "    body { "
        "      margin: 0; "
        "      padding: 20px; "
        "      background: %@; "
        "      font-family: -apple-system, BlinkMacSystemFont, sans-serif;"
        "    }"
        "    #diagram { "
        "      display: flex; "
        "      justify-content: center; "
        "      align-items: center; "
        "      min-height: %ldpx;"
        "    }"
        "    .mermaid { "
        "      font-size: 14px;"
        "    }"
        "    .mermaid .node rect,"
        "    .mermaid .node circle,"
        "    .mermaid .node ellipse,"
        "    .mermaid .node polygon {"
        "      fill: %@ !important;"
        "      stroke: %@ !important;"
        "    }"
        "  </style>"
        "</head>"
        "<body>"
        "  <div id='diagram'>"
        "    <div class='mermaid'>%@</div>"
        "  </div>"
        "  <script>"
        "    mermaid.initialize({ "
        "      startOnLoad: true, "
        "      theme: '%@',"
        "      themeVariables: {"
        "        primaryColor: '%@',"
        "        primaryBorderColor: '%@',"
        "        fontSize: '14px'"
        "      }"
        "    });"
        "    mermaid.init();"
        "    window.addEventListener('load', function() {"
        "      setTimeout(function() {"
        "        window.webkit.messageHandlers.renderComplete.postMessage('done');"
        "      }, 500);"
        "    });"
        "  </script>"
        "</body>"
        "</html>", 
        bgColor, 
        (long)height,
        isDarkMode ? @"#2d3748" : @"#e2e8f0",
        isDarkMode ? @"#4a5568" : @"#cbd5e0",
        code, 
        theme,
        isDarkMode ? @"#4a5568" : @"#e2e8f0",
        isDarkMode ? @"#2d3748" : @"#cbd5e0"];
    
    // Set frame based on estimated size
    webView.frame = NSMakeRect(0, 0, 800, height);
    
    [webView loadHTMLString:html baseURL:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController 
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"renderComplete"]) {
        WKWebView* webView = (WKWebView*)message.webView;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self captureWebView:webView];
        });
    }
}

- (void)captureWebView:(WKWebView*)webView {
    NSValue* webViewKey = [NSValue valueWithNonretainedObject:webView];
    MermaidRenderRequest* request = self.activeRenders[webViewKey];
    if (!request) return;
    
    NSString* cacheKey = request.cacheKey;
    BOOL isDarkMode = request.isDarkMode;
    
    // Take a snapshot of the WebView
    WKSnapshotConfiguration* config = [[WKSnapshotConfiguration alloc] init];
    config.rect = webView.bounds;
    
    [webView takeSnapshotWithConfiguration:config completionHandler:^(NSImage* image, NSError* error) {
        if (image && !error) {
            // Process the image to remove excess whitespace
            NSImage* processedImage = [self processImage:image isDarkMode:isDarkMode];
            
            // Cache the image
            self.imageCache[cacheKey] = processedImage;
            
            // Call the completion
            if (request.completion) {
                request.completion(processedImage);
            }
            
            // Call all other pending completions
            NSMutableArray* pending = nil;
            @synchronized(self.pendingRequests) {
                pending = self.pendingRequests[cacheKey];
                [self.pendingRequests removeObjectForKey:cacheKey];
            }
            
            if (pending) {
                for (void(^completion)(NSImage*) in pending) {
                    completion(processedImage);
                }
            }
        }
        
        // Clean up
        NSValue* webViewKey = [NSValue valueWithNonretainedObject:webView];
        [self.activeRenders removeObjectForKey:webViewKey];
        
        // Return WebView to pool (reuse it next time)
        [self.webViewPool addObject:webView];
    }];
}

- (NSImage*)processImage:(NSImage*)image isDarkMode:(BOOL)isDarkMode {
    // For now, just return the image as-is
    // Could add trimming of whitespace here if needed
    return image;
}

- (void)clearCache {
    [self.imageCache removeAllObjects];
}

// WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Mermaid render failed: %@", error);
    
    NSValue* webViewKey = [NSValue valueWithNonretainedObject:webView];
    MermaidRenderRequest* request = self.activeRenders[webViewKey];
    if (request) {
        NSString* cacheKey = request.cacheKey;
        NSMutableArray* pending = nil;
        @synchronized(self.pendingRequests) {
            pending = self.pendingRequests[cacheKey];
            [self.pendingRequests removeObjectForKey:cacheKey];
        }
        
        if (pending) {
            for (void(^completion)(NSImage*) in pending) {
                completion(nil);
            }
        }
        
        // Clean up  
        [self.activeRenders removeObjectForKey:webViewKey];
        
        // Remove message handler
        @try {
            [webView.configuration.userContentController removeScriptMessageHandlerForName:@"renderComplete"];
        } @catch (NSException* e) {
            // Ignore
        }
    }
    
    // Return WebView to pool
    [self.webViewPool addObject:webView];
}

@end