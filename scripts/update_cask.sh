#!/bin/bash

VERSION=$1
DMG_FILE="Inkwell-${VERSION}.dmg"

if [ -z "$VERSION" ]; then
    echo "Usage: ./update_cask.sh VERSION"
    echo "Example: ./update_cask.sh 1.0.3"
    exit 1
fi

if [ ! -f "$DMG_FILE" ]; then
    echo "Error: $DMG_FILE not found. Build it first with ./scripts/build_release.sh"
    exit 1
fi

# Calculate SHA256
SHA256=$(shasum -a 256 "$DMG_FILE" | cut -d' ' -f1)
echo "📊 Version: ${VERSION}"
echo "🔒 SHA256: ${SHA256}"

# Create homebrew directory if it doesn't exist
mkdir -p ../homebrew

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
echo "📋 Next steps:"
echo "1. Create GitHub release with $DMG_FILE:"
echo "   gh release create v${VERSION} --title \"Inkwell v${VERSION}\" --notes \"Release notes\" ${DMG_FILE}"
echo ""
echo "2. Copy to tap repository:"
echo "   cp homebrew/inkwell.rb ../homebrew-tap/Casks/inkwell.rb"
echo ""
echo "3. Commit and push tap:"
echo "   cd ../homebrew-tap"
echo "   git add Casks/inkwell.rb"
echo "   git commit -m \"Update Inkwell to v${VERSION}\""
echo "   git push origin main"