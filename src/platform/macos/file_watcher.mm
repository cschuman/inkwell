#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#include "platform/file_watcher.h"
#include <mutex>
#include <thread>
#include <queue>
#include <condition_variable>

namespace mdviewer {

// Thread-safe queue implementation to replace folly::ProducerConsumerQueue
template<typename T>
class ThreadSafeQueue {
private:
    std::queue<T> queue_;
    mutable std::mutex mutex_;
    std::condition_variable condition_;
    const size_t max_size_;

public:
    explicit ThreadSafeQueue(size_t max_size = 1024) : max_size_(max_size) {}
    
    bool write(const T& item) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue_.size() >= max_size_) {
            return false; // Queue full
        }
        queue_.push(item);
        condition_.notify_one();
        return true;
    }
    
    bool read(T& item) {
        std::unique_lock<std::mutex> lock(mutex_);
        if (queue_.empty()) {
            return false;
        }
        item = queue_.front();
        queue_.pop();
        return true;
    }
    
    bool empty() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return queue_.empty();
    }
};

class FileWatcher::Impl {
public:
    FSEventStreamRef stream = nullptr;
    std::vector<std::string> watched_paths;
    ChangeCallback callback;
    ThreadSafeQueue<FileEvent> event_queue{1024};
    std::thread event_thread;
    std::atomic<bool> running{false};
    std::mutex mutex;
    
    static void fsevents_callback(
        ConstFSEventStreamRef streamRef,
        void* clientCallBackInfo,
        size_t numEvents,
        void* eventPaths,
        const FSEventStreamEventFlags eventFlags[],
        const FSEventStreamEventId eventIds[]
    ) {
        auto* impl = static_cast<Impl*>(clientCallBackInfo);
        char** paths = static_cast<char**>(eventPaths);
        
        for (size_t i = 0; i < numEvents; ++i) {
            FileEvent event;
            event.path = std::string(paths[i]);
            event.timestamp = std::chrono::steady_clock::now();
            
            if (eventFlags[i] & kFSEventStreamEventFlagItemCreated) {
                event.type = FileEvent::Created;
            } else if (eventFlags[i] & kFSEventStreamEventFlagItemRemoved) {
                event.type = FileEvent::Deleted;
            } else if (eventFlags[i] & kFSEventStreamEventFlagItemRenamed) {
                event.type = FileEvent::Renamed;
            } else if (eventFlags[i] & kFSEventStreamEventFlagItemModified) {
                event.type = FileEvent::Modified;
            } else {
                continue;
            }
            
            impl->event_queue.write(event);
            
            if (impl->callback) {
                impl->callback(event.path);
            }
        }
    }
    
    void process_events() {
        while (running) {
            FileEvent event;
            while (event_queue.read(event)) {
                // Events are already processed in callback
                // This thread could be used for additional processing
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }
};

FileWatcher::FileWatcher() : impl_(std::make_unique<Impl>()) {}

FileWatcher::~FileWatcher() {
    stop();
}

bool FileWatcher::watch(const std::string& path) {
    std::lock_guard<std::mutex> lock(impl_->mutex);
    
    impl_->watched_paths.push_back(path);
    
    if (impl_->stream) {
        FSEventStreamStop(impl_->stream);
        FSEventStreamInvalidate(impl_->stream);
        FSEventStreamRelease(impl_->stream);
    }
    
    NSMutableArray* paths = [NSMutableArray array];
    for (const auto& p : impl_->watched_paths) {
        [paths addObject:[NSString stringWithUTF8String:p.c_str()]];
    }
    
    FSEventStreamContext context = {0, impl_.get(), nullptr, nullptr, nullptr};
    
    impl_->stream = FSEventStreamCreate(
        kCFAllocatorDefault,
        &Impl::fsevents_callback,
        &context,
        (__bridge CFArrayRef)paths,
        kFSEventStreamEventIdSinceNow,
        0.1, // Latency in seconds
        kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagWatchRoot
    );
    
    if (!impl_->stream) {
        return false;
    }
    
    FSEventStreamScheduleWithRunLoop(
        impl_->stream,
        CFRunLoopGetCurrent(),
        kCFRunLoopDefaultMode
    );
    
    return FSEventStreamStart(impl_->stream);
}

bool FileWatcher::unwatch(const std::string& path) {
    std::lock_guard<std::mutex> lock(impl_->mutex);
    
    auto it = std::find(impl_->watched_paths.begin(), impl_->watched_paths.end(), path);
    if (it != impl_->watched_paths.end()) {
        impl_->watched_paths.erase(it);
        
        if (impl_->watched_paths.empty()) {
            stop();
        } else {
            // Recreate stream with remaining paths
            return watch(impl_->watched_paths.front());
        }
    }
    
    return true;
}

void FileWatcher::set_callback(ChangeCallback callback) {
    std::lock_guard<std::mutex> lock(impl_->mutex);
    impl_->callback = std::move(callback);
}

void FileWatcher::start() {
    if (!impl_->running.exchange(true)) {
        impl_->event_thread = std::thread(&Impl::process_events, impl_.get());
    }
}

void FileWatcher::stop() {
    impl_->running = false;
    
    if (impl_->event_thread.joinable()) {
        impl_->event_thread.join();
    }
    
    if (impl_->stream) {
        FSEventStreamStop(impl_->stream);
        FSEventStreamInvalidate(impl_->stream);
        FSEventStreamRelease(impl_->stream);
        impl_->stream = nullptr;
    }
}

bool FileWatcher::is_watching() const {
    return impl_->running && impl_->stream != nullptr;
}

std::vector<FileWatcher::FileEvent> FileWatcher::get_recent_events(size_t max_count) const {
    std::vector<FileEvent> events;
    // Implementation would maintain a circular buffer of recent events
    return events;
}

// DiffHighlighter implementation
std::vector<DiffHighlighter::DiffRange> DiffHighlighter::compute_diff(
    const std::string& old_content,
    const std::string& new_content
) {
    std::vector<DiffRange> ranges;
    
    // Simple line-based diff for now
    // In production, would use dtl or similar diff library
    
    size_t old_lines = std::count(old_content.begin(), old_content.end(), '\n');
    size_t new_lines = std::count(new_content.begin(), new_content.end(), '\n');
    
    if (new_lines > old_lines) {
        ranges.push_back({old_lines, new_lines, DiffRange::Added});
    } else if (old_lines > new_lines) {
        ranges.push_back({new_lines, old_lines, DiffRange::Removed});
    }
    
    return ranges;
}

void DiffHighlighter::highlight_changes(
    const std::vector<DiffRange>& ranges,
    std::chrono::milliseconds duration
) {
    // This would trigger visual highlighting in the renderer
    // Animation would be handled by Core Animation
}

} // namespace mdviewer