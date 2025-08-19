#!/bin/bash

echo "Testing Table of Contents functionality..."
echo "=========================================="

# Kill any existing Inkwell instances
pkill -f Inkwell 2>/dev/null
sleep 1

echo "1. Launching Inkwell with test document containing headings..."
./build_simple/Inkwell.app/Contents/MacOS/Inkwell test_toc.md &
APP_PID=$!
sleep 2

echo "2. Testing TOC toggle with keyboard shortcut (Cmd+Option+T)..."

osascript << 'EOF'
tell application "System Events"
    -- Toggle TOC with Cmd+Option+T
    keystroke "t" using {command down, option down}
    delay 1
    
    -- The TOC should now be visible
    -- Try clicking on an item (this won't work in script but tests the UI)
    
    -- Toggle TOC again to hide it
    keystroke "t" using {command down, option down}
    delay 1
end tell
EOF

echo "3. Testing TOC toggle via Command Palette..."

osascript << 'EOF'
tell application "System Events"
    -- Open Command Palette with Cmd+K
    keystroke "k" using command down
    delay 0.5
    
    -- Type "toc" to filter commands
    keystroke "toc"
    delay 0.5
    
    -- Press Enter to select "Toggle Table of Contents"
    key code 36 -- Enter key
    delay 1
    
    -- TOC should be visible now
    
    -- Close it again
    keystroke "t" using {command down, option down}
end tell
EOF

echo "4. Checking if app is still running..."
sleep 1

if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ SUCCESS: Inkwell is still running"
    echo "5. Manual verification needed:"
    echo "   - Check if TOC sidebar appears/disappears when toggled"
    echo "   - Check if TOC shows document headings in a tree structure"
    echo "   - Check if clicking TOC items scrolls to the heading"
    echo ""
    echo "Press Cmd+Option+T in Inkwell to test the TOC manually."
    echo "Press Enter here when done testing..."
    read
    kill $APP_PID
else
    echo "❌ FAILURE: Inkwell crashed during TOC test"
    exit 1
fi

echo ""
echo "Test complete!"