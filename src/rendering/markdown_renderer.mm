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
    // Premium typography with elegant serif font for body text
    NSColor* textColor = isDarkMode ? 
        [NSColor colorWithWhite:0.92 alpha:0.95] : 
        [NSColor colorWithWhite:0.04 alpha:0.95];
    
    // Use New York or Georgia for body text - elegant serif
    NSFont* baseFont = nil;
    if (@available(macOS 10.15, *)) {
        baseFont = [NSFont fontWithName:@"New York" size:17] ?: 
                   [NSFont fontWithName:@"Georgia" size:17];
    } else {
        baseFont = [NSFont fontWithName:@"Georgia" size:17];
    }
    if (!baseFont) baseFont = [NSFont systemFontOfSize:17];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:1.618];  // Golden ratio line height
    [paragraphStyle setParagraphSpacing:21];       // Golden ratio spacing
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [paragraphStyle setAlignment:NSTextAlignmentLeft];
    [paragraphStyle setFirstLineHeadIndent:0];
    [paragraphStyle setHeadIndent:0];
    [paragraphStyle setTailIndent:0];
    
    return @{
        NSFontAttributeName: baseFont,
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName: paragraphStyle,
        NSKernAttributeName: @(0.3)  // Slight letter spacing for elegance
    };
}

+ (NSDictionary*)headingAttributesForLevel:(int)level isDarkMode:(BOOL)isDarkMode {
    // Golden ratio scale for headings
    CGFloat sizes[] = {68, 42, 26, 20, 17, 14}; // H1-H6 using golden ratio
    CGFloat size = sizes[MIN(level - 1, 5)];
    
    // Use SF Display or Helvetica Neue for headings - clean sans-serif
    NSFont* font = nil;
    NSFontWeight weight = (level <= 2) ? NSFontWeightThin : NSFontWeightLight;
    
    if (@available(macOS 10.15, *)) {
        font = [NSFont systemFontOfSize:size weight:weight];
    } else {
        NSString* fontName = (level <= 2) ? @"HelveticaNeue-UltraLight" : @"HelveticaNeue-Light";
        font = [NSFont fontWithName:fontName size:size] ?: [NSFont boldSystemFontOfSize:size];
    }
    
    // Monochromatic - pure black or white
    NSColor* color = isDarkMode ? 
        [NSColor colorWithWhite:1.0 alpha:0.95] : 
        [NSColor colorWithWhite:0.0 alpha:0.9];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setParagraphSpacingBefore:size * 0.8];  // Proportional spacing
    [paragraphStyle setParagraphSpacing:size * 0.4];
    [paragraphStyle setLineHeightMultiple:1.1];  // Tight line height for headings
    
    // Letter spacing for elegance - tighter for larger text
    CGFloat letterSpacing = (level <= 2) ? -1.5 : -0.5;
    
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: color,
        NSParagraphStyleAttributeName: paragraphStyle,
        NSKernAttributeName: @(letterSpacing)
    };
}

+ (NSDictionary*)codeAttributesForDarkMode:(BOOL)isDarkMode {
    // Premium monospace font - JetBrains Mono or SF Mono
    NSFont* font = [NSFont fontWithName:@"JetBrainsMono-Regular" size:14] ?:
                   [NSFont fontWithName:@"SF Mono" size:14] ?:
                   [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightLight];
    
    // Subtle background - almost imperceptible
    NSColor* bgColor = isDarkMode ? 
        [NSColor colorWithWhite:0.08 alpha:0.3] : 
        [NSColor colorWithWhite:0.0 alpha:0.02];
    
    // Monochromatic text
    NSColor* textColor = isDarkMode ?
        [NSColor colorWithWhite:0.8 alpha:0.9] :
        [NSColor colorWithWhite:0.15 alpha:0.9];
    
    NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
    [style setParagraphSpacing:8];
    [style setLineHeightMultiple:1.4];
    
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
        NSBackgroundColorAttributeName: bgColor,
        NSParagraphStyleAttributeName: style,
        NSKernAttributeName: @(0.5)  // Slightly wider spacing for readability
    };
}

+ (NSDictionary*)codeBlockAttributesForDarkMode:(BOOL)isDarkMode {
    // Clean monospace font
    NSFont* font = [NSFont fontWithName:@"SF Mono" size:13] ?:
                   [NSFont fontWithName:@"JetBrainsMono-Regular" size:13] ?:
                   [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightRegular];
    
    // GitHub-style background - subtle but visible
    NSColor* bgColor = isDarkMode ? 
        [NSColor colorWithWhite:0.1 alpha:1.0] : 
        [NSColor colorWithWhite:0.965 alpha:1.0];
    
    // Clear text color
    NSColor* textColor = isDarkMode ?
        [NSColor colorWithWhite:0.9 alpha:1.0] :
        [NSColor colorWithWhite:0.05 alpha:1.0];
    
    // Block-style paragraph formatting
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:1.45];       // Comfortable line height
    [paragraphStyle setParagraphSpacingBefore:16];     // Space before block
    [paragraphStyle setParagraphSpacing:16];           // Space after block  
    [paragraphStyle setFirstLineHeadIndent:16];        // Left padding
    [paragraphStyle setHeadIndent:16];                 // Left padding for all lines
    [paragraphStyle setTailIndent:-16];                // Right padding (negative from right edge)
    
    return @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor,
        NSBackgroundColorAttributeName: bgColor,
        NSParagraphStyleAttributeName: paragraphStyle,
        NSKernAttributeName: @(0.0)  // No extra letter spacing for code
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
                // Simple, clean code block like GitHub
                nodeAttrs = [self codeBlockAttributesForDarkMode:isDarkMode];
                
                NSMutableAttributedString* codeBlock = [[NSMutableAttributedString alloc] init];
                
                // Add newline before block
                if ([result length] > 0) {
                    [codeBlock appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
                }
                
                // Language label (if present) - subtle and integrated
                if (language) {
                    NSFont* labelFont = [NSFont systemFontOfSize:11 weight:NSFontWeightLight];
                    NSColor* labelColor = isDarkMode ? 
                        [NSColor colorWithWhite:0.6 alpha:0.7] : 
                        [NSColor colorWithWhite:0.5 alpha:0.7];
                    
                    NSDictionary* labelAttrs = @{
                        NSFontAttributeName: labelFont,
                        NSForegroundColorAttributeName: labelColor,
                        NSKernAttributeName: @(0.5)
                    };
                    
                    NSString* labelText = [NSString stringWithFormat:@"%@\n", [language lowercaseString]];
                    [codeBlock appendAttributedString:[[NSAttributedString alloc] 
                        initWithString:labelText attributes:labelAttrs]];
                }
                
                // Add the code content as-is with block attributes
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
            
            // Golden ratio indentation (21pt per level)
            NSMutableString* indent = [NSMutableString string];
            CGFloat indentPoints = 21.0f * indentLevel;  // Golden ratio spacing
            
            // Add bullet or number with refined typography
            BOOL isOrdered = node->list_ordered;
            
            // Create paragraph style with hanging indent for clean alignment
            NSMutableParagraphStyle* listStyle = [[NSMutableParagraphStyle alloc] init];
            [listStyle setFirstLineHeadIndent:indentPoints];
            [listStyle setHeadIndent:indentPoints + 24];  // Bullet + space width
            [listStyle setParagraphSpacing:18];  // More breathing room between items
            [listStyle setParagraphSpacingBefore:10];  // Add space before each item
            [listStyle setLineHeightMultiple:1.5];  // Comfortable line height
            
            NSMutableDictionary* listAttrs = [currentAttrs mutableCopy];
            listAttrs[NSParagraphStyleAttributeName] = listStyle;
            
            // Elegant bullet or number styling
            NSString* marker;
            NSDictionary* markerAttrs;
            
            if (isOrdered) {
                marker = [NSString stringWithFormat:@"%d.", node->list_start];
                // Use a lighter weight for numbers
                NSFont* numberFont = [NSFont fontWithName:@"HelveticaNeue-Light" size:15] ?: 
                                    [NSFont systemFontOfSize:15 weight:NSFontWeightLight];
                NSColor* numberColor = isDarkMode ? 
                    [NSColor colorWithWhite:0.6 alpha:0.8] : 
                    [NSColor colorWithWhite:0.3 alpha:0.8];
                markerAttrs = @{
                    NSFontAttributeName: numberFont,
                    NSForegroundColorAttributeName: numberColor
                };
            } else {
                // Use a refined bullet character
                marker = @"•";  // Clean bullet
                NSFont* bulletFont = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
                NSColor* bulletColor = isDarkMode ? 
                    [NSColor colorWithWhite:0.5 alpha:0.6] : 
                    [NSColor colorWithWhite:0.2 alpha:0.6];
                markerAttrs = @{
                    NSFontAttributeName: bulletFont,
                    NSForegroundColorAttributeName: bulletColor,
                    NSBaselineOffsetAttributeName: @(1)  // Slight vertical adjustment
                };
            }
            
            // Add indentation
            if (indentLevel > 0) {
                [result appendAttributedString:[[NSAttributedString alloc] 
                    initWithString:indent attributes:currentAttrs]];
            }
            
            // Add marker with spacing
            [result appendAttributedString:[[NSAttributedString alloc] 
                initWithString:marker attributes:markerAttrs]];
            [result appendAttributedString:[[NSAttributedString alloc] 
                initWithString:@"  " attributes:currentAttrs]];  // Elegant spacing
            
            // Update current attributes for list content
            [currentAttrs addEntriesFromDictionary:listAttrs];
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