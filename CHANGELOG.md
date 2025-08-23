# Changelog

All notable changes to Inkwell will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive Homebrew distribution documentation
- Automated release scripts (`release.sh`, `update_cask.sh`)
- GitHub Actions workflow for automated releases
- Release checklist documentation

## [1.0.6] - 2024-08-22

### Added
- Ultra-minimal window interface with reduced chrome
- Version info moved to status bar
- Subtle close button at 60% opacity

### Changed
- Window style to minimize distractions
- Hidden title bar for cleaner appearance

## [1.0.5] - 2024-08-22

### Added
- Custom app icon with fountain pen design
- Finder integration for markdown files
- Obsidian YAML frontmatter support
- SF Symbol icons in UI elements

### Fixed
- macOS API deprecation warnings
- Modern macOS compatibility issues

## [1.0.4] - 2024-08-22

### Added
- Theme settings with Light/Dark/System modes
- Settings persistence across launches
- Theme override capability independent of system settings
- Menu indicators for selected theme

### Changed
- Improved Bauhaus-inspired typography system
- Enhanced code block rendering with full-width backgrounds
- Better list spacing using golden ratio

### Fixed
- Initial text color on startup in dark mode
- Background color updates when switching themes
- Theme persistence across app restarts

## [1.0.3] - 2024-08-21

### Added
- Bauhaus-inspired design system
- Golden ratio typography scale
- Beautiful serif and sans-serif font combinations
- Monochromatic color palettes

### Changed
- Complete UI overhaul with focus on typography
- Improved readability and visual hierarchy
- Enhanced code block styling

## [1.0.2] - 2024-08-20

### Fixed
- Critical launch issue with missing libmd4c.0.dylib
- Force static linking of md4c library

## [1.0.1] - 2024-08-20

### Fixed
- Application crash on launch from /Applications
- Binary dependency issues

## [1.0.0] - 2024-08-20

### Added
- Initial stable release
- Native macOS markdown viewer
- Fast markdown parsing with md4c
- File watching for auto-refresh
- Drag & drop support with visual effects
- Command palette (⌘K)
- Smooth scrolling
- Dark mode support

### Technical
- Complete architectural rewrite
- Removed 5,000+ lines of unused code
- Simplified codebase for maintainability
- Binary size: 549 KB

## [0.2.0] - 2024-08-19

### Added
- Beta release with core features
- Basic markdown rendering
- File watching capability

## [0.1.0] - 2024-08-18

### Added
- Initial alpha release
- Basic markdown parsing
- macOS application structure

---

## Release Types

- **Major (X.0.0)**: Breaking changes, major features, architectural changes
- **Minor (0.X.0)**: New features, enhancements, backward compatible
- **Patch (0.0.X)**: Bug fixes, small improvements, backward compatible

## How to Release

1. Update this CHANGELOG.md with version and date
2. Run `./scripts/release.sh X.Y.Z "Release description"`
3. Follow the prompts to complete the release
4. Update Homebrew tap repository