# Homebrew Submission Guide for Inkwell

## Overview
There are two ways to distribute macOS apps via Homebrew:
1. **Homebrew Cask** (for GUI apps distributed as .app bundles)
2. **Personal Tap** (easier to start with)

## Option 1: Personal Homebrew Tap (Recommended to Start)

This is the easiest way to get started and test your formula.

### Steps:

1. **Create a new GitHub repository** named `homebrew-tap` in your account:
   ```bash
   # Go to https://github.com/new
   # Name: homebrew-tap
   # Description: Homebrew tap for Inkwell
   ```

2. **Clone the repository locally**:
   ```bash
   git clone https://github.com/cschuman/homebrew-tap.git
   cd homebrew-tap
   ```

3. **Copy the Cask formula**:
   ```bash
   mkdir -p Casks
   cp /path/to/inkwell/homebrew/inkwell.rb Casks/inkwell.rb
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add Inkwell cask"
   git push
   ```

5. **Users can now install Inkwell**:
   ```bash
   brew tap cschuman/tap
   brew install --cask cschuman/tap/inkwell
   ```

## Option 2: Submit to Official Homebrew Cask

For wider distribution, you can submit to the official Homebrew Cask repository.

### Prerequisites:
- App must be stable and useful to others
- Must have a proper versioned release
- Must be signed (for Gatekeeper) - currently not signed
- Should have decent download numbers

### Steps:

1. **First, upload the DMG to the GitHub release** (if not already done)

2. **Test the formula locally**:
   ```bash
   # Copy formula to local cask directory
   cp homebrew/inkwell.rb $(brew --repository)/Library/Taps/homebrew/homebrew-cask/Casks/
   
   # Test installation
   brew install --cask inkwell
   
   # Test the app works
   open /Applications/Inkwell.app
   
   # Uninstall to clean up
   brew uninstall --cask inkwell
   ```

3. **Fork homebrew-cask**:
   ```bash
   # Go to https://github.com/Homebrew/homebrew-cask
   # Click Fork
   ```

4. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/homebrew-cask.git
   cd homebrew-cask
   ```

5. **Create a branch**:
   ```bash
   git checkout -b add-inkwell
   ```

6. **Add the cask**:
   ```bash
   cp /path/to/inkwell/homebrew/inkwell.rb Casks/inkwell.rb
   ```

7. **Run audit checks**:
   ```bash
   brew audit --new-cask inkwell
   brew style --fix Casks/inkwell.rb
   ```

8. **Commit and push**:
   ```bash
   git add Casks/inkwell.rb
   git commit -m "Add Inkwell 0.2.0"
   git push origin add-inkwell
   ```

9. **Create Pull Request**:
   - Go to your fork on GitHub
   - Click "Pull Request"
   - Follow the PR template

## Important Notes

### For Personal Tap:
- ✅ You control updates
- ✅ No review process
- ✅ Can update immediately
- ❌ Users need to know about your tap
- ❌ Less discoverable

### For Official Homebrew:
- ✅ Wide distribution
- ✅ Discoverable via `brew search`
- ✅ Community trust
- ❌ Review process can take time
- ❌ Must meet quality standards
- ❌ Need to sign the app (Gatekeeper)

## Current Status

**Inkwell is ready for a personal tap but needs the following for official Homebrew:**

1. ❌ **Code signing** - The app needs to be signed with an Apple Developer certificate
2. ✅ **Stable release** - v0.2.0 is stable
3. ✅ **Versioned releases** - Using semantic versioning
4. ✅ **DMG distribution** - Have a proper DMG
5. ❌ **Unique name** - Need to check if "inkwell" is available
6. ✅ **Documentation** - README and docs are good

## Quick Start with Personal Tap

For now, the easiest path is:

```bash
# Create homebrew-tap repo on GitHub
# Then:
mkdir homebrew-tap
cd homebrew-tap
mkdir Casks
cat > Casks/inkwell.rb << 'EOF'
cask "inkwell" do
  version "0.2.0"
  sha256 "574fe1627e605179c2d47205aaaddcab13f9c739e3554503df17c72af9953c27"

  url "https://github.com/cschuman/inkwell/releases/download/v#{version}/Inkwell-#{version}.dmg"
  name "Inkwell"
  desc "Native macOS markdown viewer with high performance"
  homepage "https://github.com/cschuman/inkwell"

  app "Inkwell.app"

  zap trash: [
    "~/Library/Preferences/com.inkwell.markdown.plist",
    "~/Library/Saved Application State/com.inkwell.markdown.savedState",
  ]
end
EOF

git init
git add .
git commit -m "Add Inkwell cask"
git remote add origin https://github.com/cschuman/homebrew-tap.git
git push -u origin main
```

Then users can install with:
```bash
brew tap cschuman/tap
brew install --cask inkwell
```