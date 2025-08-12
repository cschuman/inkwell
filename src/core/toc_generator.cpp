#include "core/document.h"
#include "core/toc_generator.h"
#include <algorithm>
#include <stack>

namespace mdviewer {

class TOCGenerator {
public:
    static void generate(Document::TableOfContents& toc, const Document::Node* root) {
        toc.entries.clear();
        if (!root) return;
        
        std::stack<Document::TableOfContents::Entry*> entry_stack;
        size_t node_index = 0;
        
        traverse_node(root, toc, entry_stack, node_index);
        
        organize_hierarchy(toc);
    }
    
private:
    static void traverse_node(
        const Document::Node* node,
        Document::TableOfContents& toc,
        std::stack<Document::TableOfContents::Entry*>& entry_stack,
        size_t& node_index
    ) {
        if (node->type == Document::NodeType::Heading && node->heading_level > 0) {
            Document::TableOfContents::Entry entry;
            entry.text = extract_text(node);
            entry.level = node->heading_level;
            entry.node_index = node_index;
            
            // Pop entries from stack until we find parent level
            while (!entry_stack.empty() && entry_stack.top()->level >= entry.level) {
                entry_stack.pop();
            }
            
            if (entry_stack.empty()) {
                toc.entries.push_back(std::move(entry));
                entry_stack.push(&toc.entries.back());
            } else {
                entry_stack.top()->children.push_back(std::move(entry));
                entry_stack.push(&entry_stack.top()->children.back());
            }
        }
        
        for (const auto& child : node->children) {
            traverse_node(child.get(), toc, entry_stack, ++node_index);
        }
    }
    
    static std::string extract_text(const Document::Node* node) {
        std::string text;
        extract_text_recursive(node, text);
        return text;
    }
    
    static void extract_text_recursive(const Document::Node* node, std::string& text) {
        if (node->type == Document::NodeType::Text) {
            text += node->content;
        }
        
        for (const auto& child : node->children) {
            extract_text_recursive(child.get(), text);
        }
    }
    
    static void organize_hierarchy(Document::TableOfContents& toc) {
        std::vector<Document::TableOfContents::Entry> organized;
        
        for (auto& entry : toc.entries) {
            if (entry.level == 1) {
                organized.push_back(std::move(entry));
            } else {
                // Find appropriate parent
                auto* parent = find_parent_entry(organized, entry.level);
                if (parent) {
                    parent->children.push_back(std::move(entry));
                } else {
                    organized.push_back(std::move(entry));
                }
            }
        }
        
        toc.entries = std::move(organized);
    }
    
    static Document::TableOfContents::Entry* find_parent_entry(
        std::vector<Document::TableOfContents::Entry>& entries,
        int child_level
    ) {
        for (auto it = entries.rbegin(); it != entries.rend(); ++it) {
            if (it->level < child_level) {
                return &(*it);
            }
            
            auto* nested_parent = find_parent_entry(it->children, child_level);
            if (nested_parent) {
                return nested_parent;
            }
        }
        return nullptr;
    }
};

void Document::TableOfContents::generate(const Node* root) {
    TOCGenerator::generate(*this, root);
}

void Document::regenerate_toc() {
    toc_.generate(root_.get());
}

} // namespace mdviewer