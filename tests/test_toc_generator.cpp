#include <gtest/gtest.h>
#include "core/toc_generator.h"
#include <memory>
#include <string>

namespace mdviewer {

class TOCGeneratorTest : public ::testing::Test {
protected:
    void SetUp() override {
        generator = std::make_unique<TOCGenerator>();
    }
    
    std::unique_ptr<TOCGenerator> generator;
};

TEST_F(TOCGeneratorTest, EmptyDocument) {
    auto toc = generator->generate("");
    EXPECT_TRUE(toc.items.empty());
}

TEST_F(TOCGeneratorTest, SingleHeading) {
    std::string markdown = "# Title\n\nContent here.";
    auto toc = generator->generate(markdown);
    
    ASSERT_EQ(toc.items.size(), 1);
    EXPECT_EQ(toc.items[0].title, "Title");
    EXPECT_EQ(toc.items[0].level, 1);
}

TEST_F(TOCGeneratorTest, MultipleHeadings) {
    std::string markdown = R"(
# Chapter 1
Some text
## Section 1.1
More text
## Section 1.2
Even more text
# Chapter 2
Final text
)";
    
    auto toc = generator->generate(markdown);
    
    ASSERT_EQ(toc.items.size(), 4);
    EXPECT_EQ(toc.items[0].title, "Chapter 1");
    EXPECT_EQ(toc.items[0].level, 1);
    EXPECT_EQ(toc.items[1].title, "Section 1.1");
    EXPECT_EQ(toc.items[1].level, 2);
    EXPECT_EQ(toc.items[2].title, "Section 1.2");
    EXPECT_EQ(toc.items[2].level, 2);
    EXPECT_EQ(toc.items[3].title, "Chapter 2");
    EXPECT_EQ(toc.items[3].level, 1);
}

TEST_F(TOCGeneratorTest, NestedHeadings) {
    std::string markdown = R"(
# H1
## H2
### H3
#### H4
##### H5
###### H6
)";
    
    auto toc = generator->generate(markdown);
    
    ASSERT_EQ(toc.items.size(), 6);
    for (int i = 0; i < 6; ++i) {
        EXPECT_EQ(toc.items[i].level, i + 1);
    }
}

TEST_F(TOCGeneratorTest, HeadingsWithSpecialCharacters) {
    std::string markdown = R"(
# Title with **bold** text
## Section with `code`
### Heading with [link](url)
)";
    
    auto toc = generator->generate(markdown);
    
    ASSERT_EQ(toc.items.size(), 3);
    EXPECT_EQ(toc.items[0].title, "Title with bold text");
    EXPECT_EQ(toc.items[1].title, "Section with code");
    EXPECT_EQ(toc.items[2].title, "Heading with link");
}

} // namespace mdviewer