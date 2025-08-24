# Homebrew Tap Update Instructions

The release v1.0.7 has been successfully created! To complete the Homebrew distribution:

## 1. Create/Update Your Homebrew Tap Repository

If you haven't created a tap repository yet:
```bash
# Go to https://github.com/new
# Create a new repository named "homebrew-tap"
# Then clone it locally:
cd ~/Markdown
git clone https://github.com/cschuman/homebrew-tap.git
cd homebrew-tap
mkdir -p Casks
```

## 2. Copy the Updated Cask Formula

```bash
# Copy the cask formula to your tap
cp ~/Markdown/corey-md-cpp/homebrew/inkwell.rb ~/Markdown/homebrew-tap/Casks/inkwell.rb

# Go to tap directory
cd ~/Markdown/homebrew-tap

# Commit and push
git add Casks/inkwell.rb
git commit -m "Update Inkwell to v1.0.7"
git push origin main
```

## 3. Test the Installation

```bash
# Remove any existing installation
brew uninstall --cask inkwell 2>/dev/null

# Add your tap (if not already added)
brew tap cschuman/tap

# Install Inkwell
brew install --cask inkwell

# Verify it works
open /Applications/Inkwell.app
```

## 4. Verify the Release

- GitHub Release: https://github.com/cschuman/inkwell/releases/tag/v1.0.7
- DMG SHA256: `3c6a8b4781ce1d7a69167ea19095a72c07780fb9b3fa066d42909ebb6a3d1a65`
- Version: 1.0.7
- File Size: 660 KB

## Cask Formula Details

The cask formula at `homebrew/inkwell.rb` has been updated with:
- Version: 1.0.7
- SHA256: 3c6a8b4781ce1d7a69167ea19095a72c07780fb9b3fa066d42909ebb6a3d1a65
- Download URL: https://github.com/cschuman/inkwell/releases/download/v1.0.7/Inkwell-1.0.7.dmg

Once you update your tap repository, users will be able to install Inkwell via Homebrew!