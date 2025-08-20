#pragma once

#include <string>
#include <vector>

namespace mdviewer {

class TOCGenerator {
public:
    struct TOCItem {
        std::string title;
        int level;
        size_t offset;
    };
    
    struct TOC {
        std::vector<TOCItem> items;
    };
    
    TOCGenerator() = default;
    ~TOCGenerator() = default;
    
    TOC generate(const std::string& markdown);
    
private:
    static std::string stripMarkdownFormatting(const std::string& text);
};

} // namespace mdviewer