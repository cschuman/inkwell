# Inkwell

A fast, native markdown viewer for macOS. Clean, focused, and efficient.

![Version](https://img.shields.io/badge/version-1.0.9-blue)
![Size](https://img.shields.io/badge/size-608KB-green)
![License](https://img.shields.io/badge/license-MIT-brightgreen)

## Features

- **Native macOS application** with full Cocoa integration
- **Lightning fast** - Opens 14MB files in ~1 second
- **File watching** for automatic refresh when files change
- **Session memory** - Remembers last opened file and window position
- **Export support** - PDF and HTML export
- **Command palette** (⌘K) for quick actions
- **Focus mode** - Highlight current paragraph with arrow navigation
- **Recent files menu** - Quick access to recent documents
- **Dark mode** support with system preference detection
- **Zoom controls** - Adjust text size to preference

## Installation

### Via Homebrew (Recommended)

```bash
brew tap cschuman/tap
brew install --cask inkwell
```

### Direct Download

Download the latest DMG from [Releases](https://github.com/cschuman/inkwell/releases/latest)

### Build from Source

Requirements:
- macOS 11.0 or later
- Xcode Command Line Tools
- CMake 3.20+
- vcpkg

```bash
# Install dependencies
vcpkg install

# Build
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
cmake --build build -j$(sysctl -n hw.ncpu)

# Install to /Applications
cmake --install build --prefix /Applications
```

## Usage

Open markdown files:
```bash
open -a Inkwell document.md
```

Or drag and drop markdown files onto the application icon.

## Keyboard Shortcuts

### File Operations
- `⌘O` - Open file
- `⌘S` - Save (if editing)
- `⌘W` - Close window
- `⌘Q` - Quit application

### Navigation
- `⌘K` - Open command palette
- `⌘.` - Toggle focus mode
- `↑/↓` - Navigate paragraphs (in focus mode)
- `⌘F` - Find in document
- `⌘G` - Find next
- `⌘⇧G` - Find previous

### View
- `⌘+` - Zoom in
- `⌘-` - Zoom out
- `⌘0` - Reset zoom
- `⌘T` - Toggle table of contents
- `⌘B` - Toggle file browser

### Vim-style Navigation
- `j/k` - Scroll down/up
- `h/l` - Scroll left/right
- `gg` - Go to top
- `G` - Go to bottom

## Architecture

Inkwell is built with:
- **C++20** for core logic
- **Objective-C++** for macOS integration
- **NSTextView** for text rendering
- **md4c** for markdown parsing
- **FSEvents** for file monitoring

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

## Philosophy

> "The best code is the code you don't write."

Inkwell v1.0.9 represents a major cleanup based on expert review. We removed over 2,000 lines of unnecessary effects code to focus on what matters: **fast, reliable markdown viewing**.

## Project Status

**Current Version: 1.0.9** (January 2025)

Recent focus:
- ✅ Removed 2,000+ lines of unnecessary effects code
- ✅ Fixed fundamental features
- ✅ Improved performance and reliability
- ✅ Reduced binary size

See [ROADMAP.md](docs/ROADMAP.md) for future plans.