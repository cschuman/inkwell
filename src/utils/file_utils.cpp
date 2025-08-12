#include "utils/file_utils.h"
#include <fstream>
#include <sstream>
#include <algorithm>

namespace mdviewer {

std::optional<std::string> FileUtils::read_file(const std::filesystem::path& path) {
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        return std::nullopt;
    }
    
    std::ostringstream ss;
    ss << file.rdbuf();
    return ss.str();
}

bool FileUtils::write_file(const std::filesystem::path& path, const std::string& content) {
    std::ofstream file(path, std::ios::binary);
    if (!file.is_open()) {
        return false;
    }
    
    file << content;
    return file.good();
}

bool FileUtils::exists(const std::filesystem::path& path) {
    return std::filesystem::exists(path);
}

bool FileUtils::is_file(const std::filesystem::path& path) {
    return std::filesystem::is_regular_file(path);
}

bool FileUtils::is_directory(const std::filesystem::path& path) {
    return std::filesystem::is_directory(path);
}

std::optional<std::uintmax_t> FileUtils::file_size(const std::filesystem::path& path) {
    std::error_code ec;
    auto size = std::filesystem::file_size(path, ec);
    if (ec) {
        return std::nullopt;
    }
    return size;
}

bool FileUtils::create_directory(const std::filesystem::path& path) {
    std::error_code ec;
    return std::filesystem::create_directory(path, ec) && !ec;
}

bool FileUtils::create_directories(const std::filesystem::path& path) {
    std::error_code ec;
    return std::filesystem::create_directories(path, ec) && !ec;
}

std::vector<std::filesystem::path> FileUtils::list_directory(const std::filesystem::path& path) {
    std::vector<std::filesystem::path> result;
    
    std::error_code ec;
    for (const auto& entry : std::filesystem::directory_iterator(path, ec)) {
        if (!ec) {
            result.push_back(entry.path());
        }
    }
    
    return result;
}

std::filesystem::path FileUtils::get_parent_path(const std::filesystem::path& path) {
    return path.parent_path();
}

std::string FileUtils::get_filename(const std::filesystem::path& path) {
    return path.filename().string();
}

std::string FileUtils::get_extension(const std::filesystem::path& path) {
    return path.extension().string();
}

std::filesystem::path FileUtils::change_extension(const std::filesystem::path& path, const std::string& new_ext) {
    auto result = path;
    result.replace_extension(new_ext);
    return result;
}

bool FileUtils::is_markdown_file(const std::filesystem::path& path) {
    auto ext = get_extension(path);
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
    
    return ext == ".md" || ext == ".markdown" || ext == ".mdown" || 
           ext == ".mkd" || ext == ".mdx" || ext == ".text" || ext == ".txt";
}

bool FileUtils::is_text_file(const std::filesystem::path& path) {
    auto ext = get_extension(path);
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
    
    // Common text file extensions
    static const std::vector<std::string> text_extensions = {
        ".txt", ".text", ".md", ".markdown", ".mdown", ".mkd", ".mdx",
        ".rst", ".tex", ".log", ".cfg", ".conf", ".ini", ".yml", ".yaml",
        ".json", ".xml", ".html", ".htm", ".css", ".js", ".ts", ".py",
        ".cpp", ".hpp", ".c", ".h", ".java", ".swift", ".go", ".rs"
    };
    
    return std::find(text_extensions.begin(), text_extensions.end(), ext) != text_extensions.end();
}

std::filesystem::path FileUtils::create_temp_file(const std::string& prefix) {
    auto temp_dir = get_temp_directory();
    
    // Simple temp file creation - in production, would use more secure methods
    static int counter = 0;
    std::string filename = prefix + "_" + std::to_string(counter++);
    
    return temp_dir / filename;
}

std::filesystem::path FileUtils::get_temp_directory() {
    return std::filesystem::temp_directory_path();
}

std::filesystem::path FileUtils::get_user_config_directory() {
    // macOS-specific implementation
    if (const char* home = std::getenv("HOME")) {
        return std::filesystem::path(home) / "Library" / "Application Support" / "Inkwell";
    }
    return get_temp_directory();
}

std::filesystem::path FileUtils::get_user_cache_directory() {
    // macOS-specific implementation
    if (const char* home = std::getenv("HOME")) {
        return std::filesystem::path(home) / "Library" / "Caches" / "Inkwell";
    }
    return get_temp_directory();
}

std::filesystem::path FileUtils::get_user_documents_directory() {
    // macOS-specific implementation
    if (const char* home = std::getenv("HOME")) {
        return std::filesystem::path(home) / "Documents";
    }
    return get_temp_directory();
}

} // namespace mdviewer