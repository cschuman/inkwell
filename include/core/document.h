#pragma once

#include <string>
#include <vector>
#include <memory>
#include <variant>
#include <optional>
#include <string_view>
#include <functional>

namespace mdviewer {

class Document {
public:
    enum class NodeType {
        Paragraph,
        Heading,
        CodeBlock,
        BlockQuote,
        List,
        ListItem,
        Table,
        TableRow,
        TableCell,
        HorizontalRule,
        Image,
        Link,
        Emphasis,
        Strong,
        Code,
        Text,
        LineBreak,
        Html,
        Strikethrough
    };
    
    struct Node {
        NodeType type;
        std::string content;
        std::vector<std::unique_ptr<Node>> children;
        
        // Metadata
        int heading_level = 0;
        std::string code_language;
        std::string link_url;
        std::string image_alt;
        bool list_ordered = false;
        int list_start = 1;
        
        // Position in source
        size_t source_start = 0;
        size_t source_end = 0;
        
        Node(NodeType t) : type(t) {}
        Node(NodeType t, std::string_view text) : type(t), content(text) {}
    };
    
    struct Link {
        std::string text;
        std::string url;
        size_t position;
        bool is_wikilink = false;
    };
    
    struct TableOfContents {
        struct Entry {
            std::string text;
            int level;
            size_t node_index;
            std::vector<Entry> children;
        };
        
        std::vector<Entry> entries;
        
        void generate(const Node* root);
    };
    
    Document();
    ~Document();
    
    void set_root(std::unique_ptr<Node> root);
    const Node* get_root() const { return root_.get(); }
    Node* get_root() { return root_.get(); }
    
    const TableOfContents& get_toc() const { return toc_; }
    void regenerate_toc();
    
    size_t word_count() const;
    size_t character_count() const;
    std::vector<Link> extract_links() const;
    
    void visit(std::function<void(const Node&)> visitor) const;
    
private:
    std::unique_ptr<Node> root_;
    TableOfContents toc_;
    mutable std::optional<size_t> cached_word_count_;
    mutable std::optional<size_t> cached_char_count_;
    
    void visit_impl(const Node* node, std::function<void(const Node&)>& visitor) const;
    size_t count_words_simd(std::string_view text) const;
};

} // namespace mdviewer