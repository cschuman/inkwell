# Project Structure

```
inkwell/
├── src/                    # Source code
│   ├── core/              # Core functionality (C++)
│   ├── platform/          # Platform-specific code
│   │   └── macos/        # macOS integration (Objective-C++)
│   ├── rendering/         # Text rendering
│   ├── ui/               # User interface components
│   └── effects/          # Visual effects
│
├── include/               # Header files (mirrors src/)
│   ├── core/
│   ├── platform/
│   ├── rendering/
│   ├── ui/
│   └── effects/
│
├── tests/                 # Unit tests
├── resources/             # App resources (Info.plist, icons)
├── scripts/               # Build and utility scripts
│   ├── build.sh
│   ├── build_release.sh
│   └── setup_homebrew_tap.sh
│
├── docs/                  # Documentation
│   ├── CHANGELOG.md
│   ├── ROADMAP.md
│   └── ...
│
├── archive/               # Old releases and artifacts
├── build/                 # Build output (git-ignored)
├── vcpkg_installed/       # Dependencies (git-ignored)
│
├── CMakeLists.txt         # Build configuration
├── vcpkg.json            # Dependency manifest
├── README.md             # Project overview
├── LICENSE               # MIT License
└── CLAUDE.md             # AI assistant guidelines
```

## Key Directories

- **src/core**: Markdown parsing, document model, TOC generation
- **src/platform/macos**: Cocoa bridge, file watching, app lifecycle
- **src/rendering**: Text layout and rendering
- **src/ui**: Command palette, window management, design system
- **src/effects**: Drag & drop visual effects
- **tests**: Unit test suite
- **scripts**: Automation scripts for building and deployment
- **docs**: Project documentation and planning