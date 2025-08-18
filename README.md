# Inkwell - Native macOS Markdown Viewer

**Version: 0.1.0**  
**Status: Beta**

## Overview

Inkwell is a native macOS markdown viewer built with C++ and Objective-C++. It provides fast, native rendering of markdown documents with a clean, minimal interface.

## Features

### Working Features
- **File Operations**
  - Open markdown files via File menu or command line
  - Drag and drop support
  - Recent files menu
  - File watching with auto-reload

- **Text Display**
  - Syntax highlighting for headers, bold, italic, code blocks
  - Smooth scrolling
  - Dark mode support

- **Navigation**
  - Vim-style keyboard navigation (j/k/g/G)
  - Search with highlighting (Cmd+F)
  - Find next/previous (Cmd+G/Cmd+Shift+G)

- **User Interface**
  - Command palette (Cmd+K)
  - Native macOS look and feel
  - Minimal, distraction-free viewing

### Not Yet Implemented
- Table of Contents sidebar
- Export to HTML/PDF
- Zoom controls
- Preferences window

## Installation

### Requirements
- macOS 11.0 or later
- Xcode Command Line Tools
- CMake 3.20+
- vcpkg (optional, for dependency management)

### Building from Source

```bash
# Clone the repository
git clone https://github.com/cschuman/inkwell.git
cd inkwell

# Build
chmod +x build_simple.sh
./build_simple.sh

# Run
open build_simple/Inkwell.app
# Or from command line:
./build_simple/Inkwell.app/Contents/MacOS/Inkwell README.md
```

## Usage

### Opening Files
- **File Menu**: File → Open (Cmd+O)
- **Command Line**: `Inkwell document.md`
- **Drag & Drop**: Drop markdown files onto the app window

### Keyboard Shortcuts
- `Cmd+O` - Open file
- `Cmd+F` - Search
- `Cmd+G` - Find next
- `Cmd+Shift+G` - Find previous
- `Cmd+K` - Command palette
- `j/k` - Scroll down/up
- `g/G` - Go to top/bottom
- `ESC` - Close search

## Architecture

- **Language**: C++20 with Objective-C++
- **UI Framework**: Native Cocoa/AppKit
- **Markdown Parser**: md4c
- **Text Rendering**: NSTextView with syntax highlighting
- **Build System**: CMake with vcpkg for dependencies

## Known Limitations

- Read-only viewer (no editing capabilities)
- Table of Contents sidebar not yet functional
- Export features not implemented
- Some advanced markdown features may not render correctly

## Contributing

Contributions are welcome! Priority areas for improvement:
- Implementing Table of Contents navigation
- Adding export functionality (HTML/PDF)
- Improving markdown rendering coverage
- Adding preferences/settings window

## License

MIT License - see LICENSE file for details

## Acknowledgments

- md4c markdown parser by Martin Mitáš
- Original architecture inspired by performance-focused design principles