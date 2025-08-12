#!/bin/bash

set -e

echo "🚀 Building Inkwell for macOS"
echo "======================================"

# Update build number
if [ -f "update_build.sh" ]; then
    echo "📝 Updating build number..."
    ./update_build.sh
fi

# Check for required tools
command -v cmake >/dev/null 2>&1 || { echo "❌ CMake is required but not installed. Aborting." >&2; exit 1; }
command -v vcpkg >/dev/null 2>&1 || { echo "⚠️  vcpkg not found. Please install vcpkg first." >&2; exit 1; }

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get vcpkg root
VCPKG_ROOT="${VCPKG_ROOT:-$(vcpkg integrate install | grep -oE '/[^"]+' | head -1)}"
if [ -z "$VCPKG_ROOT" ]; then
    echo -e "${RED}❌ Could not determine VCPKG_ROOT${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found vcpkg at: $VCPKG_ROOT${NC}"

# Install dependencies
echo -e "\n${YELLOW}📦 Installing dependencies...${NC}"
vcpkg install

# Create build directory
mkdir -p build
cd build

# Configure with CMake
echo -e "\n${YELLOW}⚙️  Configuring project...${NC}"
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -G "Unix Makefiles"

# Build
echo -e "\n${YELLOW}🔨 Building...${NC}"
cmake --build . -j$(sysctl -n hw.ncpu)

# Run tests
echo -e "\n${YELLOW}🧪 Running tests...${NC}"
ctest --output-on-failure || true

# Create app bundle
echo -e "\n${YELLOW}📦 Creating app bundle...${NC}"
if [ -f "Inkwell" ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "\n${YELLOW}📱 Application built at: $(pwd)/Inkwell.app${NC}"
    
    # Optional: Install to /Applications
    read -p "Install to /Applications? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing to /Applications...${NC}"
        cmake --install . --prefix /Applications
        echo -e "${GREEN}✓ Installed successfully!${NC}"
    fi
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}✨ Done!${NC}"
echo "Run the app with: open Inkwell.app"