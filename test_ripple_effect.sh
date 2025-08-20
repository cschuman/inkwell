#!/bin/bash

# Kill any existing Inkwell instances
pkill -f "Inkwell.app" 2>/dev/null

# Launch Inkwell with a test file
echo "Launching Inkwell..."
./build/Inkwell.app/Contents/MacOS/Inkwell test_drag.md &
INKWELL_PID=$!

sleep 2

# Simulate drag operations
echo "Testing ripple effect..."
osascript -e '
tell application "System Events"
    tell process "Inkwell"
        set frontmost to true
        delay 1
        
        -- Open effect selector
        keystroke "e" using command down
        delay 0.5
        
        -- Select Ripple effect 
        keystroke "Ripple"
        keystroke return
        delay 1
    end tell
end tell
'

echo "Ripple effect selected. Now try dragging a markdown file to the window."
echo "You should see:"
echo "- Cyan/teal tinted overlay on drag enter"
echo "- Blue ripples emanating from cursor position"
echo "- Ripples expanding and fading as you move"
echo ""
echo "Press Enter to continue..."
read

# Clean up
kill $INKWELL_PID 2>/dev/null