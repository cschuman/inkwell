# Inkwell

A fast, native markdown viewer for macOS.

## Features

- **Native macOS application** with Cocoa integration
- **File watching** for automatic refresh
- **Drag & drop** support with visual feedback
- **Command palette** for quick actions
- **Table of contents** extraction
- **Dark mode** support
- **Smooth scrolling** with native momentum

## Installation

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

- `⌘O` - Open file
- `⌘W` - Close window
- `⌘Q` - Quit application
- `⌘K` - Open command palette
- `⌘+` - Increase font size
- `⌘-` - Decrease font size
- `⌘0` - Reset font size

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

## Project Status

Version 1.0 focuses on core functionality and stability. The codebase has been simplified from earlier experimental versions to ensure reliability and maintainability.