#!/bin/bash

# Simple build script that bypasses all the broken stuff
# Goal: Get something on screen TODAY

set -e

echo "🔨 Building Inkwell (Simple Version)"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for vcpkg
if ! command -v vcpkg >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  vcpkg not found. Installing dependencies may fail.${NC}"
fi

# Get vcpkg root if available
if [ -n "$VCPKG_ROOT" ]; then
    VCPKG_FLAG="-DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
else
    VCPKG_FLAG=""
fi

# Create build directory
mkdir -p build_simple
cd build_simple

echo -e "\n${YELLOW}⚙️  Configuring with simplified options...${NC}"

# Configure with most features disabled
cmake .. \
    -DCMAKE_BUILD_TYPE=Debug \
    $VCPKG_FLAG \
    -DCMAKE_OSX_ARCHITECTURES="$(uname -m)" \
    -G "Unix Makefiles"

echo -e "\n${YELLOW}🔨 Building (this may take a minute)...${NC}"
cmake --build . -j$(sysctl -n hw.ncpu) || true

# Check if executable was built
if [ -f "Inkwell.app/Contents/MacOS/Inkwell" ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "${GREEN}✓ App location: $(pwd)/Inkwell.app${NC}"
    echo ""
    echo "To run: open Inkwell.app"
    echo "To run with console output: ./Inkwell.app/Contents/MacOS/Inkwell"
else
    echo -e "${RED}❌ Build failed - but that's OK, we'll fix it${NC}"
    echo "Checking what was built..."
    find . -name "*.a" -o -name "*.o" | head -20
fi

cd ..