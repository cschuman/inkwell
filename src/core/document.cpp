#include "core/document.h"
#include <algorithm>
#include <numeric>
#ifdef __x86_64__
#include <immintrin.h>
#elif defined(__aarch64__)
#include <arm_neon.h>
#endif

namespace mdviewer {

Document::Document() = default;
Document::~Document() = default;

void Document::set_root(std::unique_ptr<Node> root) {
    root_ = std::move(root);
    cached_word_count_.reset();
    cached_char_count_.reset();
}

size_t Document::word_count() const {
    if (!cached_word_count_.has_value()) {
        size_t count = 0;
        visit([this, &count](const Node& node) {
            if (node.type == NodeType::Text) {
                count += count_words_simd(node.content);
            }
        });
        cached_word_count_ = count;
    }
    return cached_word_count_.value();
}

size_t Document::character_count() const {
    if (!cached_char_count_.has_value()) {
        size_t count = 0;
        visit([&count](const Node& node) {
            if (node.type == NodeType::Text) {
                count += node.content.size();
            }
        });
        cached_char_count_ = count;
    }
    return cached_char_count_.value();
}

std::vector<Document::Link> Document::extract_links() const {
    std::vector<Link> links;
    
    visit([&links](const Node& node) {
        if (node.type == NodeType::Link) {
            Link link;
            link.url = node.link_url;
            link.position = node.source_start;
            
            // Extract link text from children
            std::function<void(const Node&)> extract_text = [&link, &extract_text](const Node& n) {
                if (n.type == NodeType::Text) {
                    link.text += n.content;
                }
                for (const auto& child : n.children) {
                    extract_text(*child);
                }
            };
            
            for (const auto& child : node.children) {
                extract_text(*child);
            }
            
            links.push_back(link);
        }
    });
    
    return links;
}

void Document::visit(std::function<void(const Node&)> visitor) const {
    if (root_) {
        visit_impl(root_.get(), visitor);
    }
}

void Document::visit_impl(const Node* node, std::function<void(const Node&)>& visitor) const {
    visitor(*node);
    for (const auto& child : node->children) {
        visit_impl(child.get(), visitor);
    }
}

size_t Document::count_words_simd(std::string_view text) const {
    size_t word_count = 0;
    bool in_word = false;
    
    #ifdef __AVX2__
    const __m256i space = _mm256_set1_epi8(' ');
    const __m256i tab = _mm256_set1_epi8('\t');
    const __m256i newline = _mm256_set1_epi8('\n');
    const __m256i cr = _mm256_set1_epi8('\r');
    
    size_t i = 0;
    const size_t simd_width = 32;
    
    while (i + simd_width <= text.size()) {
        __m256i chunk = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(text.data() + i));
        
        __m256i is_space = _mm256_cmpeq_epi8(chunk, space);
        __m256i is_tab = _mm256_cmpeq_epi8(chunk, tab);
        __m256i is_newline = _mm256_cmpeq_epi8(chunk, newline);
        __m256i is_cr = _mm256_cmpeq_epi8(chunk, cr);
        
        __m256i is_whitespace = _mm256_or_si256(
            _mm256_or_si256(is_space, is_tab),
            _mm256_or_si256(is_newline, is_cr)
        );
        
        uint32_t whitespace_mask = _mm256_movemask_epi8(is_whitespace);
        
        for (size_t j = 0; j < simd_width; ++j) {
            bool is_ws = (whitespace_mask >> j) & 1;
            
            if (is_ws) {
                if (in_word) {
                    word_count++;
                    in_word = false;
                }
            } else {
                in_word = true;
            }
        }
        
        i += simd_width;
    }
    
    // Handle remaining bytes
    for (; i < text.size(); ++i) {
        char c = text[i];
        bool is_ws = (c == ' ' || c == '\t' || c == '\n' || c == '\r');
        
        if (is_ws) {
            if (in_word) {
                word_count++;
                in_word = false;
            }
        } else {
            in_word = true;
        }
    }
    #else
    // Fallback non-SIMD implementation
    for (char c : text) {
        bool is_ws = (c == ' ' || c == '\t' || c == '\n' || c == '\r');
        
        if (is_ws) {
            if (in_word) {
                word_count++;
                in_word = false;
            }
        } else {
            in_word = true;
        }
    }
    #endif
    
    if (in_word) {
        word_count++;
    }
    
    return word_count;
}

} // namespace mdviewer