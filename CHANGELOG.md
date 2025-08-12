# Changelog

All notable changes to Inkwell will be documented in this file.

## [1.1.0] - 2025-08-09

### Build 13
- Enhanced reading time badge with premium gradient design
- Added Focus Mode toggle (Cmd+.) with vignette overlay effect
- Focus Mode dims distractions and creates reading spotlight
- Glass morphism effect on reading time badge
- Added View menu item for Focus Mode

### Build 12
- Added edge scroll indicators with smooth gradient shadows
- Indicators fade in/out based on scroll position
- Shows subtle visual feedback when content extends beyond viewport
- Inspired by Linear and Things 3 design language

### Build 11
- Fixed reading time badge visibility and positioning
- Enhanced badge styling with accent color and shadow

### Build 10
- Added reading time estimates (displayed in floating badge and status bar)
- Calculates based on 225 words per minute for technical content
- Shows as "X min read" or "X hr Y min" for longer documents

### Build 9
- Implemented VimTextView for proper vim key handling
- Fixed text view focus on document load
- Enhanced keyboard event routing

### Build 8
- Added vim-style navigation (j/k for down/up, h/l for navigation)
- Enhanced keyboard shortcuts throughout the app
- Fixed command palette implementation with simplified stable version

### Build 7
- Successfully fixed command palette crash issue
- Implemented simplified command palette that works reliably
- Added to build system and verified functionality

### Build 6 and earlier
- **Command Palette** (Cmd+K) - Universal search for documents, headings, and actions
  - Fuzzy search algorithm for intelligent matching
  - Glass morphism design with smooth animations
  - Keyboard navigation (arrow keys, Enter, Escape)
  - Menu item in Edit menu
- **Version System** - Build tracking and verification
  - Version display in title bar
  - Build timestamp tracking
  - Feature flag system
- **Debug Logging** - Better debugging capabilities

### Fixed
- Menu item crash when accessing command palette (Build 7)
- Keyboard shortcut event handling
- First responder chain for proper key event routing
- Compilation errors in simple_command_palette.mm

### Known Issues
- None currently known in Build 8

## [1.0.0] - 2025-08-07

### Initial Release
- High-performance native macOS Markdown viewer
- Metal-accelerated rendering with 120fps scrolling
- Virtual DOM for efficient updates
- Table of Contents sidebar
- Dark/Light theme support
- Search functionality
- PDF and HTML export
- File watching with auto-reload
- Mermaid diagram support
- Syntax highlighting for code blocks