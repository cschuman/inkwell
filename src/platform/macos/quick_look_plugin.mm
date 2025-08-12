#import <QuickLook/QuickLook.h>
#import <QuickLookUI/QuickLookUI.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#include <objc/runtime.h>
#include <string>
#include <sstream>
#include <memory>

// Include the actual header if dependencies are available
#ifdef HAVE_MD4C
#include "core/markdown_parser.h"
#else
// Mock classes for compilation when dependencies are not available
namespace mdviewer {
    struct Document {
        struct Node {
            enum class NodeType { Text, Paragraph, Heading, CodeBlock, BlockQuote, List, ListItem, Table, TableRow, TableCell, HorizontalRule, Link, Image, Emphasis, Strong, Code, LineBreak, Html };
            NodeType type;
            std::string content;
            std::string link_url;
            std::string image_alt;
            std::string code_language;
            int heading_level = 1;
            bool list_ordered = false;
            int list_start = 1;
            int source_start = 0;
            std::vector<std::unique_ptr<Node>> children;
        };
        
        struct TableOfContents {
            struct Entry {
                std::string text;
                int node_index = 0;
                std::vector<Entry> children;
            };
            std::vector<Entry> entries;
        };
        
        Node* get_root() { return root.get(); }
        const TableOfContents& get_toc() const { return toc; }
        
    private:
        std::unique_ptr<Node> root;
        TableOfContents toc;
    };
    
    class MarkdownParser {
    public:
        MarkdownParser() = default;
        std::unique_ptr<Document> parse(const std::string&) {
            return std::make_unique<Document>();
        }
    };
}
#endif

@interface MarkdownQuickLookGenerator : NSObject <QLPreviewingController>
{
    std::unique_ptr<mdviewer::MarkdownParser> _parser;
}
@end

@implementation MarkdownQuickLookGenerator

- (instancetype)init {
    self = [super init];
    if (self) {
        _parser = std::make_unique<mdviewer::MarkdownParser>();
    }
    return self;
}

- (void)preparePreviewOfFileAtURL:(NSURL*)url completionHandler:(void (^)(NSError* _Nullable))handler {
    @autoreleasepool {
        NSError* error = nil;
        NSString* content = [NSString stringWithContentsOfURL:url
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
        
        if (error) {
            handler(error);
            return;
        }
        
        // Parse markdown
        std::string markdown_str = [content UTF8String];
        auto document = _parser->parse(markdown_str);
        
        // Generate HTML preview
        NSString* html = [self generateHTMLFromDocument:document.get()];
        
        // Store for preview
        self.generatedHTML = html;
        
        handler(nil);
    }
}

- (NSString*)generatedHTML {
    return objc_getAssociatedObject(self, @selector(generatedHTML));
}

- (void)setGeneratedHTML:(NSString*)html {
    objc_setAssociatedObject(self, @selector(generatedHTML), html, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*)generateHTMLFromDocument:(mdviewer::Document*)document {
    if (!document || !document->get_root()) {
        return @"<html><body><p>Empty document</p></body></html>";
    }
    
    std::stringstream html;
    html << R"(<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            color: #333;
        }
        h1, h2, h3, h4, h5, h6 {
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            font-weight: 600;
        }
        h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; }
        h3 { font-size: 1.25em; }
        code {
            background: #f4f4f4;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'SF Mono', Menlo, monospace;
            font-size: 0.9em;
        }
        pre {
            background: #f4f4f4;
            padding: 12px;
            border-radius: 6px;
            overflow-x: auto;
        }
        pre code {
            background: none;
            padding: 0;
        }
        blockquote {
            border-left: 4px solid #ddd;
            padding-left: 1em;
            margin-left: 0;
            color: #666;
        }
        a {
            color: #0066cc;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background: #f4f4f4;
            font-weight: 600;
        }
        img {
            max-width: 100%;
            height: auto;
        }
        .toc {
            background: #f9f9f9;
            border: 1px solid #eee;
            border-radius: 6px;
            padding: 1em;
            margin-bottom: 2em;
        }
        .toc h2 {
            margin-top: 0;
            font-size: 1.2em;
        }
        .toc ul {
            list-style: none;
            padding-left: 1.5em;
        }
        .toc > ul {
            padding-left: 0;
        }
        .toc a {
            color: #333;
        }
    </style>
</head>
<body>
)";
    
    // Generate TOC if document has headings
    const auto& toc = document->get_toc();
    if (!toc.entries.empty()) {
        html << "<div class='toc'>\n<h2>Table of Contents</h2>\n<ul>\n";
        for (const auto& entry : toc.entries) {
            [self generateTOCEntry:html entry:entry];
        }
        html << "</ul>\n</div>\n";
    }
    
    // Generate content
    [self generateHTMLFromNode:html node:document->get_root()];
    
    html << "</body>\n</html>";
    
    return [NSString stringWithUTF8String:html.str().c_str()];
}

- (void)generateHTMLFromNode:(std::stringstream&)html node:(const mdviewer::Document::Node*)node {
    using NodeType = mdviewer::Document::Node::NodeType;
    
    switch (node->type) {
        case NodeType::Paragraph:
            html << "<p>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</p>\n";
            break;
            
        case NodeType::Heading: {
            int level = std::min(6, std::max(1, node->heading_level));
            html << "<h" << level << " id='heading-" << node->source_start << "'>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</h" << level << ">\n";
            break;
        }
            
        case NodeType::CodeBlock:
            html << "<pre><code";
            if (!node->code_language.empty()) {
                html << " class='language-" << node->code_language << "'";
            }
            html << ">" << [self escapeHTML:node->content] << "</code></pre>\n";
            break;
            
        case NodeType::BlockQuote:
            html << "<blockquote>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</blockquote>\n";
            break;
            
        case NodeType::List:
            if (node->list_ordered) {
                html << "<ol";
                if (node->list_start != 1) {
                    html << " start='" << node->list_start << "'";
                }
                html << ">\n";
            } else {
                html << "<ul>\n";
            }
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << (node->list_ordered ? "</ol>\n" : "</ul>\n");
            break;
            
        case NodeType::ListItem:
            html << "<li>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</li>\n";
            break;
            
        case NodeType::Table:
            html << "<table>\n";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</table>\n";
            break;
            
        case NodeType::TableRow:
            html << "<tr>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</tr>\n";
            break;
            
        case NodeType::TableCell:
            html << "<td>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</td>";
            break;
            
        case NodeType::HorizontalRule:
            html << "<hr>\n";
            break;
            
        case NodeType::Link:
            html << "<a href='" << [self escapeHTML:node->link_url] << "'>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</a>";
            break;
            
        case NodeType::Image:
            html << "<img src='" << [self escapeHTML:node->link_url] << "' alt='" 
                 << [self escapeHTML:node->image_alt] << "'>";
            break;
            
        case NodeType::Emphasis:
            html << "<em>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</em>";
            break;
            
        case NodeType::Strong:
            html << "<strong>";
            for (const auto& child : node->children) {
                [self generateHTMLFromNode:html node:child.get()];
            }
            html << "</strong>";
            break;
            
        case NodeType::Code:
            html << "<code>" << [self escapeHTML:node->content] << "</code>";
            break;
            
        case NodeType::Text:
            html << [self escapeHTML:node->content];
            break;
            
        case NodeType::LineBreak:
            html << "<br>\n";
            break;
            
        case NodeType::Html:
            html << node->content;
            break;
    }
}

- (void)generateTOCEntry:(std::stringstream&)html entry:(const mdviewer::Document::TableOfContents::Entry&)entry {
    html << "<li><a href='#heading-" << entry.node_index << "'>" 
         << [self escapeHTML:entry.text] << "</a>";
    
    if (!entry.children.empty()) {
        html << "\n<ul>\n";
        for (const auto& child : entry.children) {
            [self generateTOCEntry:html entry:child];
        }
        html << "</ul>\n";
    }
    
    html << "</li>\n";
}

- (std::string)escapeHTML:(const std::string&)text {
    std::string escaped;
    escaped.reserve(text.size());
    
    for (char c : text) {
        switch (c) {
            case '<': escaped += "&lt;"; break;
            case '>': escaped += "&gt;"; break;
            case '&': escaped += "&amp;"; break;
            case '"': escaped += "&quot;"; break;
            case '\'': escaped += "&#39;"; break;
            default: escaped += c; break;
        }
    }
    
    return escaped;
}

@end

// Quick Look Plugin Entry Point
@interface MarkdownQLPlugin : NSObject <QLPreviewingController>
@property (strong) MarkdownQuickLookGenerator* generator;
@end

@implementation MarkdownQLPlugin

- (instancetype)init {
    self = [super init];
    if (self) {
        _generator = [[MarkdownQuickLookGenerator alloc] init];
    }
    return self;
}

- (void)preparePreviewOfFileAtURL:(NSURL*)url completionHandler:(void (^)(NSError* _Nullable))handler {
    [self.generator preparePreviewOfFileAtURL:url completionHandler:handler];
}

- (void)preparePreviewOfSearchableItemWithIdentifier:(NSString*)identifier 
                                              queryString:(NSString*)queryString 
                                       completionHandler:(void (^)(NSError* _Nullable))handler {
    handler([NSError errorWithDomain:@"com.coreymd.markdownviewer" 
                               code:1 
                           userInfo:@{NSLocalizedDescriptionKey: @"Not implemented"}]);
}

@end

// Export the plugin class - commented out as kQLPreviewingControllerTypeID is not available
// Modern QuickLook extensions should use the modern extension system instead
#if 0
void* MarkdownQuickLookPluginFactory(CFAllocatorRef allocator, CFUUIDRef typeID) {
    // kQLPreviewingControllerTypeID is not available in current macOS SDKs
    // Modern QuickLook uses extension system instead of this factory pattern
    if (CFEqual(typeID, kQLGeneratorTypeID)) {
        return (__bridge void*)[[MarkdownQLPlugin alloc] init];
    }
    return NULL;
}
#endif