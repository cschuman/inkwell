#pragma once

#include <memory>
#include <atomic>
#include <vector>
#include <functional>
#include "core/document.h"

namespace mdviewer {

class VirtualDOM {
public:
    struct DOMNode {
        Document::NodeType type;
        std::string content;
        std::vector<std::shared_ptr<DOMNode>> children;
        
        // Layout information
        float x = 0, y = 0;
        float width = 0, height = 0;
        bool needs_layout = true;
        
        // Rendering state
        bool visible = false;
        bool dirty = true;
        
        std::atomic<uint64_t> version{0};
    };
    
    using UpdateCallback = std::function<void(const DOMNode&)>;
    
    VirtualDOM();
    ~VirtualDOM();
    
    void update(const Document* doc);
    
    void update_incremental(const Document::Node* node, size_t index);
    
    void mark_dirty(const DOMNode* node);
    
    void set_viewport(float y, float height);
    
    std::vector<const DOMNode*> get_visible_nodes() const;
    
    void register_update_callback(UpdateCallback callback);
    
    const DOMNode* get_root() const { return root_.get(); }
    
private:
    std::shared_ptr<DOMNode> root_;
    std::atomic<uint64_t> global_version_{0};
    
    struct Viewport {
        std::atomic<float> y{0};
        std::atomic<float> height{0};
    } viewport_;
    
    std::vector<UpdateCallback> update_callbacks_;
    
    std::shared_ptr<DOMNode> create_dom_node(const Document::Node* doc_node);
    void update_visibility(DOMNode* node);
    void notify_updates(const DOMNode& node);
    
    // RCU pattern for lock-free updates
    template<typename T>
    class RCUPointer {
        std::atomic<T*> ptr_;
    public:
        void update(T* new_ptr);
        T* read() const;
    };
};

} // namespace mdviewer