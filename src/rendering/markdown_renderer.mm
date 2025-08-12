#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "mermaid_renderer.h"
#include "core/document.h"
#include "core/markdown_parser.h"
#include <stack>

// Custom text attachment for inline Mermaid diagrams
@interface MermaidTextAttachment : NSTextAttachment
@property (strong) NSString* mermaidCode;
@property (assign) BOOL isDarkMode;
@property (assign) NSTextView* textView;  // Using assign instead of weak for non-ARC
@property (assign) NSRange attachmentRange;
@end

@implementation MermaidTextAttachment

- (instancetype)initWithMermaidCode:(NSString*)code isDarkMode:(BOOL)isDarkMode {
    self = [super init];
    if (self) {
        _mermaidCode = code;
        _isDarkMode = isDarkMode;
        
        // Check cache first
        NSImage* cachedImage = [[MermaidRenderer sharedRenderer] cachedImageForCode:code 
                                                                        isDarkMode:isDarkMode];
        if (cachedImage) {
            self.image = cachedImage;
        } else {
            // Create a minimal, clean placeholder
            NSSize size = NSMakeSize(700, 200);
            NSImage* placeholderImage = [[NSImage alloc] initWithSize:size];
            [placeholderImage lockFocus];
            
            // Very subtle background
            NSColor* bgColor = isDarkMode ? 
                [NSColor colorWithWhite:0.15 alpha:0.3] : 
                [NSColor colorWithWhite:0.95 alpha:0.5];
            
            [bgColor set];
            NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height) 
                                                                 xRadius:8 
                                                                 yRadius:8];
            [path fill];
            
            // Subtle loading indicator - just three dots
            NSString* loadingText = @"⋯";
            NSMutableParagraphStyle* centerStyle = [[NSMutableParagraphStyle alloc] init];
            [centerStyle setAlignment:NSTextAlignmentCenter];
            
            NSDictionary* attrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:24],
                NSForegroundColorAttributeName: isDarkMode ? 
                    [NSColor colorWithWhite:0.4 alpha:0.5] : 
                    [NSColor colorWithWhite:0.6 alpha:0.5],
                NSParagraphStyleAttributeName: centerStyle
            };
            
            [loadingText drawInRect:NSMakeRect(0, size.height/2 - 20, size.width, 40) 
                      withAttributes:attrs];
            
            [placeholderImage unlockFocus];
            self.image = placeholderImage;
            
            // Start async rendering
            // Note: In non-ARC, we need to be careful with retain cycles
            // Store self in a way that won't create a retain cycle
            MermaidTextAttachment* attachmentRef = self;
            [[MermaidRenderer sharedRenderer] renderMermaidCode:code 
                                                      isDarkMode:isDarkMode
                                                      completion:^(NSImage* renderedImage) {
                if (attachmentRef && renderedImage) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        attachmentRef.image = renderedImage;
                        // Notify text view to redraw if we have a reference
                        if (attachmentRef.textView && attachmentRef.attachmentRange.location != NSNotFound) {
                            // Force a redraw of the text view
                            [attachmentRef.textView setNeedsDisplay:YES];
                        }
                    });
                }
            }];
        }
    }
    return self;
}

@end

@interface MarkdownRenderer : NSObject

+ (NSAttributedString*)renderDocument:(const mdviewer::Document*)document isDarkMode:(BOOL)isDarkMode;

@end

@implementation MarkdownRenderer

+ (NSDictionary*)baseAttributesForDarkMode:(BOOL)isDarkMode {
    NSColor* textColor = isDarkMode ? [NSColor colorWithWhite:0.9 alpha:1.0] : [NSColor textColor];
    NSFont* baseFont = [NSFont systemFontOfSize:14];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:4];
    [paragraphStyle setParagraphSpacing:12];
    
    return @{
        NSFontAttributeName: baseFont,
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName: paragraphStyle
    };
}

+ (NSDictionary*)headingAttributesForLevel:(int)level isDarkMode:(BOOL)isDarkMode {
    CGFloat sizes[] = {28, 24, 20, 18, 16, 14}; // H1-H6 sizes
    CGFloat size = sizes[MIN(level - 1, 5)];
    
    NSFont* font = [NSFont boldSystemFontOfSize:size];
    NSColor* color = isDarkMode ? 
        [NSColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0] : 
        [NSColor systemBlueColor];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setParagraphSpacingBefore:16];
    [paragraphStyle setParagraphSpacing:8];
    
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: color,
        NSParagraphStyleAttributeName: paragraphStyle
    };
}

+ (NSDictionary*)codeAttributesForDarkMode:(BOOL)isDarkMode {
    NSFont* font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
    NSColor* bgColor = isDarkMode ? 
        [NSColor colorWithRed:0.15 green:0.17 blue:0.2 alpha:1.0] : 
        [NSColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    NSColor* textColor = isDarkMode ?
        [NSColor colorWithRed:0.95 green:0.5 blue:0.3 alpha:1.0] :
        [NSColor colorWithRed:0.8 green:0.2 blue:0.1 alpha:1.0];
    
    // Add padding effect with a slightly rounded background
    NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
    [style setParagraphSpacing:0];
    
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
        NSBackgroundColorAttributeName: bgColor,
        NSParagraphStyleAttributeName: style,
        NSKernAttributeName: @(0.5) // Slight letter spacing for readability
    };
}

+ (NSDictionary*)codeBlockAttributesForDarkMode:(BOOL)isDarkMode {
    NSFont* font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
    NSColor* bgColor = isDarkMode ? 
        [NSColor colorWithWhite:0.1 alpha:1.0] : 
        [NSColor colorWithWhite:0.97 alpha:1.0];
    NSColor* textColor = isDarkMode ?
        [NSColor colorWithWhite:0.85 alpha:1.0] :
        [NSColor colorWithWhite:0.2 alpha:1.0];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setParagraphSpacingBefore:8];
    [paragraphStyle setParagraphSpacing:8];
    [paragraphStyle setFirstLineHeadIndent:16];
    [paragraphStyle setHeadIndent:16];
    [paragraphStyle setTailIndent:-16];
    
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
        NSBackgroundColorAttributeName: bgColor,
        NSParagraphStyleAttributeName: paragraphStyle
    };
}

+ (NSDictionary*)blockQuoteAttributesForDarkMode:(BOOL)isDarkMode {
    NSFont* baseFont = [NSFont systemFontOfSize:14];
    NSFont* font = [[NSFontManager sharedFontManager] convertFont:baseFont toHaveTrait:NSItalicFontMask];
    NSColor* textColor = isDarkMode ?
        [NSColor colorWithWhite:0.7 alpha:1.0] :
        [NSColor colorWithWhite:0.4 alpha:1.0];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setFirstLineHeadIndent:20];
    [paragraphStyle setHeadIndent:20];
    [paragraphStyle setParagraphSpacingBefore:8];
    [paragraphStyle setParagraphSpacing:8];
    
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName: paragraphStyle
    };
}

+ (NSDictionary*)linkAttributesForDarkMode:(BOOL)isDarkMode {
    NSColor* linkColor = isDarkMode ?
        [NSColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:1.0] :
        [NSColor linkColor];
    
    return @{
        NSForegroundColorAttributeName: linkColor,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSCursorAttributeName: [NSCursor pointingHandCursor]
    };
}

+ (void)renderNode:(const mdviewer::Document::Node*)node 
          toString:(NSMutableAttributedString*)result 
        isDarkMode:(BOOL)isDarkMode 
     currentAttrs:(NSMutableDictionary*)currentAttrs
      indentLevel:(NSInteger)indentLevel {
    
    if (!node) return;
    
    NSDictionary* nodeAttrs = nil;
    BOOL shouldRenderChildren = YES;
    
    switch (node->type) {
        case mdviewer::Document::NodeType::Heading: {
            nodeAttrs = [self headingAttributesForLevel:node->heading_level isDarkMode:isDarkMode];
            break;
        }
        
        case mdviewer::Document::NodeType::Paragraph: {
            // Add newline before paragraph if not at start
            if ([result length] > 0) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            nodeAttrs = [self baseAttributesForDarkMode:isDarkMode];
            break;
        }
        
        case mdviewer::Document::NodeType::CodeBlock: {
            // Add newline before code block if needed
            if ([result length] > 0 && ![[result string] hasSuffix:@"\n"]) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            
            // Build the code content from children (text nodes)
            NSMutableString* codeContent = [NSMutableString string];
            
            // Check if we have a language specified
            NSString* language = nil;
            if (!node->code_language.empty()) {
                language = [NSString stringWithUTF8String:node->code_language.c_str()];
            }
            
            // Collect all text from child nodes
            for (const auto& child : node->children) {
                if (child->type == mdviewer::Document::NodeType::Text) {
                    NSString* text = [NSString stringWithUTF8String:child->content.c_str()];
                    if (text) {
                        [codeContent appendString:text];
                    }
                }
            }
            
            // If no children, try direct content
            if ([codeContent length] == 0 && !node->content.empty()) {
                NSString* directContent = [NSString stringWithUTF8String:node->content.c_str()];
                if (directContent) {
                    [codeContent appendString:directContent];
                }
            }
            
            // Check if this is a mermaid diagram
            if (language && [language isEqualToString:@"mermaid"] && [codeContent length] > 0) {
                // For now, disable inline Mermaid rendering to prevent crashes
                // Just render it as a code block with mermaid label
                nodeAttrs = [self codeBlockAttributesForDarkMode:isDarkMode];
                
                NSMutableAttributedString* codeBlock = [[NSMutableAttributedString alloc] init];
                
                // Add the language label
                NSFont* smallFont = [NSFont monospacedSystemFontOfSize:10 weight:NSFontWeightRegular];
                NSColor* langColor = isDarkMode ? 
                    [NSColor colorWithWhite:0.6 alpha:1.0] : 
                    [NSColor colorWithWhite:0.5 alpha:1.0];
                NSDictionary* langAttrs = @{
                    NSFontAttributeName: smallFont,
                    NSForegroundColorAttributeName: langColor
                };
                [codeBlock appendAttributedString:[[NSAttributedString alloc] 
                    initWithString:@"// mermaid (diagram)\n"
                    attributes:langAttrs]];
                
                // Add the code content
                [codeBlock appendAttributedString:[[NSAttributedString alloc] 
                    initWithString:codeContent attributes:nodeAttrs]];
                
                [result appendAttributedString:codeBlock];
            } else if ([codeContent length] > 0) {
                // Regular code block
                nodeAttrs = [self codeBlockAttributesForDarkMode:isDarkMode];
                
                NSMutableAttributedString* codeBlock = [[NSMutableAttributedString alloc] init];
                
                // If we have a language, add it as a label
                if (language) {
                    NSFont* smallFont = [NSFont monospacedSystemFontOfSize:10 weight:NSFontWeightRegular];
                    NSColor* langColor = isDarkMode ? 
                        [NSColor colorWithWhite:0.6 alpha:1.0] : 
                        [NSColor colorWithWhite:0.5 alpha:1.0];
                    NSDictionary* langAttrs = @{
                        NSFontAttributeName: smallFont,
                        NSForegroundColorAttributeName: langColor
                    };
                    [codeBlock appendAttributedString:[[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"// %@\n", language]
                        attributes:langAttrs]];
                }
                
                // Add the code content
                [codeBlock appendAttributedString:[[NSAttributedString alloc] 
                    initWithString:codeContent attributes:nodeAttrs]];
                
                [result appendAttributedString:codeBlock];
            }
            
            shouldRenderChildren = NO;
            break;
        }
        
        case mdviewer::Document::NodeType::Code: {
            nodeAttrs = [self codeAttributesForDarkMode:isDarkMode];
            break;
        }
        
        case mdviewer::Document::NodeType::BlockQuote: {
            // Add newline before blockquote if needed
            if ([result length] > 0 && ![[result string] hasSuffix:@"\n"]) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            nodeAttrs = [self blockQuoteAttributesForDarkMode:isDarkMode];
            break;
        }
        
        case mdviewer::Document::NodeType::List: {
            // Lists need special handling for bullets/numbers
            if ([result length] > 0 && ![[result string] hasSuffix:@"\n"]) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            // Lists render their children (list items) with proper indentation
            break;
        }
        
        case mdviewer::Document::NodeType::ListItem: {
            // Add newline before list item if not at start
            if ([result length] > 0 && ![[result string] hasSuffix:@"\n"]) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            
            // Add proper indentation
            NSMutableString* indent = [NSMutableString string];
            for (NSInteger i = 0; i < indentLevel; i++) {
                [indent appendString:@"    "];
            }
            
            // Add bullet or number - check parent to determine if ordered
            BOOL isOrdered = NO;
            if (node->list_ordered || indentLevel > 0) {
                // For nested lists, we need to check the context
                isOrdered = node->list_ordered;
            }
            
            NSString* marker = isOrdered ? 
                [NSString stringWithFormat:@"%d. ", node->list_start] : @"• ";
            
            [result appendAttributedString:[[NSAttributedString alloc] 
                initWithString:indent attributes:currentAttrs]];
            [result appendAttributedString:[[NSAttributedString alloc] 
                initWithString:marker attributes:currentAttrs]];
            break;
        }
        
        case mdviewer::Document::NodeType::Strong: {
            NSFont* currentFont = currentAttrs[NSFontAttributeName];
            NSFont* boldFont = [[NSFontManager sharedFontManager] 
                convertFont:currentFont toHaveTrait:NSBoldFontMask];
            nodeAttrs = @{NSFontAttributeName: boldFont};
            break;
        }
        
        case mdviewer::Document::NodeType::Emphasis: {
            NSFont* currentFont = currentAttrs[NSFontAttributeName];
            NSFont* italicFont = [[NSFontManager sharedFontManager] 
                convertFont:currentFont toHaveTrait:NSItalicFontMask];
            nodeAttrs = @{NSFontAttributeName: italicFont};
            break;
        }
        
        case mdviewer::Document::NodeType::Strikethrough: {
            nodeAttrs = @{
                NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle),
                NSStrikethroughColorAttributeName: currentAttrs[NSForegroundColorAttributeName]
            };
            break;
        }
        
        case mdviewer::Document::NodeType::Link: {
            nodeAttrs = [self linkAttributesForDarkMode:isDarkMode];
            if (!node->link_url.empty()) {
                NSMutableDictionary* linkAttrs = [nodeAttrs mutableCopy];
                NSString* urlString = [NSString stringWithUTF8String:node->link_url.c_str()];
                NSURL* url = [NSURL URLWithString:urlString];
                if (url) {
                    linkAttrs[NSLinkAttributeName] = url;
                    // Make sure link is clickable
                    linkAttrs[NSCursorAttributeName] = [NSCursor pointingHandCursor];
                    linkAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                }
                nodeAttrs = linkAttrs;
            }
            break;
        }
        
        case mdviewer::Document::NodeType::Text: {
            // Render text content
            NSString* text = [NSString stringWithUTF8String:node->content.c_str()];
            if (text) {
                [result appendAttributedString:[[NSAttributedString alloc] 
                    initWithString:text attributes:currentAttrs]];
            }
            shouldRenderChildren = NO;
            break;
        }
        
        case mdviewer::Document::NodeType::LineBreak: {
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            shouldRenderChildren = NO;
            break;
        }
        
        case mdviewer::Document::NodeType::HorizontalRule: {
            // Add a horizontal line representation
            [result appendAttributedString:[[NSAttributedString alloc] 
                initWithString:@"\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" 
                attributes:currentAttrs]];
            shouldRenderChildren = NO;
            break;
        }
        
        case mdviewer::Document::NodeType::Table: {
            // Add proper spacing before table
            if ([result length] > 0) {
                if (![[result string] hasSuffix:@"\n\n"]) {
                    if ([[result string] hasSuffix:@"\n"]) {
                        [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
                    } else {
                        [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
                    }
                }
            }
            
            // Process table with proper formatting
            NSMutableParagraphStyle* tableStyle = [[NSMutableParagraphStyle alloc] init];
            [tableStyle setTabStops:@[
                [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:120 options:@{}],
                [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:240 options:@{}],
                [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:360 options:@{}],
                [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:480 options:@{}]
            ]];
            [tableStyle setDefaultTabInterval:120];
            [tableStyle setParagraphSpacing:2];
            nodeAttrs = @{NSParagraphStyleAttributeName: tableStyle};
            break;
        }
        
        case mdviewer::Document::NodeType::TableRow: {
            // Start a new line for each row
            if ([result length] > 0 && ![[result string] hasSuffix:@"\n"]) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            // Don't try to detect separator rows - md4c should handle that in parsing
            break;
        }
        
        case mdviewer::Document::NodeType::TableCell: {
            // Add tab between cells (but not before the first cell)
            NSString* resultStr = [result string];
            if ([resultStr length] > 0 && 
                ![resultStr hasSuffix:@"\n"] && 
                ![resultStr hasSuffix:@"\t"]) {
                // This is not the first cell in the row
                [result appendAttributedString:[[NSAttributedString alloc] 
                    initWithString:@"\t" attributes:currentAttrs]];
            }
            
            // If this is a header cell (TH), make it bold
            if (node->heading_level > 0) {
                NSFont* currentFont = currentAttrs[NSFontAttributeName];
                NSFont* boldFont = [[NSFontManager sharedFontManager] 
                    convertFont:currentFont toHaveTrait:NSBoldFontMask];
                nodeAttrs = @{NSFontAttributeName: boldFont};
            }
            break;
        }
        
        default:
            break;
    }
    
    // Apply attributes if we have them
    if (nodeAttrs) {
        [currentAttrs addEntriesFromDictionary:nodeAttrs];
    }
    
    // Render children
    if (shouldRenderChildren) {
        NSInteger childIndent = indentLevel;
        // Increase indent for list items
        if (node->type == mdviewer::Document::NodeType::List) {
            childIndent++;
        }
        
        for (const auto& child : node->children) {
            NSMutableDictionary* childAttrs = [currentAttrs mutableCopy];
            [self renderNode:child.get() toString:result isDarkMode:isDarkMode currentAttrs:childAttrs indentLevel:childIndent];
        }
    }
    
    // Add spacing after certain block elements
    if (node->type == mdviewer::Document::NodeType::Paragraph ||
        node->type == mdviewer::Document::NodeType::Heading ||
        node->type == mdviewer::Document::NodeType::List ||
        node->type == mdviewer::Document::NodeType::CodeBlock ||
        node->type == mdviewer::Document::NodeType::BlockQuote ||
        node->type == mdviewer::Document::NodeType::ListItem) {
        if ([result length] > 0 && ![[result string] hasSuffix:@"\n"]) {
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
    }
    
    // Add extra spacing after tables
    if (node->type == mdviewer::Document::NodeType::Table) {
        if ([result length] > 0) {
            if (![[result string] hasSuffix:@"\n\n"]) {
                if ([[result string] hasSuffix:@"\n"]) {
                    [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
                } else {
                    [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
                }
            }
        }
    }
}

+ (NSAttributedString*)renderDocument:(const mdviewer::Document*)document isDarkMode:(BOOL)isDarkMode {
    if (!document || !document->get_root()) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    NSMutableAttributedString* result = [[NSMutableAttributedString alloc] init];
    NSMutableDictionary* baseAttrs = [[self baseAttributesForDarkMode:isDarkMode] mutableCopy];
    
    const mdviewer::Document::Node* root = document->get_root();
    NSLog(@"DEBUG: Root node has %zu children", root->children.size());
    
    // Debug: Count code blocks
    int codeBlockCount = 0;
    std::function<void(const mdviewer::Document::Node*)> countCodeBlocks = 
        [&countCodeBlocks, &codeBlockCount](const mdviewer::Document::Node* node) {
            if (node->type == mdviewer::Document::NodeType::CodeBlock) {
                codeBlockCount++;
            }
            for (const auto& child : node->children) {
                countCodeBlocks(child.get());
            }
        };
    countCodeBlocks(root);
    NSLog(@"DEBUG: Document contains %d code blocks", codeBlockCount);
    
    for (const auto& child : root->children) {
        NSMutableDictionary* attrs = [baseAttrs mutableCopy];
        [self renderNode:child.get() toString:result isDarkMode:isDarkMode currentAttrs:attrs indentLevel:0];
    }
    
    NSLog(@"DEBUG: Final rendered string length: %ld", [result length]);
    
    return result;
}

@end

// C++ wrapper for Objective-C renderer
namespace mdviewer {
    
NSAttributedString* renderMarkdownDocument(const Document* doc, bool isDarkMode) {
    return [MarkdownRenderer renderDocument:doc isDarkMode:isDarkMode];
}

} // namespace mdviewer