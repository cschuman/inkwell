# Inkwell Features Status

## ✅ Features That ACTUALLY WORK

### Confirmed Working:
- **Markdown rendering** - Displays real formatted text
- **File opening** - File → Open dialog works
- **Command-line opening** - `Inkwell file.md` works
- **Vim navigation** - j/k/g/G confirmed working
- **Search (Cmd+F)** - FULLY IMPLEMENTED!
  - Search bar slides down
  - Highlights matches
  - Next/Previous navigation
  - Cmd+G/Cmd+Shift+G shortcuts
  - ESC to close
- **Syntax highlighting** - Headers, bold, italic, code blocks

### Likely Working (Need User Confirmation):
- **File watching** - Code runs, needs visual confirmation
- **Command Palette (Cmd+K)** - Code exists, may work
- **Drag & drop** - Registered for file drops
- **Recent files menu** - Code exists

## ❌ Features That DON'T Work

### Confirmed Broken:
- **TOC sidebar** - Not wired up
- **Save/Save As** - TODO stubs (but it's a viewer!)
- **Export HTML/PDF** - TODO stubs
- **Zoom in/out** - TODO stubs
- **About dialog** - TODO stub

### Architectural Fiction:
- **GPU acceleration** - Using NSTextView
- **Virtual DOM** - Exists but unused
- **SIMD optimization** - Never used
- **Memory pools** - Not used for parsing

## 🎯 Discovery: Hidden Features!

We discovered that many features were **already implemented but not documented**:

1. **Search was 100% complete** - Just needed testing
2. **File watching appears functional** - Auto-reload on external changes
3. **Command Palette exists** - SimpleCommandPalette implementation

## 📊 Real Statistics

- **Features claimed**: ~20
- **Actually working**: ~10 (50%)
- **Hidden but working**: ~3 (15%)
- **Broken**: ~7 (35%)

## Next Steps

1. Document the working features properly
2. Test Command Palette thoroughly
3. Wire up TOC sidebar (parser works, UI exists)
4. Add Export to PDF (macOS makes this easy)

---

*The app is way more functional than we initially thought!*