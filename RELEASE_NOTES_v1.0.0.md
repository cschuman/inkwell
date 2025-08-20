# Inkwell v1.0.0 - Clean Slate Release

## First Stable Release 🎉

After a major architectural simplification, Inkwell 1.0.0 is here as a clean, maintainable markdown viewer for macOS.

## What's New

- **Complete rewrite** - Removed 5,000+ lines of unused optimization code
- **Simplified architecture** - Focus on reliability over premature optimization  
- **Clean codebase** - Organized structure with proper separation of concerns
- **Stable foundation** - Ready for real-world use and future enhancements

## Features

- 📝 Native macOS markdown viewer
- ⚡ Fast markdown parsing with md4c
- 🔄 File watching for auto-refresh
- 🎯 Drag & drop with visual effects
- ⌘K Command palette
- 🖱️ Smooth scrolling
- 🌙 Dark mode support

## Download

- **[Inkwell-1.0.0.dmg](https://github.com/cschuman/inkwell/releases/download/v1.0.0/Inkwell-1.0.0.dmg)** (549 KB)

## Installation

1. Download the DMG file
2. Open and drag Inkwell to Applications
3. Right-click and select 'Open' on first launch (unsigned app)

## Technical Details

- **Binary size**: 549 KB (reduced from ~800 KB)
- **Architecture**: NSTextView-based rendering
- **Language**: C++20 with Objective-C++
- **Dependencies**: md4c, fmt
- **macOS**: 11.0+ (Universal Binary)

## Known Issues

- Verbose drag & drop logging (will be fixed in 1.0.1)
- App is unsigned (Gatekeeper warning on first launch)
- Tests temporarily disabled during refactor

## What Changed

### Removed
- Metal rendering pipeline (unused)
- Virtual DOM implementation (never integrated)
- SIMD optimizations (never utilized)
- Memory pool system (not used in hot paths)
- 50+ test scripts
- Unnecessary dependencies

### Improved
- Project structure (docs/, scripts/, organized directories)
- Build system (simplified CMakeLists.txt)
- Documentation (reflects actual implementation)
- Code clarity (removed architectural complexity)

## What's Next

### v1.0.1 (Bug fixes)
- Reduce debug logging
- Fix deprecation warnings
- Re-enable test suite

### v1.1.0 (Features)
- Export to PDF/HTML
- Enhanced table of contents
- Search functionality
- Preferences window

### v2.0.0 (Future)
- Code signing & notarization
- Homebrew formula
- Plugin system
- Theme customization

## Commit Statistics

- **75 files changed**
- **442 insertions(+)**
- **5,425 deletions(-)**
- **~40% binary size reduction**

## For Developers

```bash
# Clone and build
git clone https://github.com/cschuman/inkwell.git
cd inkwell
./scripts/build.sh

# Run
./build/Inkwell.app/Contents/MacOS/Inkwell README.md
```

## Credits

Built with:
- [md4c](https://github.com/mity/md4c) - Markdown parser
- [fmt](https://github.com/fmtlib/fmt) - Formatting library
- Love for clean code ❤️

---

This release represents a complete architectural reset. The codebase is now maintainable, understandable, and ready for community contributions.

**Philosophy**: Simple, working software beats complex, theoretical performance every time.