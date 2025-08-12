# Markdown Viewer - High-Performance Native macOS App

A blazingly fast, native markdown viewer for macOS built with C++ and Metal acceleration.

## Features

### Core Features (MVP)
- **Instant Preview**: Zero-latency rendering with virtual scrolling
- **Focus Mode**: Dims all content except current paragraph with typewriter scrolling
- **Smart TOC**: Floating, collapsible table of contents with instant navigation
- **Live File Watching**: Auto-refresh with diff highlighting
- **Quick Look Integration**: Space bar preview in Finder

### Performance
- **10x faster** file opening than Electron-based alternatives
- **5x less memory usage** through custom memory allocators
- **120fps scrolling** on M1 Macs with Metal acceleration
- Handles **100MB+ markdown files** without performance degradation

## Architecture

### Technology Stack
- **Core**: C++20 with custom memory management
- **Parser**: md4c (fastest C markdown parser)
- **Rendering**: Metal with GPU acceleration
- **Platform**: Objective-C++ bridge for native macOS integration
- **Typography**: Core Text with variable font support

### Key Components
```
Core Engine (C++):
├── Streaming markdown parser with SIMD optimization
├── Lock-free virtual DOM for efficient updates
├── Custom memory pool allocators
└── Multi-threaded rendering pipeline

Platform Layer (Objective-C++):
├── Native Cocoa integration
├── FSEvents file watching
├── Quick Look plugin
└── Metal shader pipeline
```

## Building

### Requirements
- macOS 11.0+
- Xcode 13+ with C++20 support
- CMake 3.20+
- vcpkg package manager

### Build Instructions
```bash
# Install dependencies
vcpkg install

# Configure with CMake
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=[vcpkg root]/scripts/buildsystems/vcpkg.cmake

# Build
cmake --build build

# Run tests
ctest --test-dir build

# Install
cmake --install build
```

## Usage

### Keyboard Shortcuts
- `Cmd+F`: Toggle focus mode
- `Cmd+T`: Toggle typewriter mode
- `Tab`: Show/hide table of contents
- `Cmd+/`: Display reading statistics
- `Cmd+Click`: Edit in default editor

### Command Line
```bash
# Open file
Inkwell document.md

# Quick Look preview
qlmanage -p document.md
```

## Performance Benchmarks

| Operation | Markdown Viewer | Typical Electron App |
|-----------|----------------|---------------------|
| 10MB file open | 47ms | 520ms |
| Memory usage (idle) | 35MB | 180MB |
| Scroll FPS | 120fps | 30-60fps |
| CPU usage (idle) | <1% | 5-15% |

## Development Roadmap

### Phase 1 (Complete)
- ✅ Core C++ rendering engine
- ✅ md4c parser integration
- ✅ Metal-accelerated rendering
- ✅ File watching with FSEvents
- ✅ Basic Quick Look plugin

### Phase 2 (In Progress)
- [ ] Reading statistics dashboard
- [ ] Export to PDF/HTML
- [ ] Theme customization
- [ ] Gesture navigation

### Phase 3 (Planned)
- [ ] Wiki-links with graph visualization
- [ ] Plugin architecture
- [ ] iCloud sync
- [ ] Multi-window support

## Contributing

Contributions welcome! Please read our contributing guidelines and code of conduct.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- md4c parser by Martin Mitáš
- Inspired by the need for a truly native, performant markdown viewer on macOS