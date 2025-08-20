# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Building the Application
```bash
# Quick build using script
./scripts/build.sh

# Manual build
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
cmake --build build -j$(sysctl -n hw.ncpu)

# Clean build
rm -rf build
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
cmake --build build
```

### Running the Application
```bash
# Run directly
./build/Inkwell.app/Contents/MacOS/Inkwell [markdown_file]

# Open with macOS
open ./build/Inkwell.app

# Install to Applications
cmake --install build --prefix /Applications
```

## Architecture Overview

Inkwell is a native macOS Markdown viewer built with C++20 and Objective-C++. The codebase follows a clean, layered architecture:

### Core Layer (`src/core/`, `include/core/`)
- **markdown_parser**: Wraps md4c parser for markdown processing
- **document**: Document model managing markdown content and structure
- **toc_generator**: Extracts table of contents from markdown

### Platform Layer (`src/platform/macos/`, `include/platform/`)
- **cocoa_bridge**: Objective-C++ bridge for Cocoa framework integration
- **file_watcher**: FSEvents-based file monitoring for auto-refresh
- **app_delegate**: macOS application lifecycle management
- **main_window**: Native window management using NSTextView

### Rendering Layer (`src/rendering/`, `include/rendering/`)
- **text_layout**: Core Text integration for typography
- **markdown_renderer**: Converts parsed markdown to attributed strings

### UI Layer (`src/ui/`, `include/ui/`)
- **command_palette**: Quick command access
- **design_system**: UI theming and styles
- **enhanced_window**: Window effects and animations

### Effects Layer (`src/effects/`, `include/effects/`)
- **effect_manager**: Manages visual effects for drag & drop
- **Various effect implementations**: Ripple, particle, etc.

## Key Design Decisions

1. **NSTextView Rendering**: Uses native macOS text rendering for reliability
2. **Native Integration**: Full Cocoa/AppKit integration for macOS feel
3. **Simple Architecture**: Focus on maintainability over premature optimization
4. **File Watching**: Automatic refresh on file changes

## Dependencies

- **md4c**: C markdown parser (fetched via CMake)
- **fmt**: Modern C++ formatting library
- **gtest**: Google Test framework (for tests)

## macOS Frameworks Used

- **Cocoa**: Window management and UI
- **CoreText**: Typography and font rendering
- **Quartz**: Graphics and effects
- **WebKit**: Web content rendering (for future features)
- **FSEvents**: File system monitoring

## Development Guidelines

1. **Keep it Simple**: Avoid over-engineering
2. **Native First**: Use macOS native APIs where possible
3. **Test Coverage**: Write tests for core functionality
4. **Clean Code**: Follow modern C++ best practices

## Git Commit Guidelines

Use clean, standard commit messages without AI-related signatures or emojis.