# Inkwell Development Roadmap

## Project Vision
Inkwell aims to be the fastest, most elegant native Markdown viewer for macOS, focusing on performance, simplicity, and seamless integration with the macOS ecosystem.

## Development Principles
- **Performance First** - Every feature must maintain 60+ fps scrolling
- **Native Experience** - Follow macOS design guidelines and conventions
- **Incremental Delivery** - Ship small, working improvements frequently
- **User-Driven** - Prioritize based on actual user needs and feedback

---

## Phase 1: Foundation Stabilization ✅ COMPLETED (v1.0.0 - v1.0.2)
**Theme: "Rock Solid Basics"**

### Achieved
- ✅ Fixed critical dylib issue preventing app launch
- ✅ TOC click navigation working
- ✅ File watching auto-refresh functional
- ✅ All keyboard shortcuts documented and working
- ✅ Drag & drop fully implemented with visual effects
- ✅ Command palette (Cmd+K) working
- ✅ Search functionality (Cmd+F) with highlighting
- ✅ Export to PDF/HTML working
- ✅ Zoom controls implemented
- ✅ Window persistence working
- ✅ Command-line file opening (`inkwell file.md`)

### Outstanding Items
- [ ] Re-enable test suite (currently disabled)
- [ ] Performance baseline measurements
- [ ] CLI folder support (`inkwell .` to open current directory)

---

## Phase 2: Essential Enhancements (Current - v1.1.0)
**Timeline: 2-3 weeks**
**Theme: "Daily Driver Ready"**

### Goals
- Add most-requested quality-of-life features
- Improve document navigation experience
- Polish existing features

### Deliverables
- [ ] CLI folder support - `inkwell .` opens folder browser
- [ ] Tab support for multiple documents
- [ ] Dark mode with system preference detection (partial support exists)
- [ ] Back/forward navigation history
- [ ] Search highlighting persistence across document changes
- [ ] TOC with collapsible sections
- [ ] Recent files in dock menu (basic support exists)
- [ ] Preference pane for customization
- [ ] Re-enable and update test suite
- [ ] Code signing for easier distribution

### Success Metrics
- Can replace Preview.app for daily markdown viewing
- Positive feedback on navigation improvements
- <100ms file open time for typical documents

---

## Phase 3: Power User Features (v1.2.0)
**Timeline: 3-4 weeks**
**Theme: "Professional Tool"**

### Goals
- Support advanced markdown features
- Enhance export capabilities
- Add power user shortcuts

### Deliverables
- [ ] Mermaid diagram rendering
- [ ] Math formula support (LaTeX/KaTeX)
- [ ] Export to DOCX and enhanced PDF
- [ ] Custom CSS theme support
- [ ] Global search across multiple files
- [ ] External editor integration
- [ ] Bookmark system

### Success Metrics
- Feature parity with major markdown editors (viewing only)
- Support for technical documentation workflows
- Adoption by developers and technical writers

---

## Phase 4: Performance Revolution (v1.3.0)
**Timeline: 4-5 weeks**
**Theme: "Blazing Fast"**

### Goals
- Optimize for massive documents (100MB+)
- Implement true GPU acceleration
- Achieve best-in-class performance

### Deliverables
- [ ] Incremental parsing for large files
- [ ] Virtual scrolling implementation
- [ ] GPU-accelerated text rendering (Metal)
- [ ] Memory pool optimization
- [ ] Background parsing with progressive rendering
- [ ] SIMD optimizations for text processing

### Success Metrics
- Open 100MB file in <1 second
- Maintain 120fps scrolling on all documents
- <50MB memory usage for typical documents
- Handle 1M+ line documents smoothly

---

## Phase 5: Ecosystem Integration (v1.4.0)
**Timeline: 4-5 weeks**
**Theme: "Part of Your Workflow"**

### Goals
- Deep macOS integration
- Developer tool integration
- Extensibility foundation

### Deliverables
- [ ] Quick Look plugin enhancement
- [ ] Spotlight search integration
- [ ] Share sheet support
- [ ] AppleScript support
- [ ] Basic plugin system
- [ ] CLI tool improvements
- [ ] Integration with note-taking apps

### Success Metrics
- Seamless integration with macOS workflows
- Plugin ecosystem beginning to form
- Adoption by app developers for documentation

---

## Phase 6: Intelligence Layer (v2.0.0)
**Timeline: 6-8 weeks**
**Theme: "Smart Viewer"**

### Goals
- Add intelligent features
- Major version milestone
- Professional polish

### Deliverables
- [ ] Smart search with context understanding
- [ ] Document summarization
- [ ] Auto-generated table of contents
- [ ] Reading time estimates
- [ ] Document statistics and insights
- [ ] Link validation and checking
- [ ] Professional documentation

### Success Metrics
- Mac App Store release
- 1000+ GitHub stars
- Active user community
- Plugin ecosystem started

---

## Long-term Vision (Post v2.0)

### Potential Directions
1. **Inkwell Pro** - Advanced features for professionals
2. **Inkwell Teams** - Collaboration features
3. **Inkwell Cloud** - Sync and backup service
4. **Inkwell Mobile** - iOS/iPadOS companion app
5. **Inkwell Editor** - Full markdown editing capabilities

### Exploration Areas
- AI-powered features (formatting, completion, translation)
- Real-time collaboration
- Version control integration
- Custom markdown extensions
- Publishing platform integration

---

## Release Strategy

### Version Numbering
- **Major (x.0.0)** - Significant feature additions or architectural changes
- **Minor (0.x.0)** - New features and enhancements
- **Patch (0.0.x)** - Bug fixes and minor improvements

### Release Cadence
- **Patch releases** - As needed for critical fixes
- **Minor releases** - Every 3-4 weeks
- **Major releases** - Every 3-4 months

### Distribution Channels
1. Direct download from website
2. Homebrew cask
3. Mac App Store (after v2.0)
4. GitHub releases

---

## Community Engagement

### Feedback Channels
- GitHub Issues for bug reports
- GitHub Discussions for feature requests
- Twitter/X for announcements
- Discord for community chat (future)

### Open Source Strategy
- Maintain transparency with public roadmap
- Accept community contributions
- Regular development updates
- Beta testing program

---

## Risk Mitigation

### Technical Risks
- **Performance degradation** - Continuous benchmarking
- **Platform changes** - Stay current with macOS betas
- **Dependency issues** - Minimal external dependencies

### Market Risks
- **Competition** - Focus on native performance advantage
- **User adoption** - Free tier with optional pro features
- **Sustainability** - Multiple revenue streams planned

---

## Success Metrics

### Key Performance Indicators
- GitHub stars and forks
- Download numbers
- User retention (telemetry-free estimation)
- Performance benchmarks vs competitors
- Community engagement levels
- App Store ratings (post-launch)

### Quality Gates
- Each release must maintain or improve performance
- No regressions in existing features
- Comprehensive test coverage
- Documentation updates with each release

---

*This roadmap is a living document and will be updated based on user feedback, technical discoveries, and market conditions.*

*Last updated: January 2025*
*Current version: v1.0.2*