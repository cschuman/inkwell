# Homebrew Distribution Guide for Inkwell

This guide provides comprehensive instructions for distributing Inkwell through Homebrew on macOS.

## Overview

Inkwell is distributed as a Homebrew Cask since it's a macOS GUI application. The distribution involves:
1. Creating GitHub releases with DMG files
2. Maintaining a Homebrew tap repository
3. Updating the cask formula with new versions

## Prerequisites

- GitHub account with repository access
- Homebrew installed locally for testing
- Code signing certificate (optional but recommended)
- Apple Developer account for notarization (optional but recommended)

## Directory Structure

```
inkwell/                    # Main repository
├── scripts/
│   ├── build_release.sh    # Build and create DMG
│   ├── setup_homebrew_tap.sh
│   └── update_cask.sh      # Update cask formula
├── homebrew/
│   └── inkwell.rb          # Cask formula template
└── docs/
    └── HOMEBREW_DISTRIBUTION.md

homebrew-tap/               # Separate tap repository
└── Casks/
    └── inkwell.rb          # Published cask formula
```

## Release Process

### 1. Prepare the Release

```bash
# Update version in CMakeLists.txt
vim CMakeLists.txt  # Update VERSION

# Update version in build script
vim scripts/build_release.sh  # Update VERSION variable

# Commit version changes
git add -A
git commit -m "Bump version to X.Y.Z"
git push origin main
```

### 2. Build the Release

```bash
# Build release DMG
./scripts/build_release.sh

# Verify the DMG
open Inkwell-X.Y.Z.dmg
# Test the app thoroughly
```

### 3. Create GitHub Release

```bash
# Create git tag
git tag -a vX.Y.Z -m "Release version X.Y.Z"
git push origin vX.Y.Z

# Create release using GitHub CLI
gh release create vX.Y.Z \
  --title "Inkwell vX.Y.Z" \
  --notes "Release notes here" \
  Inkwell-X.Y.Z.dmg

# Or manually via GitHub web interface
```

### 4. Calculate SHA256

```bash
# Get SHA256 for the DMG
shasum -a 256 Inkwell-X.Y.Z.dmg
# Copy the hash for the cask formula
```

### 5. Update Homebrew Tap

```bash
# Clone or update tap repository
cd ../homebrew-tap
git pull origin main

# Update cask formula
vim Casks/inkwell.rb
# Update version, sha256, and url

# Commit and push
git add Casks/inkwell.rb
git commit -m "Update Inkwell to vX.Y.Z"
git push origin main
```

## Cask Formula Template

Create `homebrew/inkwell.rb`:

```ruby
cask "inkwell" do
  version "X.Y.Z"
  sha256 "YOUR_SHA256_HERE"

  url "https://github.com/cschuman/inkwell/releases/download/v#{version}/Inkwell-#{version}.dmg"
  name "Inkwell"
  desc "Native macOS markdown viewer with beautiful typography"
  homepage "https://github.com/cschuman/inkwell"

  auto_updates true
  depends_on macos: ">= :big_sur"

  app "Inkwell.app"

  zap trash: [
    "~/Library/Preferences/com.coreymd.inkwell.plist",
    "~/Library/Saved Application State/com.coreymd.inkwell.savedState",
  ]
end
```

## Automation Scripts

### Update Cask Script

Create `scripts/update_cask.sh`:

```bash
#!/bin/bash

VERSION=$1
DMG_FILE="Inkwell-${VERSION}.dmg"

if [ -z "$VERSION" ]; then
    echo "Usage: ./update_cask.sh VERSION"
    echo "Example: ./update_cask.sh 1.0.3"
    exit 1
fi

if [ ! -f "$DMG_FILE" ]; then
    echo "Error: $DMG_FILE not found. Build it first with ./build_release.sh"
    exit 1
fi

# Calculate SHA256
SHA256=$(shasum -a 256 "$DMG_FILE" | cut -d' ' -f1)
echo "SHA256: $SHA256"

# Create cask formula
cat > homebrew/inkwell.rb << EOF
cask "inkwell" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/cschuman/inkwell/releases/download/v#{version}/Inkwell-#{version}.dmg"
  name "Inkwell"
  desc "Native macOS markdown viewer with beautiful typography"
  homepage "https://github.com/cschuman/inkwell"

  auto_updates true
  depends_on macos: ">= :big_sur"

  app "Inkwell.app"

  zap trash: [
    "~/Library/Preferences/com.coreymd.inkwell.plist",
    "~/Library/Saved Application State/com.coreymd.inkwell.savedState",
  ]
end
EOF

echo "✅ Cask formula updated at homebrew/inkwell.rb"
echo ""
echo "Next steps:"
echo "1. Create GitHub release with $DMG_FILE"
echo "2. Copy homebrew/inkwell.rb to your tap repository"
echo "3. Commit and push the tap repository"
```

### Complete Release Script

Create `scripts/release.sh`:

```bash
#!/bin/bash

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh VERSION"
    echo "Example: ./release.sh 1.0.3"
    exit 1
fi

echo "🚀 Releasing Inkwell v${VERSION}"
echo "================================"

# Update version in CMakeLists.txt
echo "📝 Updating version in CMakeLists.txt..."
sed -i '' "s/VERSION [0-9]\+\.[0-9]\+\.[0-9]\+/VERSION ${VERSION}/" CMakeLists.txt

# Update version in build script
echo "📝 Updating version in build script..."
sed -i '' "s/VERSION=\"[0-9]\+\.[0-9]\+\.[0-9]\+\"/VERSION=\"${VERSION}\"/" scripts/build_release.sh

# Commit version changes
echo "💾 Committing version changes..."
git add CMakeLists.txt scripts/build_release.sh
git commit -m "Bump version to ${VERSION}" || echo "No changes to commit"

# Build release
echo "🔨 Building release..."
./scripts/build_release.sh

# Update cask formula
echo "📦 Updating cask formula..."
./scripts/update_cask.sh ${VERSION}

# Create git tag
echo "🏷️  Creating git tag..."
git tag -a "v${VERSION}" -m "Release version ${VERSION}"

echo ""
echo "✅ Release preparation complete!"
echo ""
echo "📋 Final steps:"
echo "1. Push changes: git push origin main --tags"
echo "2. Create GitHub release:"
echo "   gh release create v${VERSION} --title \"Inkwell v${VERSION}\" --notes \"Release notes\" Inkwell-${VERSION}.dmg"
echo "3. Update tap repository with new cask formula"
echo "4. Test installation: brew tap cschuman/tap && brew install --cask inkwell"
```

## Testing

### Local Testing

```bash
# Test cask formula locally
brew install --cask ./homebrew/inkwell.rb

# Verify installation
ls -la /Applications/Inkwell.app

# Test the app
open /Applications/Inkwell.app

# Uninstall
brew uninstall --cask inkwell
```

### Tap Testing

```bash
# Add tap
brew tap cschuman/tap

# Install from tap
brew install --cask inkwell

# Update
brew upgrade --cask inkwell

# Remove
brew uninstall --cask inkwell
brew untap cschuman/tap
```

## User Installation Instructions

### First-time Installation

```bash
# Easy one-liner
brew tap cschuman/tap && brew install --cask inkwell

# Or step by step
brew tap cschuman/tap
brew install --cask inkwell
```

### Updating

```bash
brew update
brew upgrade --cask inkwell
```

### Uninstalling

```bash
brew uninstall --cask inkwell
brew untap cschuman/tap  # Optional: remove tap
```

## Troubleshooting

### Common Issues

1. **SHA256 Mismatch**
   - Ensure DMG wasn't modified after calculating hash
   - Recalculate: `shasum -a 256 Inkwell-X.Y.Z.dmg`

2. **Download Failed**
   - Verify GitHub release URL is correct
   - Ensure DMG is attached to release

3. **Installation Failed**
   - Check macOS version compatibility
   - Verify app isn't already running

4. **Gatekeeper Issues**
   - Users may need to right-click and "Open" on first launch
   - Consider code signing and notarization

### Debug Commands

```bash
# Check tap
brew tap

# Check cask info
brew info inkwell

# Check installed casks
brew list --cask

# Reinstall
brew reinstall --cask inkwell

# Check formula
brew cat inkwell
```

## Code Signing & Notarization (Optional)

For a better user experience, consider signing and notarizing:

```bash
# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" \
  build_release/Inkwell.app

# Create signed DMG
# ... (DMG creation steps)

# Notarize
xcrun notarytool submit Inkwell-X.Y.Z.dmg \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAMID" \
  --wait

# Staple notarization
xcrun stapler staple Inkwell-X.Y.Z.dmg
```

## Release Checklist

- [ ] Update version in CMakeLists.txt
- [ ] Update version in build_release.sh
- [ ] Update CHANGELOG.md
- [ ] Build and test release locally
- [ ] Create DMG with build_release.sh
- [ ] Calculate SHA256 hash
- [ ] Create git tag
- [ ] Push tag to GitHub
- [ ] Create GitHub release with DMG
- [ ] Update cask formula with new version/hash
- [ ] Push updated cask to tap repository
- [ ] Test installation from tap
- [ ] Update documentation if needed
- [ ] Announce release (optional)

## Maintenance

### Regular Tasks

- Monitor GitHub issues for installation problems
- Keep tap repository up to date
- Test each release on multiple macOS versions
- Update minimum macOS version as needed
- Consider adding auto-update mechanism

### Version Numbering

Follow semantic versioning:
- MAJOR.MINOR.PATCH (e.g., 1.2.3)
- MAJOR: Breaking changes
- MINOR: New features, backwards compatible
- PATCH: Bug fixes, backwards compatible

## Resources

- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [Apple Notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Semantic Versioning](https://semver.org/)