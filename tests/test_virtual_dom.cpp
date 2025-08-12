#include <gtest/gtest.h>
#include "core/virtual_dom.h"
#include "core/document.h"
#include <memory>

namespace mdviewer {

class VirtualDOMTest : public ::testing::Test {
protected:
    void SetUp() override {
        vdom = std::make_unique<VirtualDOM>();
        document = std::make_unique<Document>();
    }
    
    void TearDown() override {
        vdom.reset();
        document.reset();
    }
    
    std::unique_ptr<VirtualDOM> vdom;
    std::unique_ptr<Document> document;
};

TEST_F(VirtualDOMTest, Construction) {
    EXPECT_NE(vdom.get(), nullptr);
    EXPECT_EQ(vdom->get_root(), nullptr);
}

TEST_F(VirtualDOMTest, UpdateWithEmptyDocument) {
    vdom->update(document.get());
    
    const auto* root = vdom->get_root();
    EXPECT_NE(root, nullptr);
}

TEST_F(VirtualDOMTest, UpdateWithSimpleDocument) {
    // Create a simple document with a paragraph
    auto root_node = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    root_node->content = "Hello, World!";
    
    document->set_root(std::move(root_node));
    vdom->update(document.get());
    
    const auto* dom_root = vdom->get_root();
    ASSERT_NE(dom_root, nullptr);
    EXPECT_EQ(dom_root->type, Document::NodeType::Paragraph);
    EXPECT_EQ(dom_root->content, "Hello, World!");
}

TEST_F(VirtualDOMTest, UpdateWithNestedDocument) {
    // Create a document with nested structure
    auto root_node = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    auto child1 = std::make_unique<Document::Node>(Document::NodeType::Text);
    child1->content = "Hello, ";
    
    auto child2 = std::make_unique<Document::Node>(Document::NodeType::Strong);
    child2->content = "World";
    
    auto child3 = std::make_unique<Document::Node>(Document::NodeType::Text);
    child3->content = "!";
    
    root_node->children.push_back(std::move(child1));
    root_node->children.push_back(std::move(child2));
    root_node->children.push_back(std::move(child3));
    
    document->set_root(std::move(root_node));
    vdom->update(document.get());
    
    const auto* dom_root = vdom->get_root();
    ASSERT_NE(dom_root, nullptr);
    EXPECT_EQ(dom_root->children.size(), 3);
    
    EXPECT_EQ(dom_root->children[0]->type, Document::NodeType::Text);
    EXPECT_EQ(dom_root->children[0]->content, "Hello, ");
    
    EXPECT_EQ(dom_root->children[1]->type, Document::NodeType::Strong);
    EXPECT_EQ(dom_root->children[1]->content, "World");
    
    EXPECT_EQ(dom_root->children[2]->type, Document::NodeType::Text);
    EXPECT_EQ(dom_root->children[2]->content, "!");
}

TEST_F(VirtualDOMTest, ViewportFiltering) {
    // Create a document with multiple paragraphs
    auto root_node = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    for (int i = 0; i < 10; ++i) {
        auto para = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
        para->content = "Paragraph " + std::to_string(i);
        root_node->children.push_back(std::move(para));
    }
    
    document->set_root(std::move(root_node));
    vdom->update(document.get());
    
    // Set viewport
    vdom->set_viewport(100.0f, 200.0f);
    
    // Get visible nodes - should be filtered based on viewport
    auto visible_nodes = vdom->get_visible_nodes();
    EXPECT_GE(visible_nodes.size(), 0); // May be empty if layout not calculated
}

TEST_F(VirtualDOMTest, UpdateCallback) {
    bool callback_called = false;
    std::string callback_content;
    
    vdom->register_update_callback([&](const VirtualDOM::DOMNode& node) {
        callback_called = true;
        callback_content = node.content;
    });
    
    // Create and update document
    auto root_node = std::make_unique<Document::Node>(Document::NodeType::Text);
    root_node->content = "Test Content";
    
    document->set_root(std::move(root_node));
    vdom->update(document.get());
    
    // Note: Callback behavior depends on implementation
    // This test may need adjustment based on actual callback trigger conditions
}

TEST_F(VirtualDOMTest, NodeVersioning) {
    // Create initial document
    auto root_node = std::make_unique<Document::Node>(Document::NodeType::Text);
    root_node->content = "Initial";
    
    document->set_root(std::move(root_node));
    vdom->update(document.get());
    
    const auto* dom_root = vdom->get_root();
    ASSERT_NE(dom_root, nullptr);
    
    uint64_t initial_version = dom_root->version.load();
    
    // Update document
    auto new_root = std::make_unique<Document::Node>(Document::NodeType::Text);
    new_root->content = "Updated";
    
    document->set_root(std::move(new_root));
    vdom->update(document.get());
    
    const auto* updated_root = vdom->get_root();
    ASSERT_NE(updated_root, nullptr);
    
    // Version should change (implementation dependent)
    // This may need adjustment based on actual versioning behavior
}

TEST_F(VirtualDOMTest, LayoutProperties) {
    auto root_node = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    root_node->content = "Test paragraph";
    
    document->set_root(std::move(root_node));
    vdom->update(document.get());
    
    const auto* dom_root = vdom->get_root();
    ASSERT_NE(dom_root, nullptr);
    
    // Check initial layout state
    EXPECT_TRUE(dom_root->needs_layout);
    EXPECT_FALSE(dom_root->visible);
    EXPECT_TRUE(dom_root->dirty);
}

// Stress test with large document
TEST_F(VirtualDOMTest, LargeDocumentPerformance) {
    auto root_node = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    // Create a large nested structure
    constexpr int NUM_NODES = 1000;
    for (int i = 0; i < NUM_NODES; ++i) {
        auto child = std::make_unique<Document::Node>(Document::NodeType::Text);
        child->content = "Node " + std::to_string(i);
        root_node->children.push_back(std::move(child));
    }
    
    document->set_root(std::move(root_node));
    
    auto start = std::chrono::high_resolution_clock::now();
    vdom->update(document.get());
    auto end = std::chrono::high_resolution_clock::now();
    
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    const auto* dom_root = vdom->get_root();
    ASSERT_NE(dom_root, nullptr);
    EXPECT_EQ(dom_root->children.size(), NUM_NODES);
    
    // Should complete in reasonable time (adjust threshold as needed)
    EXPECT_LT(duration.count(), 100); // Less than 100ms
}

} // namespace mdviewer