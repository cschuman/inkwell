#!/bin/bash

echo "🚀 Building Inkwell Release Version"
echo "===================================="

VERSION="0.2.0"
BUILD_DIR="build_release"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Configure with Release mode
echo "⚙️  Configuring Release build..."
cmake -B $BUILD_DIR -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake 2>/dev/null || \
cmake -B $BUILD_DIR -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

# Build
echo "🔨 Building (this may take a minute)..."
cmake --build $BUILD_DIR --config Release -j$(sysctl -n hw.ncpu)

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Create DMG for distribution
    echo "📦 Creating DMG installer..."
    
    # Create a temporary directory for DMG contents
    DMG_DIR="/tmp/Inkwell-$VERSION"
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR"
    
    # Copy app to DMG directory
    cp -R "$BUILD_DIR/Inkwell.app" "$DMG_DIR/"
    
    # Create a symbolic link to Applications
    ln -s /Applications "$DMG_DIR/Applications"
    
    # Create DMG
    DMG_NAME="Inkwell-$VERSION.dmg"
    rm -f "$DMG_NAME"
    
    hdiutil create -volname "Inkwell $VERSION" \
                   -srcfolder "$DMG_DIR" \
                   -ov -format UDZO \
                   "$DMG_NAME"
    
    # Clean up
    rm -rf "$DMG_DIR"
    
    if [ -f "$DMG_NAME" ]; then
        echo "✅ DMG created: $DMG_NAME"
        echo ""
        echo "📊 Release Info:"
        echo "  Version: $VERSION"
        echo "  App: $BUILD_DIR/Inkwell.app"
        echo "  DMG: $DMG_NAME"
        echo "  Size: $(du -h "$DMG_NAME" | cut -f1)"
    else
        echo "❌ DMG creation failed"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi