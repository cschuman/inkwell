#ifndef MERMAID_RENDERER_H
#define MERMAID_RENDERER_H

#import <Cocoa/Cocoa.h>

@interface MermaidRenderer : NSObject

+ (instancetype)sharedRenderer;
- (void)renderMermaidCode:(NSString*)code 
             isDarkMode:(BOOL)isDarkMode
             completion:(void(^)(NSImage* image))completion;
- (NSImage*)cachedImageForCode:(NSString*)code isDarkMode:(BOOL)isDarkMode;
- (void)clearCache;

@end

#endif // MERMAID_RENDERER_H