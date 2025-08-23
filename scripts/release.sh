#!/bin/bash

set -e

VERSION=$1
RELEASE_NOTES=""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$VERSION" ]; then
    echo -e "${RED}Usage: ./release.sh VERSION [RELEASE_NOTES]${NC}"
    echo "Example: ./release.sh 1.0.3 \"Bug fixes and performance improvements\""
    exit 1
fi

if [ ! -z "$2" ]; then
    RELEASE_NOTES="$2"
fi

echo -e "${BLUE}🚀 Releasing Inkwell v${VERSION}${NC}"
echo "================================"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update version in CMakeLists.txt
echo -e "${BLUE}📝 Updating version in CMakeLists.txt...${NC}"
sed -i '' "s/VERSION [0-9]\+\.[0-9]\+\.[0-9]\+/VERSION ${VERSION}/" CMakeLists.txt

# Update version in build script
echo -e "${BLUE}📝 Updating version in build script...${NC}"
sed -i '' "s/VERSION=\"[0-9]\+\.[0-9]\+\.[0-9]\+\"/VERSION=\"${VERSION}\"/" scripts/build_release.sh

# Update version in Info.plist
echo -e "${BLUE}📝 Updating version in Info.plist...${NC}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" resources/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" resources/Info.plist 2>/dev/null || true

# Commit version changes
echo -e "${BLUE}💾 Committing version changes...${NC}"
git add CMakeLists.txt scripts/build_release.sh resources/Info.plist 2>/dev/null || true
git commit -m "Bump version to ${VERSION}" || echo "No changes to commit"

# Build release
echo -e "${BLUE}🔨 Building release...${NC}"
./scripts/build_release.sh

if [ ! -f "Inkwell-${VERSION}.dmg" ]; then
    echo -e "${RED}❌ Build failed! DMG not created.${NC}"
    exit 1
fi

# Update cask formula
echo -e "${BLUE}📦 Updating cask formula...${NC}"
./scripts/update_cask.sh ${VERSION}

# Create git tag
echo -e "${BLUE}🏷️  Creating git tag...${NC}"
git tag -a "v${VERSION}" -m "Release version ${VERSION}" 2>/dev/null || {
    echo -e "${YELLOW}Tag already exists, skipping...${NC}"
}

echo ""
echo -e "${GREEN}✅ Release preparation complete!${NC}"
echo ""
echo -e "${BLUE}📋 Final steps to complete the release:${NC}"
echo ""
echo "1. Push changes and tags:"
echo -e "   ${YELLOW}git push origin main --tags${NC}"
echo ""
echo "2. Create GitHub release:"
if [ -z "$RELEASE_NOTES" ]; then
    echo -e "   ${YELLOW}gh release create v${VERSION} \\
      --title \"Inkwell v${VERSION}\" \\
      --generate-notes \\
      Inkwell-${VERSION}.dmg${NC}"
else
    echo -e "   ${YELLOW}gh release create v${VERSION} \\
      --title \"Inkwell v${VERSION}\" \\
      --notes \"${RELEASE_NOTES}\" \\
      Inkwell-${VERSION}.dmg${NC}"
fi
echo ""
echo "3. Update tap repository:"
echo -e "   ${YELLOW}cp homebrew/inkwell.rb ../homebrew-tap/Casks/inkwell.rb
   cd ../homebrew-tap
   git add Casks/inkwell.rb
   git commit -m \"Update Inkwell to v${VERSION}\"
   git push origin main${NC}"
echo ""
echo "4. Test installation:"
echo -e "   ${YELLOW}brew tap cschuman/tap
   brew install --cask inkwell${NC}"
echo ""
echo -e "${GREEN}📦 Release artifacts:${NC}"
echo "   - DMG: Inkwell-${VERSION}.dmg ($(du -h Inkwell-${VERSION}.dmg | cut -f1))"
echo "   - App: build_release/Inkwell.app"
echo "   - Cask: homebrew/inkwell.rb"