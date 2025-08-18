# Inkwell - A Simple macOS Markdown Viewer

**Version: 0.1.0**  
**Status: Actually working (mostly)**

## What This Actually Is

Inkwell is a native macOS markdown **viewer** (not editor!) built with C++. It displays markdown files with basic formatting. That's it.

## What Actually Works

✅ **Core Features That Work:**
- Opens and displays markdown files
- Basic syntax highlighting (headers, bold, italic, code blocks)
- File → Open dialog
- Command-line opening: `Inkwell file.md`
- Vim navigation (j/k for scrolling, g/G for top/bottom)
- Smooth scrolling
- Recent files menu (maybe?)

## What Doesn't Work

❌ **Broken/Missing:**
- Table of Contents sidebar (code exists but not wired up)
- File watching (unclear if working)
- Command Palette (Cmd+K might crash)
- Search functionality
- Export to HTML/PDF
- Zoom in/out
- About dialog

❌ **Architectural Lies (ignore these claims):**
- "GPU accelerated" - Nope, uses NSTextView
- "120fps scrolling" - Just regular scrolling
- "Virtual DOM" - Exists but unused
- "SIMD optimized" - Headers included, never used
- "Memory pools" - Implemented but not used
- "10x faster than Electron" - Never measured

## How to Build

```bash
# Requirements
- macOS 11.0+
- Xcode command line tools
- CMake
- vcpkg (optional)

# Build
chmod +x build_simple.sh
./build_simple.sh

# Run
./build_simple/Inkwell.app/Contents/MacOS/Inkwell file.md
# Or
open build_simple/Inkwell.app
```

## How to Use

1. **Open a file:**
   - Launch app → File → Open
   - Or: `./Inkwell.app/Contents/MacOS/Inkwell file.md`
   - Or: Drag and drop (might work?)

2. **Navigate:**
   - Scroll with trackpad/mouse
   - `j`/`k` - scroll down/up
   - `g` - go to top
   - `G` - go to bottom

3. **That's it.** It's a viewer. It views markdown files.

## Technical Details

- **Language:** C++20 with Objective-C++
- **UI:** Native Cocoa with NSTextView
- **Parser:** md4c (this part actually works well)
- **Size:** ~2MB executable

## Known Issues

- Can't edit anything (it's a viewer)
- TOC sidebar doesn't work
- Some menu items are just TODO stubs
- Might crash on certain markdown files
- No preferences/settings

## Why This Exists

Originally intended as a "blazingly fast" markdown viewer with GPU acceleration and all sorts of fancy features. Reality: It's a simple NSTextView wrapper that displays markdown. And that's fine.

## Contributing

The codebase is 15% working, 40% broken, 45% aspirational. Feel free to:
- Remove broken code
- Simplify the architecture
- Make TOC actually work
- Add search
- Fix any of the TODO stubs

## License

MIT (because why not)

---

**Note:** This is the honest version. For the original aspirational version, see README_ORIGINAL_FANTASY.md