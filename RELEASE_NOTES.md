# Release v0.2.0 - Table of Contents & Stability

## ✨ Major Improvements

This release brings significant functionality improvements and stability fixes to Inkwell.

### 🎯 Key Features
- **Table of Contents Sidebar** - Toggle with Cmd+Option+T to see document structure
- **TOC Navigation** - Click any heading to jump directly to that section
- **Window Persistence** - Window size and position are saved between sessions
- **Zoom Controls** - Adjust text size with Cmd++/Cmd+-/Cmd+0
- **Export Functionality** - Export to PDF (Cmd+Shift+E) and HTML
- **Enhanced About Dialog** - Shows version and build information

### 🐛 Critical Fixes
- **Search Crash Fixed** - Resolved memory management issue causing crashes
- **Command Palette Working** - Now properly displays and executes all commands
- **File Opening Fixed** - Command-line file opening works correctly
- **Memory Leaks Resolved** - Multiple memory management issues fixed

### 📦 Installation
Download the DMG file and drag Inkwell to your Applications folder.

**Requirements:** macOS 11.0 or later

### 📊 Release Stats
- **Version:** 0.2.0
- **Build:** 2
- **Size:** 228KB (DMG)
- **Architecture:** Universal (Intel + Apple Silicon)

### 🙏 Acknowledgments
Thanks to the md4c parser and the macOS developer community.

---

## How to Create the GitHub Release

1. Go to: https://github.com/cschuman/inkwell/releases/new
2. Choose tag: `v0.2.0` (already created and pushed)
3. Release title: `v0.2.0 - Table of Contents & Stability`
4. Copy the release notes above into the description
5. Attach the file: `Inkwell-0.2.0.dmg`
6. Check "Set as the latest release"
7. Click "Publish release"