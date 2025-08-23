# Inkwell Release Checklist

Use this checklist for each release to ensure a smooth distribution process.

## Pre-Release Preparation

### Code Quality
- [ ] All tests passing
- [ ] No compiler warnings
- [ ] Code reviewed and cleaned up
- [ ] Debug code removed or disabled
- [ ] Performance tested on both Intel and Apple Silicon

### Documentation
- [ ] README.md updated with new features
- [ ] CHANGELOG.md updated with release notes
- [ ] API documentation updated (if applicable)
- [ ] User guide updated (if needed)

### Version Updates
- [ ] Version in `CMakeLists.txt` updated
- [ ] Version in `scripts/build_release.sh` updated
- [ ] Version in `resources/Info.plist` updated
- [ ] Copyright year updated (if new year)

## Build & Package

### Build Process
- [ ] Clean build directory: `rm -rf build_release`
- [ ] Run release build: `./scripts/build_release.sh`
- [ ] DMG created successfully
- [ ] DMG file size reasonable (< 2MB expected)

### Testing
- [ ] Install from DMG on clean system
- [ ] App launches without crashes
- [ ] Basic functionality tested:
  - [ ] Open markdown file
  - [ ] Drag and drop works
  - [ ] Command palette (⌘K) works
  - [ ] Theme switching works
  - [ ] File watching works
- [ ] Test on macOS versions:
  - [ ] macOS 14 (Sonoma)
  - [ ] macOS 13 (Ventura)
  - [ ] macOS 12 (Monterey)
  - [ ] macOS 11 (Big Sur)
- [ ] Test on architectures:
  - [ ] Apple Silicon (M1/M2)
  - [ ] Intel

## GitHub Release

### Repository
- [ ] All changes committed
- [ ] Changes pushed to main branch
- [ ] CI/CD passing (if configured)

### Create Release
- [ ] Create git tag: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
- [ ] Push tag: `git push origin vX.Y.Z`
- [ ] Create GitHub release via CLI or web
- [ ] Upload DMG to release
- [ ] Release notes written:
  - [ ] New features listed
  - [ ] Bug fixes mentioned
  - [ ] Breaking changes highlighted
  - [ ] Download instructions included
  - [ ] Known issues documented

### Release Notes Template
```markdown
## What's New
- Feature 1
- Feature 2

## Improvements
- Performance enhancement
- UI refinement

## Bug Fixes
- Fixed issue #XX
- Fixed crash when...

## Download
**[Inkwell-X.Y.Z.dmg](link)** (size)

## Installation
1. Download the DMG file
2. Open and drag Inkwell to Applications
3. Right-click and select "Open" on first launch

## Homebrew Installation
\`\`\`bash
brew tap cschuman/tap
brew install --cask inkwell
\`\`\`
```

## Homebrew Distribution

### Update Cask
- [ ] Calculate SHA256: `shasum -a 256 Inkwell-X.Y.Z.dmg`
- [ ] Run update script: `./scripts/update_cask.sh X.Y.Z`
- [ ] Verify cask formula in `homebrew/inkwell.rb`

### Update Tap Repository
- [ ] Clone/pull tap repo: `cd ../homebrew-tap && git pull`
- [ ] Copy cask: `cp ../inkwell/homebrew/inkwell.rb Casks/`
- [ ] Commit: `git commit -am "Update Inkwell to vX.Y.Z"`
- [ ] Push: `git push origin main`

### Test Homebrew Installation
- [ ] Remove existing: `brew uninstall --cask inkwell`
- [ ] Update tap: `brew tap cschuman/tap`
- [ ] Install fresh: `brew install --cask inkwell`
- [ ] Verify version: `open /Applications/Inkwell.app`
- [ ] Test upgrade: `brew upgrade --cask inkwell`

## Post-Release

### Communication
- [ ] Update project website (if applicable)
- [ ] Post release announcement (if applicable)
- [ ] Respond to user feedback
- [ ] Monitor GitHub issues

### Analytics
- [ ] Check download statistics
- [ ] Monitor crash reports (if configured)
- [ ] Review user feedback

### Planning
- [ ] Create milestone for next release
- [ ] Triage issues for next version
- [ ] Update project roadmap

## Rollback Plan

If critical issues are found:

1. **Remove Release**
   ```bash
   gh release delete vX.Y.Z
   git tag -d vX.Y.Z
   git push --delete origin vX.Y.Z
   ```

2. **Revert Tap**
   ```bash
   cd ../homebrew-tap
   git revert HEAD
   git push origin main
   ```

3. **Communicate**
   - Post issue about rollback
   - Notify users of known issues
   - Provide workaround if possible

## Quick Commands Reference

```bash
# Full release process
./scripts/release.sh X.Y.Z "Release notes here"

# Manual release
./scripts/build_release.sh
./scripts/update_cask.sh X.Y.Z
git tag -a vX.Y.Z -m "Release X.Y.Z"
git push origin main --tags
gh release create vX.Y.Z --title "Inkwell vX.Y.Z" Inkwell-X.Y.Z.dmg

# Test installation
brew tap cschuman/tap
brew install --cask inkwell
brew upgrade --cask inkwell
brew uninstall --cask inkwell
```

## Troubleshooting

### Build Issues
- Ensure vcpkg is installed and VCPKG_ROOT is set
- Check CMake version (>= 3.20 required)
- Verify Xcode command line tools installed

### DMG Issues
- Check disk space
- Verify app bundle structure
- Test with Disk Utility

### Homebrew Issues
- Verify SHA256 matches exactly
- Check GitHub release URL is accessible
- Ensure DMG is attached to release
- Test with `brew install --debug --verbose`

### Signing Issues (Future)
- Verify Developer ID certificate
- Check notarization status
- Staple notarization to DMG

## Notes

- Keep release sizes small (target < 1MB)
- Test on clean VMs when possible
- Consider beta releases for major changes
- Maintain backward compatibility when possible
- Document breaking changes clearly