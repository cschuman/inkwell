#!/bin/bash

echo "Testing Drag & Drop functionality..."
echo "======================================="
echo ""

# First, launch the app
echo "1. Launching Inkwell..."
open ./build/Inkwell.app

sleep 2

# Test opening a file via command line (simulates drag to icon)
echo "2. Testing file open via command line (simulates drag to app icon)..."
./build/Inkwell.app/Contents/MacOS/Inkwell test_drag_drop.md &
APP_PID=$!

sleep 2

# Check if app is running
if ps -p $APP_PID > /dev/null; then
    echo "✅ App launched successfully with file"
else
    echo "❌ App failed to launch with file"
fi

echo ""
echo "3. Manual Test Required:"
echo "   - Drag 'test_drag_drop.md' onto the Inkwell window"
echo "   - The file should open immediately"
echo "   - Try dragging different file types (.txt, .markdown)"
echo ""
echo "4. Also test:"
echo "   - Drag file onto app icon in Dock"
echo "   - Drag multiple files (should open first one)"
echo ""

# Kill the test app after a moment
sleep 3
pkill -f Inkwell

echo "Test completed. Please perform manual drag & drop tests."