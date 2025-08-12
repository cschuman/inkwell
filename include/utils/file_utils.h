#pragma once

#include <string>
#include <vector>
#include <optional>
#include <filesystem>

namespace mdviewer {

class FileUtils {
public:
    // File reading/writing
    static std::optional<std::string> read_file(const std::filesystem::path& path);
    static bool write_file(const std::filesystem::path& path, const std::string& content);
    
    // File existence and properties
    static bool exists(const std::filesystem::path& path);
    static bool is_file(const std::filesystem::path& path);
    static bool is_directory(const std::filesystem::path& path);
    static std::optional<std::uintmax_t> file_size(const std::filesystem::path& path);
    
    // Directory operations
    static bool create_directory(const std::filesystem::path& path);
    static bool create_directories(const std::filesystem::path& path);
    static std::vector<std::filesystem::path> list_directory(const std::filesystem::path& path);
    
    // Path manipulation
    static std::filesystem::path get_parent_path(const std::filesystem::path& path);
    static std::string get_filename(const std::filesystem::path& path);
    static std::string get_extension(const std::filesystem::path& path);
    static std::filesystem::path change_extension(const std::filesystem::path& path, const std::string& new_ext);
    
    // File type detection
    static bool is_markdown_file(const std::filesystem::path& path);
    static bool is_text_file(const std::filesystem::path& path);
    
    // Temporary files
    static std::filesystem::path create_temp_file(const std::string& prefix = "mdviewer");
    static std::filesystem::path get_temp_directory();
    
    // Platform-specific paths
    static std::filesystem::path get_user_config_directory();
    static std::filesystem::path get_user_cache_directory();
    static std::filesystem::path get_user_documents_directory();
};

} // namespace mdviewer