# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Building the Application
```bash
# Full build with dependencies
./build.sh

# Manual build steps
vcpkg install
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
cmake --build build -j$(sysctl -n hw.ncpu)
```

### Running Tests
```bash
# Run all tests
ctest --test-dir build --output-on-failure

# Run specific test executable
./build/mdviewer_tests

# Run benchmarks
./build/mdviewer_benchmarks
```

### Development Commands
```bash
# Generate compile_commands.json for language servers
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Clean build
rm -rf build && mkdir build

# Install to /Applications
cmake --install build --prefix /Applications
```

## Architecture Overview

Inkwell is a high-performance native macOS Markdown viewer built with C++20 and Metal acceleration. The codebase uses a layered architecture:

### Core Layer (`src/core/`, `include/core/`)
- **markdown_parser**: Wraps md4c parser with streaming capabilities and SIMD optimizations
- **virtual_dom**: Lock-free virtual DOM for efficient rendering updates without full re-parses
- **document**: Document model managing markdown content and metadata
- **toc_generator**: Extracts and manages table of contents from parsed markdown

### Platform Layer (`src/platform/macos/`, `include/platform/`)
- **cocoa_bridge**: Objective-C++ bridge for Cocoa framework integration
- **file_watcher**: FSEvents-based file monitoring for auto-refresh
- **quick_look_plugin**: Quick Look integration for Finder previews
- **app_delegate**: macOS application lifecycle management
- **main_window**: Native window management and event handling

### Rendering Layer (`src/rendering/`, `include/rendering/`)
- **metal_renderer**: GPU-accelerated rendering using Metal shaders
- **text_layout**: Core Text integration for typography and font rendering
- **glyph_atlas**: Texture atlas management for efficient glyph caching
- **render_engine**: Orchestrates the rendering pipeline with virtual scrolling

### Utilities (`src/utils/`, `include/utils/`)
- **memory_pool**: Custom memory allocators for reduced fragmentation
- **string_utils**: SIMD-optimized string operations
- **file_utils**: Platform-specific file I/O operations

## Key Design Patterns

1. **Virtual DOM**: Changes are computed as diffs between DOM states to minimize rendering updates
2. **Memory Pooling**: Custom allocators reduce allocation overhead for parser tokens
3. **GPU Acceleration**: Text rendering offloaded to Metal shaders for 120fps scrolling
4. **Lock-free Updates**: Concurrent reads during rendering while parsing happens on background thread
5. **Streaming Parser**: Handles large files by parsing incrementally with bounded memory usage

## Dependencies

- **md4c**: C markdown parser (fetched via CMake)
- **fmt**: Modern C++ formatting library
- **gtest**: Google Test framework
- **benchmark**: Google Benchmark for performance testing
- **parallel-hashmap**: High-performance hash maps
- **simdjson**: SIMD-accelerated JSON parsing
- **range-v3**: Range library for C++

## macOS Frameworks Used

- **Cocoa**: Window management and UI
- **Metal/MetalKit**: GPU rendering
- **CoreText**: Typography and font rendering
- **Quartz**: Quick Look plugin support
- **FSEvents**: File system monitoring

## Git Commit Guidelines

When creating git commits, DO NOT add Claude attribution or co-authorship lines. Use clean, standard commit messages without any AI-related signatures or emojis.