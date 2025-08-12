#include "core/markdown_parser.h"
#include <stack>
#include <fmt/format.h>
#ifdef __x86_64__
#include <immintrin.h>
#elif defined(__aarch64__)
#include <arm_neon.h>
#endif

namespace mdviewer {

class MarkdownParser::Impl {
public:
    std::pmr::memory_resource* memory;
    MD_PARSER parser;
    unsigned parser_flags = 0;
    
    std::stack<Document::Node*> node_stack;
    std::unique_ptr<Document> current_document;
    ParseCallback incremental_callback;
    
    Impl(std::pmr::memory_resource* mem) : memory(mem) {
        parser_flags = MD_FLAG_TABLES | MD_FLAG_STRIKETHROUGH | 
                      MD_FLAG_TASKLISTS | MD_FLAG_LATEXMATHSPANS;
    }
};

MarkdownParser::MarkdownParser(std::pmr::memory_resource* memory)
    : impl_(std::make_unique<Impl>(memory)) {}

MarkdownParser::~MarkdownParser() = default;

std::unique_ptr<Document> MarkdownParser::parse(std::string_view input) {
    impl_->current_document = std::make_unique<Document>();
    
    // Create a proper root node - this will be our document container
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    // Clear the stack before starting
    while (!impl_->node_stack.empty()) {
        impl_->node_stack.pop();
    }
    
    // Push the root node to the stack - this ensures stack is never empty during parsing
    impl_->node_stack.push(root.get());
    
    // Set up the parser structure
    MD_PARSER parser = {
        0,
        impl_->parser_flags,
        enter_block_callback,
        leave_block_callback,
        enter_span_callback,
        leave_span_callback,
        text_callback,
        nullptr,
        nullptr
    };
    
    // Parse the markdown if input is not empty
    int result = 0;
    if (!input.empty() && input.data() != nullptr) {
        result = md_parse(input.data(), input.size(), &parser, impl_.get());
    }
    
    // Clean up the stack but keep the root
    while (impl_->node_stack.size() > 1) {
        impl_->node_stack.pop();
    }
    // Now pop the root
    if (!impl_->node_stack.empty()) {
        impl_->node_stack.pop();
    }
    
    if (result == 0 || result == -1) {  // md_parse returns 0 on success, we'll be lenient
        impl_->current_document->set_root(std::move(root));
        // Only regenerate TOC if we have a valid root
        if (impl_->current_document->get_root()) {
            impl_->current_document->regenerate_toc();
        }
    } else {
        // If parsing failed, still use what we have
        impl_->current_document->set_root(std::move(root));
    }
    
    return std::move(impl_->current_document);
}

void MarkdownParser::parse_incremental(std::string_view input, ParseCallback callback) {
    impl_->incremental_callback = std::move(callback);
    
    MD_PARSER parser = {
        0,
        impl_->parser_flags,
        enter_block_callback,
        leave_block_callback,
        enter_span_callback,
        leave_span_callback,
        text_callback,
        nullptr,
        nullptr
    };
    
    md_parse(input.data(), input.size(), &parser, impl_.get());
}

int MarkdownParser::enter_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata) {
    auto* impl = static_cast<Impl*>(userdata);
    
    // Safety check for null impl
    if (!impl) {
        return 0;
    }
    
    // Handle document root specially
    if (type == MD_BLOCK_DOC) {
        // Document root - don't create a new node, it's already created
        return 0;
    }
    
    // For all other blocks, we need a parent node
    if (impl->node_stack.empty()) {
        return 0;
    }
    
    Document::NodeType node_type;
    switch (type) {
        case MD_BLOCK_P: node_type = Document::NodeType::Paragraph; break;
        case MD_BLOCK_H: {
            node_type = Document::NodeType::Heading;
            auto* h_detail = static_cast<MD_BLOCK_H_DETAIL*>(detail);
            auto node = std::make_unique<Document::Node>(node_type);
            node->heading_level = h_detail->level;
            impl->node_stack.top()->children.push_back(std::move(node));
            impl->node_stack.push(impl->node_stack.top()->children.back().get());
            return 0;
        }
        case MD_BLOCK_CODE: {
            node_type = Document::NodeType::CodeBlock;
            auto* code_detail = static_cast<MD_BLOCK_CODE_DETAIL*>(detail);
            auto node = std::make_unique<Document::Node>(node_type);
            if (code_detail && code_detail->lang.text && code_detail->lang.size > 0) {
                node->code_language = std::string(code_detail->lang.text, code_detail->lang.size);
            }
            if (code_detail && code_detail->info.text && code_detail->info.size > 0) {
                // info contains the full language specification (e.g., "swift" from ```swift)
                node->code_language = std::string(code_detail->info.text, code_detail->info.size);
            }
            impl->node_stack.top()->children.push_back(std::move(node));
            impl->node_stack.push(impl->node_stack.top()->children.back().get());
            return 0;
        }
        case MD_BLOCK_QUOTE: node_type = Document::NodeType::BlockQuote; break;
        case MD_BLOCK_UL: 
        case MD_BLOCK_OL: {
            node_type = Document::NodeType::List;
            auto node = std::make_unique<Document::Node>(node_type);
            if (type == MD_BLOCK_OL) {
                auto* ol_detail = static_cast<MD_BLOCK_OL_DETAIL*>(detail);
                node->list_ordered = true;
                node->list_start = ol_detail->start;
            }
            impl->node_stack.top()->children.push_back(std::move(node));
            impl->node_stack.push(impl->node_stack.top()->children.back().get());
            return 0;
        }
        case MD_BLOCK_LI: node_type = Document::NodeType::ListItem; break;
        case MD_BLOCK_HR: node_type = Document::NodeType::HorizontalRule; break;
        case MD_BLOCK_TABLE: node_type = Document::NodeType::Table; break;
        case MD_BLOCK_THEAD:
        case MD_BLOCK_TBODY:
        case MD_BLOCK_TR: node_type = Document::NodeType::TableRow; break;
        case MD_BLOCK_TH:
        case MD_BLOCK_TD: {
            node_type = Document::NodeType::TableCell;
            auto node = std::make_unique<Document::Node>(node_type);
            // Mark if this is a header cell
            if (type == MD_BLOCK_TH) {
                node->heading_level = 1;  // Use heading_level as a flag for header cells
            }
            impl->node_stack.top()->children.push_back(std::move(node));
            impl->node_stack.push(impl->node_stack.top()->children.back().get());
            return 0;
        }
        default: return 0;
    }
    
    auto node = std::make_unique<Document::Node>(node_type);
    impl->node_stack.top()->children.push_back(std::move(node));
    impl->node_stack.push(impl->node_stack.top()->children.back().get());
    
    return 0;
}

int MarkdownParser::leave_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata) {
    auto* impl = static_cast<Impl*>(userdata);
    
    if (!impl) {
        return 0;
    }
    
    // Don't pop for document root since we didn't push for it
    if (type == MD_BLOCK_DOC) {
        return 0;
    }
    
    if (!impl->node_stack.empty()) {
        impl->node_stack.pop();
    }
    
    return 0;
}

int MarkdownParser::enter_span_callback(MD_SPANTYPE type, void* detail, void* userdata) {
    auto* impl = static_cast<Impl*>(userdata);
    
    // Safety check for null impl or empty stack
    if (!impl || impl->node_stack.empty()) {
        return 0;
    }
    
    Document::NodeType node_type;
    switch (type) {
        case MD_SPAN_EM: node_type = Document::NodeType::Emphasis; break;
        case MD_SPAN_STRONG: node_type = Document::NodeType::Strong; break;
        case MD_SPAN_CODE: node_type = Document::NodeType::Code; break;
        case MD_SPAN_DEL: node_type = Document::NodeType::Strikethrough; break;
        case MD_SPAN_A: {
            node_type = Document::NodeType::Link;
            auto* link_detail = static_cast<MD_SPAN_A_DETAIL*>(detail);
            if (!link_detail || !link_detail->href.text) {
                return 0;
            }
            auto node = std::make_unique<Document::Node>(node_type);
            node->link_url = std::string(link_detail->href.text, link_detail->href.size);
            impl->node_stack.top()->children.push_back(std::move(node));
            impl->node_stack.push(impl->node_stack.top()->children.back().get());
            return 0;
        }
        case MD_SPAN_IMG: {
            node_type = Document::NodeType::Image;
            auto* img_detail = static_cast<MD_SPAN_IMG_DETAIL*>(detail);
            if (!img_detail || !img_detail->src.text) {
                return 0;
            }
            auto node = std::make_unique<Document::Node>(node_type);
            node->link_url = std::string(img_detail->src.text, img_detail->src.size);
            impl->node_stack.top()->children.push_back(std::move(node));
            impl->node_stack.push(impl->node_stack.top()->children.back().get());
            return 0;
        }
        default: return 0;
    }
    
    auto node = std::make_unique<Document::Node>(node_type);
    impl->node_stack.top()->children.push_back(std::move(node));
    impl->node_stack.push(impl->node_stack.top()->children.back().get());
    
    return 0;
}

int MarkdownParser::leave_span_callback(MD_SPANTYPE type, void* detail, void* userdata) {
    auto* impl = static_cast<Impl*>(userdata);
    
    // Safety check for null impl
    if (!impl) {
        return 0;
    }
    
    if (!impl->node_stack.empty()) {
        impl->node_stack.pop();
    }
    
    return 0;
}

int MarkdownParser::text_callback(MD_TEXTTYPE type, const MD_CHAR* text, MD_SIZE size, void* userdata) {
    auto* impl = static_cast<Impl*>(userdata);
    
    // Safety checks
    if (!impl || impl->node_stack.empty() || !text || size == 0) {
        return 0;
    }
    
    auto node = std::make_unique<Document::Node>(Document::NodeType::Text);
    node->content = std::string(text, size);
    impl->node_stack.top()->children.push_back(std::move(node));
    
    if (impl->incremental_callback) {
        impl->incremental_callback(*node);
    }
    
    return 0;
}

void MarkdownParser::detect_wikilinks(std::string_view text, std::vector<Document::Link>& links) {
    detect_wikilinks_simd(text.data(), text.size(), links);
}

void MarkdownParser::detect_wikilinks_simd(const char* text, size_t len, std::vector<Document::Link>& links) {
    size_t i = 0;
    
    #ifdef __AVX2__
    const __m256i open_bracket = _mm256_set1_epi8('[');
    const __m256i close_bracket = _mm256_set1_epi8(']');
    while (i + 32 <= len) {
        __m256i chunk = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(text + i));
        __m256i open_match = _mm256_cmpeq_epi8(chunk, open_bracket);
        __m256i close_match = _mm256_cmpeq_epi8(chunk, close_bracket);
        
        uint32_t open_mask = _mm256_movemask_epi8(open_match);
        uint32_t close_mask = _mm256_movemask_epi8(close_match);
        
        while (open_mask) {
            int open_pos = __builtin_ctz(open_mask);
            size_t abs_open = i + open_pos;
            
            if (abs_open + 1 < len && text[abs_open + 1] == '[') {
                size_t link_start = abs_open + 2;
                size_t link_end = link_start;
                
                while (link_end + 1 < len && 
                       !(text[link_end] == ']' && text[link_end + 1] == ']')) {
                    link_end++;
                }
                
                if (link_end + 1 < len) {
                    Document::Link link;
                    link.text = std::string(text + link_start, link_end - link_start);
                    link.url = link.text;
                    link.position = abs_open;
                    link.is_wikilink = true;
                    links.push_back(link);
                }
            }
            
            open_mask &= open_mask - 1;
        }
        
        i += 32;
    }
    #endif
    
    // Handle remaining bytes
    for (; i < len - 1; ++i) {
        if (text[i] == '[' && text[i + 1] == '[') {
            size_t link_start = i + 2;
            size_t link_end = link_start;
            
            while (link_end + 1 < len && 
                   !(text[link_end] == ']' && text[link_end + 1] == ']')) {
                link_end++;
            }
            
            if (link_end + 1 < len) {
                Document::Link link;
                link.text = std::string(text + link_start, link_end - link_start);
                link.url = link.text;
                link.position = i;
                link.is_wikilink = true;
                links.push_back(link);
                
                i = link_end + 1;
            }
        }
    }
}

void MarkdownParser::enable_github_extensions(bool enable) {
    if (enable) {
        impl_->parser_flags |= MD_FLAG_TABLES | MD_FLAG_STRIKETHROUGH | MD_FLAG_TASKLISTS;
    } else {
        impl_->parser_flags &= ~(MD_FLAG_TABLES | MD_FLAG_STRIKETHROUGH | MD_FLAG_TASKLISTS);
    }
}

void MarkdownParser::enable_tables(bool enable) {
    if (enable) {
        impl_->parser_flags |= MD_FLAG_TABLES;
    } else {
        impl_->parser_flags &= ~MD_FLAG_TABLES;
    }
}

void MarkdownParser::enable_strikethrough(bool enable) {
    if (enable) {
        impl_->parser_flags |= MD_FLAG_STRIKETHROUGH;
    } else {
        impl_->parser_flags &= ~MD_FLAG_STRIKETHROUGH;
    }
}

} // namespace mdviewer