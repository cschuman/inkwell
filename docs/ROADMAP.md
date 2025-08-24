# Inkwell Development Roadmap

## Project Vision
Inkwell aims to be the fastest, most elegant native Markdown viewer for macOS, focusing on performance, simplicity, and seamless integration with the macOS ecosystem.

## Development Principles
- **Fix Before Feature** - Complete existing features before adding new ones
- **Performance First** - Every feature must maintain 120fps scrolling
- **Code Reduction** - Less code means fewer bugs and better performance
- **User Trust** - Menu items must work or be removed
- **Native Experience** - Follow macOS design guidelines and conventions

---

## Phase 0: Fix Fundamentals ✅ COMPLETED (v1.0.9)
**Timeline: 1 week** - **Actual: 1 day**
**Theme: "Stop Lying to Users"**

### Critical Fixes (Actually Already Implemented!)
- ✅ **Export to PDF** - Was already working at line 3618
- ✅ **Export to HTML** - Was already working at line 3674
- ✅ **Zoom controls** - Were already working at lines 3916-3929
- ✅ **Window persistence** - Was already working
- ✅ **Recent files menu** - Was already working
- ✅ **Remember last file** - NOW IMPLEMENTED

### Code Cleanup (2,000+ lines deleted)
- ✅ Removed ALL drag effects except one simple one
- ✅ Deleted particle effects, physics simulation, noise generators (1,600+ lines)
- ✅ Removed non-functional performance monitoring
- ✅ Removed debug overlays
- ✅ Deleted orphaned app_delegate.mm
- ⚠️ main.mm still 4,000 lines (future work)

### Performance Fixes
- ✅ Tested with 14MB markdown file - loads in ~1 second
- ✅ No freezing on large files
- ⚠️ Progressive rendering not needed yet

### Success Metrics Achieved
- ✅ All menu items work
- ✅ 14MB file loads in ~1 second
- ⚠️ Binary size 608KB (DMG) - slightly over target
- ✅ Zero TODO comments in menu handlers (deleted orphaned file)

---

## Phase 1: Foundation Stabilization ⚠️ PARTIALLY COMPLETE (v1.0.0 - v1.0.8)
**Theme: "Actually Working Basics"**

### Actually Achieved
- ✅ Fixed critical dylib issue preventing app launch
- ✅ TOC click navigation working
- ✅ File watching auto-refresh functional
- ✅ Drag & drop fully implemented (with excessive effects)
- ✅ Command palette (Cmd+K) working
- ✅ Basic search functionality (Cmd+F)
- ✅ Command-line file opening (`inkwell file.md`)
- ✅ Custom app icon
- ✅ Homebrew distribution

### Falsely Claimed as Complete
- ❌ Export to PDF/HTML (just TODO comments)
- ❌ Zoom controls (just TODO comments)
- ❌ Window persistence (broken)
- ❌ Performance for large files (freezes)

### Outstanding Items
- [ ] Re-enable test suite (currently disabled)
- [ ] Performance baseline measurements
- [ ] CLI folder support (`inkwell .` to open current directory)

---

## Phase 2: Core User Experience (v1.1.0)
**Timeline: 2 weeks**
**Theme: "Reading Experience First"**

### Must Have (Week 1)
- [ ] **Real search** - Find with highlighting, navigate between results
- [ ] **Reading progress bar** - Subtle indicator of position in document
- [ ] **Reading time estimate** - "~5 min read" in status bar
- [ ] **Session restoration** - Remember file + scroll position
- [ ] **Welcome document** - First-launch experience with sample
- [ ] **Working recent files** - In File menu and dock

### Nice to Have (Week 2)
- [ ] **CLI folder support** - `inkwell .` opens folder browser
- [ ] **Focus mode that works** - Dim everything except current paragraph
- [ ] **Auto-TOC** - Fixed position, collapsible sidebar
- [ ] **Smooth momentum scrolling** - Perfect 120fps always
- [ ] **Document stats** - Word count, character count in status bar

### Explicitly Deprioritized
- ❌ Tab support (adds complexity, wait for user demand)
- ❌ Preference pane (keep it simple for now)
- ❌ Back/forward navigation (not essential for v1.1)

### Success Metrics
- Search works as well as VS Code
- Reading experience rivals iA Writer
- Zero performance degradation
- <50ms file open time

---

## Phase 3: Performance at Scale (v1.2.0)
**Timeline: 3 weeks**
**Theme: "Handle Anything"**

### Core Performance (Week 1-2)
- [ ] **Virtual scrolling** - Only render visible portion
- [ ] **Progressive rendering** - Show content while parsing
- [ ] **Incremental parsing** - Parse only changed sections
- [ ] **Memory optimization** - Stream large files, don't load entirely
- [ ] **Background processing** - Parse on background thread

### Large File Support (Week 3)
- [ ] **10MB file support** - Currently freezes, must work smoothly
- [ ] **100MB file support** - Open in <2 seconds
- [ ] **Smart chunking** - Break large documents into segments
- [ ] **File size warnings** - Alert user before opening huge files
- [ ] **Cancel/abort loading** - Let user cancel if taking too long

### Already Have (Don't Rewrite)
- ✅ Metal shaders written (just not integrated)
- ✅ SIMD available (just not used)
- ❌ Don't write more GPU code until current code is used

### Success Metrics
- 100MB file opens in <2 seconds
- 10MB file scrolls at 120fps
- Memory usage <100MB for any file size
- No freezing, ever

---

## Phase 4: Advanced Features (v1.3.0) 
**Timeline: 4 weeks**
**Theme: "Power Tools"**

### Developer Features (Week 1-2)
- [ ] **Mermaid diagrams** - Already partially implemented
- [ ] **Math formulas** - LaTeX/KaTeX support
- [ ] **Code block enhancements** - Line numbers, better highlighting
- [ ] **Global search** - Search across folder of files
- [ ] **External editor** - "Open in VS Code" menu item

### Export & Publishing (Week 3-4)
- [ ] **Better PDF export** - With proper pagination
- [ ] **DOCX export** - For Word users
- [ ] **HTML export with styles** - Ready-to-publish HTML
- [ ] **Custom CSS themes** - User-defined styles
- [ ] **Print preview** - WYSIWYG printing

### Success Metrics
- Can handle technical documentation
- Export quality matches Pandoc
- Developers choose Inkwell for docs

---

## Phase 5: Polish & Ship (v2.0.0)
**Timeline: 2 weeks**
**Theme: "Ready for the World"**

### Mac App Store Preparation
- [ ] **Code signing** - Proper Apple Developer ID
- [ ] **Sandboxing** - App Store compliance
- [ ] **Help documentation** - Built-in help system
- [ ] **App Store assets** - Screenshots, description, keywords
- [ ] **Telemetry-free analytics** - Respect privacy

### Professional Polish
- [ ] **Proper app icon** - Shows in dock correctly
- [ ] **Onboarding flow** - First-launch experience
- [ ] **Keyboard shortcuts help** - Discoverable shortcuts
- [ ] **Sample documents** - Beautiful examples included
- [ ] **Error handling** - Graceful failures with helpful messages

### Success Metrics
- Mac App Store approval
- 5-star average rating
- <1% crash rate
- 1000+ downloads in first month

---

## Future Considerations (Post v2.0)

### Only If Users Demand It
- Tab support for multiple documents
- Plugin system for extensions
- Collaboration features
- Cloud sync
- Mobile companion app

### Probably Never
- Editing capabilities (stay focused on viewing)
- AI features (keep it simple and fast)
- Subscription model (one-time purchase if anything)
- Electron rewrite (stay native)

---

## Code Quality Principles

### The 10 Commandments
1. **Thou shalt not ship broken menu items**
2. **Thou shalt delete unused code**
3. **Thou shalt test with 10MB files**
4. **Thou shalt maintain 120fps always**
5. **Thou shalt keep binary under 1MB**
6. **Thou shalt implement before announcing**
7. **Thou shalt not add effects for markdown**
8. **Thou shalt respect user expectations**
9. **Thou shalt profile before optimizing**
10. **Thou shalt choose boring technology**

---

## Release Strategy

### Version Numbering
- **Major (x.0.0)** - Significant user-facing improvements
- **Minor (0.x.0)** - New features that work
- **Patch (0.0.x)** - Bug fixes and performance

### Release Cadence
- **Phase 0** - Ship v1.0.9 within 1 week
- **Then** - Release when ready, not on schedule
- **No deadlines** - Quality over dates

### Distribution Channels
1. GitHub releases (primary)
2. Homebrew cask (current)
3. Direct download (future)
4. Mac App Store (v2.0)

---

## Success Metrics

### What Actually Matters
- **It works** - All features function as advertised
- **It's fast** - 10MB file in <1 second
- **It's small** - Binary under 600KB
- **It's reliable** - Zero crashes
- **It's honest** - No fake features

### What Doesn't Matter
- GitHub stars
- Feature count
- Line count (less is more)
- Framework choices
- Effect variety

---

## Expert Review Quotes

**Sr. Principal Engineer (25 years experience):**
> "You have 15,000 lines of code. 5,000 are effects nobody uses. 10 are the PDF export you haven't written. Which matters more?"

**Creative Director (20 years experience):**
> "Every second spent on particle effects is a second not spent on making text beautiful and readable. You're not a game. You're a reading tool."

---

*This roadmap has been revised based on expert review and brutal honesty about current state.*

*Last updated: January 2025*
*Current version: v1.0.9*
*Status: Phase 0 ✅ COMPLETE - Fundamentals fixed, 2,000+ lines removed*