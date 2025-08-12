#include <gtest/gtest.h>
#include "core/toc_generator.h"
#include "core/document.h"
#include <memory>

namespace mdviewer {

class TOCWidgetTest : public ::testing::Test {
protected:
    void SetUp() override {
        toc_widget = std::make_unique<TOCWidget>();
        document = std::make_unique<Document>();
        createSampleDocument();
    }
    
    void TearDown() override {
        toc_widget.reset();
        document.reset();
    }
    
    void createSampleDocument() {
        auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
        
        // Add some headings
        auto h1 = std::make_unique<Document::Node>(Document::NodeType::Heading);
        h1->content = "Chapter 1: Introduction";
        h1->heading_level = 1;
        root->children.push_back(std::move(h1));
        
        auto p1 = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
        p1->content = "This is the introduction paragraph.";
        root->children.push_back(std::move(p1));
        
        auto h2_1 = std::make_unique<Document::Node>(Document::NodeType::Heading);
        h2_1->content = "Section 1.1: Overview";
        h2_1->heading_level = 2;
        root->children.push_back(std::move(h2_1));
        
        auto p2 = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
        p2->content = "Overview paragraph.";
        root->children.push_back(std::move(p2));
        
        auto h2_2 = std::make_unique<Document::Node>(Document::NodeType::Heading);
        h2_2->content = "Section 1.2: Details";
        h2_2->heading_level = 2;
        root->children.push_back(std::move(h2_2));
        
        auto h3 = std::make_unique<Document::Node>(Document::NodeType::Heading);
        h3->content = "Subsection 1.2.1: Technical Details";
        h3->heading_level = 3;
        root->children.push_back(std::move(h3));
        
        auto h1_2 = std::make_unique<Document::Node>(Document::NodeType::Heading);
        h1_2->content = "Chapter 2: Implementation";
        h1_2->heading_level = 1;
        root->children.push_back(std::move(h1_2));
        
        document->set_root(std::move(root));
        document->regenerate_toc();
    }
    
    std::unique_ptr<TOCWidget> toc_widget;
    std::unique_ptr<Document> document;
};

TEST_F(TOCWidgetTest, Construction) {
    EXPECT_NE(toc_widget.get(), nullptr);
    EXPECT_FALSE(toc_widget->is_visible());
}

TEST_F(TOCWidgetTest, SetDocument) {
    toc_widget->set_document(document.get());
    
    // Document should be set successfully
    // Actual verification depends on implementation details
}

TEST_F(TOCWidgetTest, DefaultConfiguration) {
    TOCWidget::Config default_config;
    
    EXPECT_TRUE(default_config.auto_hide);
    EXPECT_TRUE(default_config.highlight_current);
    EXPECT_FLOAT_EQ(default_config.width, 250.0f);
    EXPECT_FLOAT_EQ(default_config.opacity, 0.95f);
    EXPECT_EQ(default_config.max_depth, 3);
    EXPECT_FALSE(default_config.show_numbers);
}

TEST_F(TOCWidgetTest, CustomConfiguration) {
    TOCWidget::Config config;
    config.auto_hide = false;
    config.highlight_current = false;
    config.width = 300.0f;
    config.opacity = 0.8f;
    config.max_depth = 2;
    config.show_numbers = true;
    
    toc_widget->set_config(config);
    
    // Configuration should be applied
    // Verification depends on whether config can be retrieved
}

TEST_F(TOCWidgetTest, VisibilityToggle) {
    EXPECT_FALSE(toc_widget->is_visible());
    
    toc_widget->toggle_visibility();
    EXPECT_TRUE(toc_widget->is_visible());
    
    toc_widget->toggle_visibility();
    EXPECT_FALSE(toc_widget->is_visible());
}

TEST_F(TOCWidgetTest, NavigationCallback) {
    bool callback_called = false;
    size_t callback_index = 0;
    
    toc_widget->set_navigation_callback([&](size_t index) {
        callback_called = true;
        callback_index = index;
    });
    
    // Set document to enable TOC
    toc_widget->set_document(document.get());
    
    // Simulate navigation (implementation specific)
    // This test may need adjustment based on actual callback trigger
}

TEST_F(TOCWidgetTest, CurrentPositionTracking) {
    toc_widget->set_document(document.get());
    
    // Set various scroll positions
    toc_widget->set_current_position(0.0f);
    toc_widget->set_current_position(100.0f);
    toc_widget->set_current_position(500.0f);
    
    // Position should be tracked internally
    // Verification depends on implementation details
}

TEST_F(TOCWidgetTest, MouseEventHandling) {
    toc_widget->set_document(document.get());
    toc_widget->toggle_visibility(); // Make visible
    
    // Test mouse events
    bool result1 = toc_widget->handle_mouse_event(50.0f, 50.0f, false); // Move
    bool result2 = toc_widget->handle_mouse_event(50.0f, 50.0f, true);  // Click
    
    // Results depend on implementation
    // Should handle events when visible
}

TEST_F(TOCWidgetTest, RenderWhenVisible) {
    toc_widget->set_document(document.get());
    toc_widget->toggle_visibility();
    
    // Should render without crashing when visible
    EXPECT_NO_THROW(toc_widget->render(10.0f, 10.0f));
}

TEST_F(TOCWidgetTest, RenderWhenHidden) {
    toc_widget->set_document(document.get());
    // Keep hidden (default state)
    
    // Should handle render call when hidden
    EXPECT_NO_THROW(toc_widget->render(10.0f, 10.0f));
}

// Test the Document::TableOfContents functionality
class TableOfContentsTest : public ::testing::Test {
protected:
    void SetUp() override {
        document = std::make_unique<Document>();
    }
    
    void TearDown() override {
        document.reset();
    }
    
    std::unique_ptr<Document> document;
};

TEST_F(TableOfContentsTest, EmptyDocument) {
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    document->set_root(std::move(root));
    document->regenerate_toc();
    
    const auto& toc = document->get_toc();
    EXPECT_TRUE(toc.entries.empty());
}

TEST_F(TableOfContentsTest, SingleHeading) {
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    auto heading = std::make_unique<Document::Node>(Document::NodeType::Heading);
    heading->content = "Test Heading";
    heading->heading_level = 1;
    root->children.push_back(std::move(heading));
    
    document->set_root(std::move(root));
    document->regenerate_toc();
    
    const auto& toc = document->get_toc();
    EXPECT_EQ(toc.entries.size(), 1);
    EXPECT_EQ(toc.entries[0].text, "Test Heading");
    EXPECT_EQ(toc.entries[0].level, 1);
}

TEST_F(TableOfContentsTest, NestedHeadings) {
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    // H1
    auto h1 = std::make_unique<Document::Node>(Document::NodeType::Heading);
    h1->content = "Chapter 1";
    h1->heading_level = 1;
    root->children.push_back(std::move(h1));
    
    // H2
    auto h2_1 = std::make_unique<Document::Node>(Document::NodeType::Heading);
    h2_1->content = "Section 1.1";
    h2_1->heading_level = 2;
    root->children.push_back(std::move(h2_1));
    
    // H3
    auto h3 = std::make_unique<Document::Node>(Document::NodeType::Heading);
    h3->content = "Subsection 1.1.1";
    h3->heading_level = 3;
    root->children.push_back(std::move(h3));
    
    // Another H2
    auto h2_2 = std::make_unique<Document::Node>(Document::NodeType::Heading);
    h2_2->content = "Section 1.2";
    h2_2->heading_level = 2;
    root->children.push_back(std::move(h2_2));
    
    document->set_root(std::move(root));
    document->regenerate_toc();
    
    const auto& toc = document->get_toc();
    EXPECT_EQ(toc.entries.size(), 1); // One top-level entry
    
    const auto& chapter1 = toc.entries[0];
    EXPECT_EQ(chapter1.text, "Chapter 1");
    EXPECT_EQ(chapter1.level, 1);
    EXPECT_EQ(chapter1.children.size(), 2); // Two sections
    
    EXPECT_EQ(chapter1.children[0].text, "Section 1.1");
    EXPECT_EQ(chapter1.children[0].level, 2);
    EXPECT_EQ(chapter1.children[0].children.size(), 1); // One subsection
    
    EXPECT_EQ(chapter1.children[0].children[0].text, "Subsection 1.1.1");
    EXPECT_EQ(chapter1.children[0].children[0].level, 3);
    
    EXPECT_EQ(chapter1.children[1].text, "Section 1.2");
    EXPECT_EQ(chapter1.children[1].level, 2);
    EXPECT_TRUE(chapter1.children[1].children.empty());
}

TEST_F(TableOfContentsTest, SkippedHeadingLevels) {
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    // H1
    auto h1 = std::make_unique<Document::Node>(Document::NodeType::Heading);
    h1->content = "Chapter 1";
    h1->heading_level = 1;
    root->children.push_back(std::move(h1));
    
    // Skip H2, go directly to H3
    auto h3 = std::make_unique<Document::Node>(Document::NodeType::Heading);
    h3->content = "Subsection";
    h3->heading_level = 3;
    root->children.push_back(std::move(h3));
    
    document->set_root(std::move(root));
    document->regenerate_toc();
    
    const auto& toc = document->get_toc();
    EXPECT_GE(toc.entries.size(), 1);
    
    // Should handle skipped levels gracefully
    // Exact behavior depends on implementation
}

TEST_F(TableOfContentsTest, NonHeadingNodes) {
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    // Mix of headings and other nodes
    auto para = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    para->content = "Some paragraph";
    root->children.push_back(std::move(para));
    
    auto heading = std::make_unique<Document::Node>(Document::NodeType::Heading);
    heading->content = "Important Heading";
    heading->heading_level = 1;
    root->children.push_back(std::move(heading));
    
    auto code = std::make_unique<Document::Node>(Document::NodeType::CodeBlock);
    code->content = "console.log('hello');";
    root->children.push_back(std::move(code));
    
    document->set_root(std::move(root));
    document->regenerate_toc();
    
    const auto& toc = document->get_toc();
    EXPECT_EQ(toc.entries.size(), 1); // Only the heading should appear
    EXPECT_EQ(toc.entries[0].text, "Important Heading");
}

} // namespace mdviewer