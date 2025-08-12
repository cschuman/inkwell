#include "utils/string_utils.h"
#include <algorithm>
#include <sstream>
#include <cctype>

namespace mdviewer {

std::string StringUtils::trim_left(const std::string& str) {
    auto start = std::find_if_not(str.begin(), str.end(), [](unsigned char ch) {
        return std::isspace(ch);
    });
    return std::string(start, str.end());
}

std::string StringUtils::trim_right(const std::string& str) {
    auto end = std::find_if_not(str.rbegin(), str.rend(), [](unsigned char ch) {
        return std::isspace(ch);
    }).base();
    return std::string(str.begin(), end);
}

std::string StringUtils::trim(const std::string& str) {
    return trim_left(trim_right(str));
}

std::vector<std::string> StringUtils::split(const std::string& str, char delimiter) {
    std::vector<std::string> result;
    std::stringstream ss(str);
    std::string item;
    
    while (std::getline(ss, item, delimiter)) {
        result.push_back(item);
    }
    
    return result;
}

std::vector<std::string_view> StringUtils::split_view(std::string_view str, char delimiter) {
    std::vector<std::string_view> result;
    size_t start = 0;
    size_t end = 0;
    
    while (end != std::string_view::npos) {
        end = str.find(delimiter, start);
        result.push_back(str.substr(start, end - start));
        start = end + 1;
    }
    
    return result;
}

std::string StringUtils::join(const std::vector<std::string>& parts, const std::string& separator) {
    if (parts.empty()) {
        return "";
    }
    
    std::string result = parts[0];
    for (size_t i = 1; i < parts.size(); ++i) {
        result += separator + parts[i];
    }
    
    return result;
}

std::string StringUtils::to_lower(const std::string& str) {
    std::string result = str;
    std::transform(result.begin(), result.end(), result.begin(), [](unsigned char c) {
        return std::tolower(c);
    });
    return result;
}

std::string StringUtils::to_upper(const std::string& str) {
    std::string result = str;
    std::transform(result.begin(), result.end(), result.begin(), [](unsigned char c) {
        return std::toupper(c);
    });
    return result;
}

std::string StringUtils::replace_all(const std::string& str, const std::string& from, const std::string& to) {
    std::string result = str;
    size_t pos = 0;
    
    while ((pos = result.find(from, pos)) != std::string::npos) {
        result.replace(pos, from.length(), to);
        pos += to.length();
    }
    
    return result;
}

bool StringUtils::starts_with(std::string_view str, std::string_view prefix) {
    return str.size() >= prefix.size() && 
           str.compare(0, prefix.size(), prefix) == 0;
}

bool StringUtils::ends_with(std::string_view str, std::string_view suffix) {
    return str.size() >= suffix.size() && 
           str.compare(str.size() - suffix.size(), suffix.size(), suffix) == 0;
}

bool StringUtils::contains(std::string_view str, std::string_view substring) {
    return str.find(substring) != std::string_view::npos;
}

std::string StringUtils::escape_html(const std::string& str) {
    std::string result;
    result.reserve(str.size() * 1.2); // Reserve some extra space
    
    for (char ch : str) {
        switch (ch) {
            case '<': result += "&lt;"; break;
            case '>': result += "&gt;"; break;
            case '&': result += "&amp;"; break;
            case '"': result += "&quot;"; break;
            case '\'': result += "&#39;"; break;
            default: result += ch; break;
        }
    }
    
    return result;
}

std::string StringUtils::unescape_html(const std::string& str) {
    std::string result = str;
    
    // Simple implementation for basic HTML entities
    result = replace_all(result, "&lt;", "<");
    result = replace_all(result, "&gt;", ">");
    result = replace_all(result, "&amp;", "&");
    result = replace_all(result, "&quot;", "\"");
    result = replace_all(result, "&#39;", "'");
    
    return result;
}

size_t StringUtils::utf8_length(std::string_view str) {
    size_t length = 0;
    for (size_t i = 0; i < str.size();) {
        unsigned char byte = str[i];
        if (byte < 0x80) {
            i += 1;
        } else if ((byte >> 5) == 0x06) {
            i += 2;
        } else if ((byte >> 4) == 0x0E) {
            i += 3;
        } else if ((byte >> 3) == 0x1E) {
            i += 4;
        } else {
            i += 1; // Invalid UTF-8, skip one byte
        }
        length++;
    }
    return length;
}

std::string StringUtils::utf8_substr(std::string_view str, size_t start, size_t length) {
    // Simplified implementation - for full UTF-8 support, would need more robust handling
    if (start == 0 && length == std::string::npos) {
        return std::string(str);
    }
    
    // For now, treat as regular string
    if (start >= str.size()) {
        return "";
    }
    
    size_t end_pos = (length == std::string::npos) ? str.size() : std::min(start + length, str.size());
    return std::string(str.substr(start, end_pos - start));
}

} // namespace mdviewer