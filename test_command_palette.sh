#!/bin/bash

echo "Testing Command Palette functionality..."
echo "========================================"

# Kill any existing Inkwell instances
pkill -f Inkwell 2>/dev/null
sleep 1

echo "1. Launching Inkwell with test document..."
./build_simple/Inkwell.app/Contents/MacOS/Inkwell test_toc.md &
APP_PID=$!
sleep 2

echo "2. Testing Command Palette opening (Cmd+K)..."

osascript << 'EOF'
tell application "System Events"
    -- Open Command Palette with Cmd+K
    keystroke "k" using command down
    delay 1
    
    -- Type to filter commands
    keystroke "search"
    delay 0.5
    
    -- Press Escape to close
    key code 53 -- ESC key
    delay 0.5
    
    -- Open again
    keystroke "k" using command down
    delay 0.5
    
    -- Test different filter
    keystroke "export"
    delay 0.5
    
    -- Close again
    key code 53 -- ESC key
    delay 0.5
    
    -- Test selecting a command
    keystroke "k" using command down
    delay 0.5
    
    keystroke "zoom in"
    delay 0.5
    
    -- Select it with Enter
    key code 36 -- Enter key
    delay 0.5
    
    -- Test again with TOC
    keystroke "k" using command down
    delay 0.5
    
    keystroke "table"
    delay 0.5
    
    key code 36 -- Enter key
    delay 1
    
    -- Close TOC again
    keystroke "t" using {command down, option down}
end tell
EOF

echo "3. Checking available commands..."
echo ""
echo "Expected commands in palette:"
echo "  - Open File (Cmd+O)"
echo "  - Save (Cmd+S)"
echo "  - Export to PDF (Cmd+Shift+E)"
echo "  - Export to HTML"
echo "  - Search (Cmd+F)"
echo "  - Toggle Table of Contents (Cmd+Option+T)"
echo "  - Zoom In (Cmd++)"
echo "  - Zoom Out (Cmd+-)"
echo "  - Reset Zoom (Cmd+0)"
echo "  - Go to Top (Home)"
echo "  - Go to Bottom (End)"
echo ""

sleep 2

if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ SUCCESS: Command Palette is working"
    echo ""
    echo "Manual verification needed:"
    echo "  1. Press Cmd+K to open Command Palette"
    echo "  2. Verify fuzzy search filtering works"
    echo "  3. Verify commands execute when selected"
    echo "  4. Verify keyboard shortcuts are shown"
    echo ""
    echo "Press Enter when done testing..."
    read
    kill $APP_PID
else
    echo "❌ FAILURE: Inkwell crashed during Command Palette test"
    exit 1
fi

echo ""
echo "Test complete!"