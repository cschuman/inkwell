#pragma once

#include <string_view>
#include <memory>
#include <functional>
#include <vector>
#include <memory_resource>
#include "core/document.h"

extern "C" {
#include "md4c.h"
}

namespace mdviewer {

class MarkdownParser {
public:
    using ParseCallback = std::function<void(const Document::Node&)>;
    
    explicit MarkdownParser(std::pmr::memory_resource* memory = std::pmr::get_default_resource());
    ~MarkdownParser();
    
    std::unique_ptr<Document> parse(std::string_view input);
    
    void parse_incremental(std::string_view input, ParseCallback callback);
    
    void detect_wikilinks(std::string_view text, std::vector<Document::Link>& links);
    
    void enable_github_extensions(bool enable = true);
    void enable_tables(bool enable = true);
    void enable_strikethrough(bool enable = true);
    
private:
    class Impl;
    std::unique_ptr<Impl> impl_;
    
    static int enter_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata);
    static int leave_block_callback(MD_BLOCKTYPE type, void* detail, void* userdata);
    static int enter_span_callback(MD_SPANTYPE type, void* detail, void* userdata);
    static int leave_span_callback(MD_SPANTYPE type, void* detail, void* userdata);
    static int text_callback(MD_TEXTTYPE type, const MD_CHAR* text, MD_SIZE size, void* userdata);
    
    void detect_wikilinks_simd(const char* text, size_t len, std::vector<Document::Link>& links);
};

} // namespace mdviewer