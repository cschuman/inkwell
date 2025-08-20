#!/bin/bash

echo "Manual Ripple Effect Test"
echo "========================="
echo ""
echo "1. Launch Inkwell with a test file"
./build/Inkwell.app/Contents/MacOS/Inkwell test_drag.md 2>&1 | grep -E "(effect|Effect|ripple|Ripple|Drag)" &
INKWELL_PID=$!

sleep 2

echo ""
echo "2. Select Ripple effect (press Cmd+E, then '2', then Enter)"
osascript -e '
tell application "System Events"
    tell process "Inkwell"
        set frontmost to true
        delay 1
        keystroke "e" using command down
        delay 0.5
        keystroke "2"
        delay 0.5
        keystroke return
    end tell
end tell
'

echo ""
echo "3. Now manually drag a markdown file to the Inkwell window"
echo ""
echo "Expected behavior:"
echo "  - Cyan tinted overlay should appear when drag enters"
echo "  - Blue ripples should emanate from cursor position"
echo "  - Ripples should expand and fade"
echo "  - Multiple ripples as you move the cursor"
echo ""
echo "Watch the console output above for debug messages"
echo ""
echo "Press Ctrl+C to exit when done testing"

wait $INKWELL_PID