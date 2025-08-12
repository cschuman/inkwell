#include "core/virtual_dom.h"
#include <algorithm>

namespace mdviewer {

VirtualDOM::VirtualDOM() {
    root_ = std::make_shared<DOMNode>();
}

VirtualDOM::~VirtualDOM() = default;

void VirtualDOM::update(const Document* doc) {
    if (!doc || !doc->get_root()) return;
    
    auto new_root = create_dom_node(doc->get_root());
    
    // RCU update pattern for lock-free read access
    std::atomic_store(&root_, new_root);
    global_version_.fetch_add(1, std::memory_order_release);
    
    // Update visibility based on current viewport
    update_visibility(new_root.get());
    
    // Notify callbacks
    notify_updates(*new_root);
}

void VirtualDOM::update_incremental(const Document::Node* node, size_t index) {
    if (!node || !root_) return;
    
    // Find the corresponding DOM node and update it
    // This would traverse the DOM tree to find the node at the given index
    // For now, we'll do a full update
    global_version_.fetch_add(1, std::memory_order_release);
}

std::shared_ptr<VirtualDOM::DOMNode> VirtualDOM::create_dom_node(const Document::Node* doc_node) {
    auto dom_node = std::make_shared<DOMNode>();
    dom_node->type = doc_node->type;
    dom_node->content = doc_node->content;
    
    for (const auto& child : doc_node->children) {
        dom_node->children.push_back(create_dom_node(child.get()));
    }
    
    return dom_node;
}

void VirtualDOM::mark_dirty(const DOMNode* node) {
    if (!node) return;
    
    // const_cast is safe here as we're only modifying the dirty flag
    const_cast<DOMNode*>(node)->dirty = true;
    const_cast<DOMNode*>(node)->version.fetch_add(1, std::memory_order_release);
}

void VirtualDOM::set_viewport(float y, float height) {
    viewport_.y.store(y, std::memory_order_release);
    viewport_.height.store(height, std::memory_order_release);
    
    // Update visibility for all nodes
    if (root_) {
        update_visibility(root_.get());
    }
}

void VirtualDOM::update_visibility(DOMNode* node) {
    if (!node) return;
    
    float viewport_y = viewport_.y.load(std::memory_order_acquire);
    float viewport_height = viewport_.height.load(std::memory_order_acquire);
    
    // Check if node is within viewport
    bool was_visible = node->visible;
    node->visible = (node->y + node->height >= viewport_y) && 
                   (node->y <= viewport_y + viewport_height);
    
    // Mark as dirty if visibility changed
    if (was_visible != node->visible) {
        node->dirty = true;
    }
    
    // Recursively update children
    for (auto& child : node->children) {
        update_visibility(child.get());
    }
}

std::vector<const VirtualDOM::DOMNode*> VirtualDOM::get_visible_nodes() const {
    std::vector<const DOMNode*> visible;
    
    if (!root_) return visible;
    
    std::function<void(const DOMNode*)> collect_visible = [&visible, &collect_visible](const DOMNode* node) {
        if (node->visible) {
            visible.push_back(node);
        }
        
        for (const auto& child : node->children) {
            collect_visible(child.get());
        }
    };
    
    collect_visible(root_.get());
    
    return visible;
}

void VirtualDOM::register_update_callback(UpdateCallback callback) {
    update_callbacks_.push_back(std::move(callback));
}

void VirtualDOM::notify_updates(const DOMNode& node) {
    for (const auto& callback : update_callbacks_) {
        callback(node);
    }
}

// RCU pattern implementation
template<typename T>
void VirtualDOM::RCUPointer<T>::update(T* new_ptr) {
    T* old_ptr = ptr_.exchange(new_ptr);
    
    // Simple deletion - in production would need hazard pointers or similar
    delete old_ptr;
}

template<typename T>
T* VirtualDOM::RCUPointer<T>::read() const {
    return ptr_.load();
}

} // namespace mdviewer