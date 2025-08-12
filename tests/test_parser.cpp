#include <gtest/gtest.h>
#include "core/markdown_parser.h"
#include "core/document.h"

using namespace mdviewer;

class MarkdownParserTest : public ::testing::Test {
protected:
    std::unique_ptr<MarkdownParser> parser;
    
    void SetUp() override {
        parser = std::make_unique<MarkdownParser>();
    }
};

TEST_F(MarkdownParserTest, ParseSimpleParagraph) {
    std::string markdown = "This is a simple paragraph.";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    ASSERT_NE(doc->get_root(), nullptr);
    
    const auto* root = doc->get_root();
    ASSERT_EQ(root->type, Document::NodeType::Paragraph);
    ASSERT_EQ(root->children.size(), 1);
    ASSERT_EQ(root->children[0]->type, Document::NodeType::Text);
    ASSERT_EQ(root->children[0]->content, "This is a simple paragraph.");
}

TEST_F(MarkdownParserTest, ParseHeadings) {
    std::string markdown = "# Heading 1\n## Heading 2\n### Heading 3";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    int heading_count = 0;
    doc->visit([&heading_count](const Document::Node& node) {
        if (node.type == Document::NodeType::Heading) {
            heading_count++;
        }
    });
    
    EXPECT_EQ(heading_count, 3);
}

TEST_F(MarkdownParserTest, ParseCodeBlock) {
    std::string markdown = "```cpp\nint main() {\n    return 0;\n}\n```";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    bool found_code_block = false;
    doc->visit([&found_code_block](const Document::Node& node) {
        if (node.type == Document::NodeType::CodeBlock) {
            found_code_block = true;
            EXPECT_EQ(node.code_language, "cpp");
        }
    });
    
    EXPECT_TRUE(found_code_block);
}

TEST_F(MarkdownParserTest, ParseList) {
    std::string markdown = "- Item 1\n- Item 2\n- Item 3";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    int list_item_count = 0;
    doc->visit([&list_item_count](const Document::Node& node) {
        if (node.type == Document::NodeType::ListItem) {
            list_item_count++;
        }
    });
    
    EXPECT_EQ(list_item_count, 3);
}

TEST_F(MarkdownParserTest, ParseOrderedList) {
    std::string markdown = "1. First\n2. Second\n3. Third";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    bool found_ordered_list = false;
    doc->visit([&found_ordered_list](const Document::Node& node) {
        if (node.type == Document::NodeType::List) {
            found_ordered_list = node.list_ordered;
        }
    });
    
    EXPECT_TRUE(found_ordered_list);
}

TEST_F(MarkdownParserTest, ParseEmphasis) {
    std::string markdown = "This is *italic* and **bold** text.";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    bool found_emphasis = false;
    bool found_strong = false;
    
    doc->visit([&](const Document::Node& node) {
        if (node.type == Document::NodeType::Emphasis) {
            found_emphasis = true;
        }
        if (node.type == Document::NodeType::Strong) {
            found_strong = true;
        }
    });
    
    EXPECT_TRUE(found_emphasis);
    EXPECT_TRUE(found_strong);
}

TEST_F(MarkdownParserTest, ParseLinks) {
    std::string markdown = "[Link text](https://example.com)";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    auto links = doc->extract_links();
    ASSERT_EQ(links.size(), 1);
    EXPECT_EQ(links[0].text, "Link text");
    EXPECT_EQ(links[0].url, "https://example.com");
}

TEST_F(MarkdownParserTest, ParseWikiLinks) {
    std::string markdown = "This is a [[wiki link]] in text.";
    
    std::vector<Document::Link> links;
    parser->detect_wikilinks(markdown, links);
    
    ASSERT_EQ(links.size(), 1);
    EXPECT_EQ(links[0].text, "wiki link");
    EXPECT_TRUE(links[0].is_wikilink);
}

TEST_F(MarkdownParserTest, ParseTable) {
    std::string markdown = R"(
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
)";
    
    parser->enable_tables(true);
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    int table_cell_count = 0;
    doc->visit([&table_cell_count](const Document::Node& node) {
        if (node.type == Document::NodeType::TableCell) {
            table_cell_count++;
        }
    });
    
    EXPECT_GT(table_cell_count, 0);
}

TEST_F(MarkdownParserTest, ParseBlockquote) {
    std::string markdown = "> This is a quote\n> with multiple lines";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    bool found_blockquote = false;
    doc->visit([&found_blockquote](const Document::Node& node) {
        if (node.type == Document::NodeType::BlockQuote) {
            found_blockquote = true;
        }
    });
    
    EXPECT_TRUE(found_blockquote);
}

TEST_F(MarkdownParserTest, ParseHorizontalRule) {
    std::string markdown = "Text above\n\n---\n\nText below";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    bool found_hr = false;
    doc->visit([&found_hr](const Document::Node& node) {
        if (node.type == Document::NodeType::HorizontalRule) {
            found_hr = true;
        }
    });
    
    EXPECT_TRUE(found_hr);
}

TEST_F(MarkdownParserTest, ParseInlineCode) {
    std::string markdown = "Use `code` in text";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    
    bool found_code = false;
    doc->visit([&found_code](const Document::Node& node) {
        if (node.type == Document::NodeType::Code) {
            found_code = true;
            EXPECT_EQ(node.content, "code");
        }
    });
    
    EXPECT_TRUE(found_code);
}

TEST_F(MarkdownParserTest, WordCount) {
    std::string markdown = "This is a test document with exactly eight words.";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    EXPECT_EQ(doc->word_count(), 9);
}

TEST_F(MarkdownParserTest, CharacterCount) {
    std::string markdown = "Hello";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    EXPECT_EQ(doc->character_count(), 5);
}

TEST_F(MarkdownParserTest, TableOfContentsGeneration) {
    std::string markdown = R"(
# Chapter 1
## Section 1.1
### Subsection 1.1.1
## Section 1.2
# Chapter 2
## Section 2.1
)";
    
    auto doc = parser->parse(markdown);
    ASSERT_NE(doc, nullptr);
    
    const auto& toc = doc->get_toc();
    EXPECT_EQ(toc.entries.size(), 2); // Two chapters
    EXPECT_EQ(toc.entries[0].children.size(), 2); // Two sections in chapter 1
    EXPECT_EQ(toc.entries[0].children[0].children.size(), 1); // One subsection
}

TEST_F(MarkdownParserTest, ParseEmptyDocument) {
    std::string markdown = "";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    EXPECT_EQ(doc->word_count(), 0);
    EXPECT_EQ(doc->character_count(), 0);
}

TEST_F(MarkdownParserTest, ParseLargeDocument) {
    // Generate a large document
    std::string markdown;
    for (int i = 0; i < 1000; ++i) {
        markdown += "# Heading " + std::to_string(i) + "\n";
        markdown += "This is paragraph " + std::to_string(i) + " with some text.\n\n";
    }
    
    auto doc = parser->parse(markdown);
    ASSERT_NE(doc, nullptr);
    
    int heading_count = 0;
    doc->visit([&heading_count](const Document::Node& node) {
        if (node.type == Document::NodeType::Heading) {
            heading_count++;
        }
    });
    
    EXPECT_EQ(heading_count, 1000);
}

TEST_F(MarkdownParserTest, GithubExtensions) {
    parser->enable_github_extensions(true);
    
    std::string markdown = "~~strikethrough~~ text";
    auto doc = parser->parse(markdown);
    
    ASSERT_NE(doc, nullptr);
    // Strikethrough would be parsed with GitHub extensions enabled
}

TEST_F(MarkdownParserTest, IncrementalParsing) {
    std::string markdown = "# Title\nParagraph text";
    
    int callback_count = 0;
    parser->parse_incremental(markdown, [&callback_count](const Document::Node& node) {
        if (node.type == Document::NodeType::Text) {
            callback_count++;
        }
    });
    
    EXPECT_GT(callback_count, 0);
}