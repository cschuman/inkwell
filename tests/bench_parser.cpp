#include <benchmark/benchmark.h>
#include "core/markdown_parser.h"
#include "core/document.h"
#include <random>
#include <sstream>

using namespace mdviewer;

static std::string generate_markdown(size_t paragraphs, size_t words_per_paragraph) {
    std::stringstream ss;
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> word_len(3, 12);
    
    const std::string chars = "abcdefghijklmnopqrstuvwxyz";
    
    for (size_t p = 0; p < paragraphs; ++p) {
        if (p % 10 == 0) {
            ss << "# Heading " << p / 10 << "\n\n";
        }
        
        for (size_t w = 0; w < words_per_paragraph; ++w) {
            int len = word_len(gen);
            for (int i = 0; i < len; ++i) {
                ss << chars[gen() % chars.size()];
            }
            
            if (w < words_per_paragraph - 1) {
                ss << " ";
            }
        }
        ss << "\n\n";
    }
    
    return ss.str();
}

static void BM_ParseSmallDocument(benchmark::State& state) {
    MarkdownParser parser;
    std::string markdown = "# Title\n\nThis is a paragraph with some text.\n\n- List item 1\n- List item 2";
    
    for (auto _ : state) {
        auto doc = parser.parse(markdown);
        benchmark::DoNotOptimize(doc);
    }
    
    state.SetBytesProcessed(state.iterations() * markdown.size());
}
BENCHMARK(BM_ParseSmallDocument);

static void BM_ParseMediumDocument(benchmark::State& state) {
    MarkdownParser parser;
    std::string markdown = generate_markdown(100, 50);
    
    for (auto _ : state) {
        auto doc = parser.parse(markdown);
        benchmark::DoNotOptimize(doc);
    }
    
    state.SetBytesProcessed(state.iterations() * markdown.size());
}
BENCHMARK(BM_ParseMediumDocument);

static void BM_ParseLargeDocument(benchmark::State& state) {
    MarkdownParser parser;
    std::string markdown = generate_markdown(1000, 100);
    
    for (auto _ : state) {
        auto doc = parser.parse(markdown);
        benchmark::DoNotOptimize(doc);
    }
    
    state.SetBytesProcessed(state.iterations() * markdown.size());
    state.SetLabel("Size: " + std::to_string(markdown.size() / 1024) + " KB");
}
BENCHMARK(BM_ParseLargeDocument);

static void BM_Parse10MBDocument(benchmark::State& state) {
    MarkdownParser parser;
    std::string markdown;
    
    // Generate approximately 10MB of markdown
    while (markdown.size() < 10 * 1024 * 1024) {
        markdown += generate_markdown(100, 100);
    }
    
    for (auto _ : state) {
        auto doc = parser.parse(markdown);
        benchmark::DoNotOptimize(doc);
    }
    
    state.SetBytesProcessed(state.iterations() * markdown.size());
    state.SetLabel("Size: " + std::to_string(markdown.size() / (1024 * 1024)) + " MB");
}
BENCHMARK(BM_Parse10MBDocument)->Unit(benchmark::kMillisecond);

static void BM_WikilinkDetection(benchmark::State& state) {
    MarkdownParser parser;
    std::string text = "This text has [[many]] different [[wiki links]] scattered [[throughout]] the [[document]] for testing.";
    
    // Add more wikilinks
    for (int i = 0; i < 100; ++i) {
        text += " More text with [[link" + std::to_string(i) + "]] included.";
    }
    
    for (auto _ : state) {
        std::vector<Document::Link> links;
        parser.detect_wikilinks(text, links);
        benchmark::DoNotOptimize(links);
    }
    
    state.SetBytesProcessed(state.iterations() * text.size());
}
BENCHMARK(BM_WikilinkDetection);

static void BM_WikilinkDetectionLarge(benchmark::State& state) {
    MarkdownParser parser;
    std::string text;
    
    // Generate text with many wikilinks
    for (int i = 0; i < 10000; ++i) {
        text += "Some text with [[link" + std::to_string(i) + "]] and more content. ";
    }
    
    for (auto _ : state) {
        std::vector<Document::Link> links;
        parser.detect_wikilinks(text, links);
        benchmark::DoNotOptimize(links);
    }
    
    state.SetBytesProcessed(state.iterations() * text.size());
    state.SetLabel("Links found: ~10000");
}
BENCHMARK(BM_WikilinkDetectionLarge)->Unit(benchmark::kMillisecond);

static void BM_WordCount(benchmark::State& state) {
    MarkdownParser parser;
    std::string markdown = generate_markdown(100, 100);
    auto doc = parser.parse(markdown);
    
    for (auto _ : state) {
        auto count = doc->word_count();
        benchmark::DoNotOptimize(count);
    }
    
    state.SetItemsProcessed(state.iterations() * doc->word_count());
}
BENCHMARK(BM_WordCount);

static void BM_WordCountLarge(benchmark::State& state) {
    MarkdownParser parser;
    std::string markdown = generate_markdown(1000, 200);
    auto doc = parser.parse(markdown);
    
    for (auto _ : state) {
        auto count = doc->word_count();
        benchmark::DoNotOptimize(count);
    }
    
    state.SetItemsProcessed(state.iterations() * doc->word_count());
    state.SetLabel("Words: ~" + std::to_string(doc->word_count()));
}
BENCHMARK(BM_WordCountLarge);

static void BM_TOCGeneration(benchmark::State& state) {
    MarkdownParser parser;
    
    std::stringstream ss;
    for (int i = 0; i < 100; ++i) {
        ss << "# Chapter " << i << "\n";
        for (int j = 0; j < 5; ++j) {
            ss << "## Section " << i << "." << j << "\n";
            ss << "Some content here.\n\n";
        }
    }
    
    auto doc = parser.parse(ss.str());
    
    for (auto _ : state) {
        doc->regenerate_toc();
        benchmark::DoNotOptimize(doc->get_toc());
    }
    
    state.SetItemsProcessed(state.iterations() * 100 * 6); // 100 chapters + 500 sections
}
BENCHMARK(BM_TOCGeneration);

static void BM_IncrementalParsing(benchmark::State& state) {
    MarkdownParser parser;
    std::string markdown = generate_markdown(50, 30);
    
    int callback_count = 0;
    auto callback = [&callback_count](const Document::Node& node) {
        callback_count++;
    };
    
    for (auto _ : state) {
        callback_count = 0;
        parser.parse_incremental(markdown, callback);
        benchmark::DoNotOptimize(callback_count);
    }
    
    state.SetBytesProcessed(state.iterations() * markdown.size());
}
BENCHMARK(BM_IncrementalParsing);

static void BM_ParseWithTables(benchmark::State& state) {
    MarkdownParser parser;
    parser.enable_tables(true);
    
    std::stringstream ss;
    for (int i = 0; i < 50; ++i) {
        ss << "| Header 1 | Header 2 | Header 3 |\n";
        ss << "|----------|----------|----------|\n";
        for (int j = 0; j < 10; ++j) {
            ss << "| Cell " << j << ",1 | Cell " << j << ",2 | Cell " << j << ",3 |\n";
        }
        ss << "\n";
    }
    
    std::string markdown = ss.str();
    
    for (auto _ : state) {
        auto doc = parser.parse(markdown);
        benchmark::DoNotOptimize(doc);
    }
    
    state.SetBytesProcessed(state.iterations() * markdown.size());
    state.SetLabel("Tables: 50, Cells: 1500");
}
BENCHMARK(BM_ParseWithTables);

static void BM_ParseCodeBlocks(benchmark::State& state) {
    MarkdownParser parser;
    
    std::stringstream ss;
    for (int i = 0; i < 100; ++i) {
        ss << "```cpp\n";
        ss << "#include <iostream>\n";
        ss << "int main() {\n";
        ss << "    std::cout << \"Hello, World " << i << "!\" << std::endl;\n";
        ss << "    return 0;\n";
        ss << "}\n";
        ss << "```\n\n";
    }
    
    std::string markdown = ss.str();
    
    for (auto _ : state) {
        auto doc = parser.parse(markdown);
        benchmark::DoNotOptimize(doc);
    }
    
    state.SetBytesProcessed(state.iterations() * markdown.size());
}
BENCHMARK(BM_ParseCodeBlocks);

BENCHMARK_MAIN();