# Inkwell Recovery Plan

## Current Status
- Basic markdown viewing works via NSTextView
- Good macOS integration (drag/drop, command palette, file watching)
- Over-engineered with unused optimization layers
- Test infrastructure broken

## Recovery Phases

### Phase 1: Clean House (Immediate)
- [x] Remove test scripts and temporary files
- [x] Consolidate build directories
- [ ] Fix test infrastructure
- [ ] Remove unused code

### Phase 2: Simplify Architecture (Week 1)
Choose ONE path:

#### Option A: Embrace Simplicity (Recommended)
- Accept NSTextView as the renderer
- Remove Metal, SIMD, memory pool code
- Focus on polish and features
- Ship as "Inkwell Lite"

#### Option B: Implement Architecture
- Actually implement Metal rendering
- Use memory pools in parser
- Make virtual DOM work
- Ship as "Inkwell Pro"

### Phase 3: Focus Features (Week 2)
Core features to perfect:
1. File watching and auto-reload
2. Table of contents navigation
3. Command palette
4. Search functionality
5. Export capabilities

### Phase 4: Polish (Week 3)
- Comprehensive test coverage
- Performance profiling
- Documentation update
- Release 1.0

## Decision Required
**Which path: Simple or Performance?**

The honest answer: Go simple. You have a working markdown viewer. Polish it and ship it.