#include "core/toc_generator.h"
#include <regex>

namespace mdviewer {

TOCGenerator::TOC TOCGenerator::generate(const std::string& markdown) {
    TOC toc;
    
    if (markdown.empty()) {
        return toc;
    }
    
    // Simple regex-based extraction for headings
    std::regex heading_regex(R"(^(#{1,6})\s+(.+)$)", std::regex::multiline);
    auto begin = std::sregex_iterator(markdown.begin(), markdown.end(), heading_regex);
    auto end = std::sregex_iterator();
    
    for (auto it = begin; it != end; ++it) {
        std::smatch match = *it;
        TOCItem item;
        item.level = match[1].length();  // Number of # characters
        item.title = match[2].str();
        item.offset = match.position();
        
        // Strip markdown formatting from title
        item.title = stripMarkdownFormatting(item.title);
        
        toc.items.push_back(item);
    }
    
    return toc;
}

std::string TOCGenerator::stripMarkdownFormatting(const std::string& text) {
    std::string result = text;
    
    // Remove bold markers
    result = std::regex_replace(result, std::regex(R"(\*\*|__)"), "");
    
    // Remove italic markers
    result = std::regex_replace(result, std::regex(R"(\*|_)"), "");
    
    // Remove inline code markers
    result = std::regex_replace(result, std::regex("`"), "");
    
    // Remove links but keep link text
    result = std::regex_replace(result, std::regex(R"(\[([^\]]+)\]\([^\)]+\))"), "$1");
    
    return result;
}

} // namespace mdviewer