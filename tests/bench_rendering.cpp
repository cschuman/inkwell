#include <benchmark/benchmark.h>
#include "core/virtual_dom.h"
#include "core/document.h"
#include "rendering/render_engine.h"
#include "rendering/text_layout.h"
#include "rendering/glyph_atlas.h"
#include <memory>
#include <random>

namespace mdviewer {

// Helper function to create a large document
std::unique_ptr<Document> create_large_document(size_t num_paragraphs, size_t words_per_paragraph) {
    auto document = std::make_unique<Document>();
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> word_length_dist(3, 10);
    
    for (size_t p = 0; p < num_paragraphs; ++p) {
        auto para = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
        
        std::string content;
        for (size_t w = 0; w < words_per_paragraph; ++w) {
            if (w > 0) content += " ";
            
            // Generate random word
            int length = word_length_dist(gen);
            for (int i = 0; i < length; ++i) {
                content += static_cast<char>('a' + (gen() % 26));
            }
        }
        
        para->content = content;
        root->children.push_back(std::move(para));
    }
    
    document->set_root(std::move(root));
    return document;
}

// Helper function to create a document with various node types
std::unique_ptr<Document> create_mixed_document(size_t complexity) {
    auto document = std::make_unique<Document>();
    auto root = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
    
    for (size_t i = 0; i < complexity; ++i) {
        // Add headings
        if (i % 10 == 0) {
            auto heading = std::make_unique<Document::Node>(Document::NodeType::Heading);
            heading->content = "Heading " + std::to_string(i / 10 + 1);
            heading->heading_level = (i / 10) % 3 + 1;
            root->children.push_back(std::move(heading));
        }
        
        // Add paragraphs
        auto para = std::make_unique<Document::Node>(Document::NodeType::Paragraph);
        para->content = "This is paragraph " + std::to_string(i) + " with some sample text content.";
        root->children.push_back(std::move(para));
        
        // Add code blocks occasionally
        if (i % 15 == 0) {
            auto code = std::make_unique<Document::Node>(Document::NodeType::CodeBlock);
            code->content = "function example() {\n    return " + std::to_string(i) + ";\n}";
            code->code_language = "javascript";
            root->children.push_back(std::move(code));
        }
        
        // Add lists occasionally
        if (i % 20 == 0) {
            auto list = std::make_unique<Document::Node>(Document::NodeType::List);
            for (int j = 0; j < 3; ++j) {
                auto item = std::make_unique<Document::Node>(Document::NodeType::ListItem);
                item->content = "List item " + std::to_string(j + 1);
                list->children.push_back(std::move(item));
            }
            root->children.push_back(std::move(list));
        }
    }
    
    document->set_root(std::move(root));
    return document;
}

// Benchmark Virtual DOM updates
static void BM_VirtualDOM_Update_Small(benchmark::State& state) {
    auto document = create_large_document(10, 20);
    auto vdom = std::make_unique<VirtualDOM>();
    
    for (auto _ : state) {
        vdom->update(document.get());
        benchmark::DoNotOptimize(vdom.get());
    }
    
    state.SetItemsProcessed(state.iterations() * 10); // 10 paragraphs
}
BENCHMARK(BM_VirtualDOM_Update_Small);

static void BM_VirtualDOM_Update_Medium(benchmark::State& state) {
    auto document = create_large_document(100, 50);
    auto vdom = std::make_unique<VirtualDOM>();
    
    for (auto _ : state) {
        vdom->update(document.get());
        benchmark::DoNotOptimize(vdom.get());
    }
    
    state.SetItemsProcessed(state.iterations() * 100); // 100 paragraphs
}
BENCHMARK(BM_VirtualDOM_Update_Medium);

static void BM_VirtualDOM_Update_Large(benchmark::State& state) {
    auto document = create_large_document(1000, 30);
    auto vdom = std::make_unique<VirtualDOM>();
    
    for (auto _ : state) {
        vdom->update(document.get());
        benchmark::DoNotOptimize(vdom.get());
    }
    
    state.SetItemsProcessed(state.iterations() * 1000); // 1000 paragraphs
}
BENCHMARK(BM_VirtualDOM_Update_Large);

// Benchmark Virtual DOM viewport filtering
static void BM_VirtualDOM_Viewport_Filtering(benchmark::State& state) {
    auto document = create_large_document(500, 25);
    auto vdom = std::make_unique<VirtualDOM>();
    vdom->update(document.get());
    
    for (auto _ : state) {
        vdom->set_viewport(static_cast<float>(state.iterations() % 1000), 400.0f);
        auto visible_nodes = vdom->get_visible_nodes();
        benchmark::DoNotOptimize(visible_nodes);
    }
}
BENCHMARK(BM_VirtualDOM_Viewport_Filtering);

// Benchmark text layout
static void BM_TextLayout_SingleParagraph(benchmark::State& state) {
    TextLayout layout;
    std::string text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
    
    for (auto _ : state) {
        auto result = layout.layout_text(text, 400.0f, 16.0f, "Helvetica");
        benchmark::DoNotOptimize(result);
    }
}
BENCHMARK(BM_TextLayout_SingleParagraph);

static void BM_TextLayout_MultipleWidths(benchmark::State& state) {
    TextLayout layout;
    std::string text = "The quick brown fox jumps over the lazy dog. This is a longer sentence to test text wrapping behavior with various width constraints.";
    
    std::vector<float> widths = {200.0f, 300.0f, 400.0f, 500.0f, 600.0f};
    
    for (auto _ : state) {
        for (float width : widths) {
            auto result = layout.layout_text(text, width, 14.0f, "SF Pro");
            benchmark::DoNotOptimize(result);
        }
    }
}
BENCHMARK(BM_TextLayout_MultipleWidths);

// Benchmark glyph atlas operations
static void BM_GlyphAtlas_AddGlyphs(benchmark::State& state) {
    GlyphAtlas atlas(1024, 1024);
    std::string text = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    
    for (auto _ : state) {
        for (char c : text) {
            atlas.get_glyph(static_cast<uint32_t>(c), 16.0f, "Helvetica");
        }
        benchmark::DoNotOptimize(&atlas);
    }
}
BENCHMARK(BM_GlyphAtlas_AddGlyphs);

static void BM_GlyphAtlas_LookupExisting(benchmark::State& state) {
    GlyphAtlas atlas(1024, 1024);
    
    // Pre-populate atlas
    for (char c = 'A'; c <= 'Z'; ++c) {
        atlas.get_glyph(static_cast<uint32_t>(c), 16.0f, "Helvetica");
    }
    
    for (auto _ : state) {
        for (char c = 'A'; c <= 'Z'; ++c) {
            auto glyph = atlas.get_glyph(static_cast<uint32_t>(c), 16.0f, "Helvetica");
            benchmark::DoNotOptimize(glyph);
        }
    }
}
BENCHMARK(BM_GlyphAtlas_LookupExisting);

// Benchmark render engine operations
static void BM_RenderEngine_PrepareFrame(benchmark::State& state) {
    RenderEngine engine;
    engine.initialize(1920, 1080);
    
    for (auto _ : state) {
        auto frame = engine.prepare_frame();
        benchmark::DoNotOptimize(frame);
    }
}
BENCHMARK(BM_RenderEngine_PrepareFrame);

static void BM_RenderEngine_DrawQuads(benchmark::State& state) {
    RenderEngine engine;
    engine.initialize(1920, 1080);
    
    std::vector<RenderEngine::Quad> quads;
    for (int i = 0; i < 100; ++i) {
        RenderEngine::Quad quad;
        quad.x = static_cast<float>(i * 10);
        quad.y = static_cast<float>(i * 5);
        quad.width = 50.0f;
        quad.height = 20.0f;
        quad.color = {0.5f, 0.5f, 0.8f, 1.0f};
        quads.push_back(quad);
    }
    
    for (auto _ : state) {
        auto frame = engine.prepare_frame();
        for (const auto& quad : quads) {
            engine.draw_quad(frame, quad);
        }
        benchmark::DoNotOptimize(frame);
    }
    
    state.SetItemsProcessed(state.iterations() * 100); // 100 quads per iteration
}
BENCHMARK(BM_RenderEngine_DrawQuads);

// Benchmark complex document rendering
static void BM_ComplexDocument_Rendering(benchmark::State& state) {
    auto document = create_mixed_document(200);
    auto vdom = std::make_unique<VirtualDOM>();
    RenderEngine engine;
    engine.initialize(1200, 800);
    
    for (auto _ : state) {
        vdom->update(document.get());
        vdom->set_viewport(0.0f, 800.0f);
        auto visible_nodes = vdom->get_visible_nodes();
        
        auto frame = engine.prepare_frame();
        
        float y_offset = 0.0f;
        for (const auto* node : visible_nodes) {
            RenderEngine::Quad quad;
            quad.x = 20.0f;
            quad.y = y_offset;
            quad.width = 760.0f;
            quad.height = 20.0f;
            quad.color = {0.9f, 0.9f, 0.9f, 1.0f};
            
            engine.draw_quad(frame, quad);
            y_offset += 25.0f;
        }
        
        benchmark::DoNotOptimize(frame);
    }
    
    state.SetComplexityN(200);
}
BENCHMARK(BM_ComplexDocument_Rendering)->RangeMultiplier(2)->Range(50, 800);

// Benchmark memory allocation patterns
static void BM_Document_Creation_Destruction(benchmark::State& state) {
    const size_t doc_size = state.range(0);
    
    for (auto _ : state) {
        auto doc = create_large_document(doc_size, 25);
        benchmark::DoNotOptimize(doc.get());
    }
    
    state.SetComplexityN(doc_size);
}
BENCHMARK(BM_Document_Creation_Destruction)->RangeMultiplier(2)->Range(10, 1000);

// Benchmark incremental updates
static void BM_VirtualDOM_Incremental_Updates(benchmark::State& state) {
    auto document = create_large_document(100, 30);
    auto vdom = std::make_unique<VirtualDOM>();
    vdom->update(document.get());
    
    size_t update_index = 0;
    
    for (auto _ : state) {
        // Simulate incremental update
        const auto* root = document->get_root();
        if (root && !root->children.empty()) {
            size_t index = update_index % root->children.size();
            vdom->update_incremental(root->children[index].get(), index);
            update_index++;
        }
        benchmark::DoNotOptimize(vdom.get());
    }
}
BENCHMARK(BM_VirtualDOM_Incremental_Updates);

} // namespace mdviewer