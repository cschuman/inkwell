#pragma once

#include <string>
#include <string_view>
#include <vector>

namespace mdviewer {

class StringUtils {
public:
    // String trimming
    static std::string trim_left(const std::string& str);
    static std::string trim_right(const std::string& str);
    static std::string trim(const std::string& str);
    
    // String splitting
    static std::vector<std::string> split(const std::string& str, char delimiter);
    static std::vector<std::string_view> split_view(std::string_view str, char delimiter);
    
    // String joining
    static std::string join(const std::vector<std::string>& parts, const std::string& separator);
    
    // Case conversion
    static std::string to_lower(const std::string& str);
    static std::string to_upper(const std::string& str);
    
    // String replacement
    static std::string replace_all(const std::string& str, const std::string& from, const std::string& to);
    
    // String checking
    static bool starts_with(std::string_view str, std::string_view prefix);
    static bool ends_with(std::string_view str, std::string_view suffix);
    static bool contains(std::string_view str, std::string_view substring);
    
    // String escape/unescape
    static std::string escape_html(const std::string& str);
    static std::string unescape_html(const std::string& str);
    
    // Unicode handling
    static size_t utf8_length(std::string_view str);
    static std::string utf8_substr(std::string_view str, size_t start, size_t length = std::string::npos);
};

} // namespace mdviewer