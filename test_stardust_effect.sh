#!/bin/bash

echo "Stardust Effect Test"
echo "===================="
echo ""

# Kill any existing instances
pkill -f "Inkwell.app" 2>/dev/null
sleep 1

echo "1. Launching Inkwell..."
./build/Inkwell.app/Contents/MacOS/Inkwell test_drag.md 2>&1 | grep -E "(effect|Effect|particle|Particle|Stardust|Drag)" &
INKWELL_PID=$!

sleep 2

echo ""
echo "2. Selecting Stardust effect..."
osascript -e '
tell application "System Events"
    tell process "Inkwell"
        set frontmost to true
        delay 1
        keystroke "e" using command down
        delay 0.5
        keystroke "3"
        delay 0.5
        keystroke return
    end tell
end tell
'

echo ""
echo "3. Ready for testing!"
echo ""
echo "Now drag a markdown file to the window multiple times."
echo ""
echo "Expected behavior:"
echo "  - Purple/pink tinted overlay on drag enter"
echo "  - Glowing particles following cursor"
echo "  - Particle burst on drop"
echo "  - Should work repeatedly (not just once)"
echo ""
echo "Press Ctrl+C to exit when done testing"

wait $INKWELL_PID