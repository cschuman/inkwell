#pragma once

#include <string>
#include <functional>
#include <memory>
#include <vector>
#include <chrono>

namespace mdviewer {

class FileWatcher {
public:
    using ChangeCallback = std::function<void(const std::string& path)>;
    
    struct FileEvent {
        enum Type {
            Modified,
            Created,
            Deleted,
            Renamed
        };
        
        Type type;
        std::string path;
        std::string old_path; // For renames
        std::chrono::steady_clock::time_point timestamp;
    };
    
    FileWatcher();
    ~FileWatcher();
    
    bool watch(const std::string& path);
    bool unwatch(const std::string& path);
    
    void set_callback(ChangeCallback callback);
    
    void start();
    void stop();
    
    bool is_watching() const;
    
    std::vector<FileEvent> get_recent_events(size_t max_count = 10) const;
    
private:
    class Impl;
    std::unique_ptr<Impl> impl_;
};

class DiffHighlighter {
public:
    struct DiffRange {
        size_t start_line;
        size_t end_line;
        enum Type { Added, Removed, Modified } type;
    };
    
    static std::vector<DiffRange> compute_diff(
        const std::string& old_content,
        const std::string& new_content
    );
    
    static void highlight_changes(
        const std::vector<DiffRange>& ranges,
        std::chrono::milliseconds duration = std::chrono::milliseconds(500)
    );
};

} // namespace mdviewer