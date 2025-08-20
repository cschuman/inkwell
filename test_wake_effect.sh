#!/bin/bash

echo "Testing Gravitational Wake effect..."
echo "Opening Inkwell with test document..."

# Launch app in background
./build/Inkwell.app/Contents/MacOS/Inkwell test_drag_drop.md &
APP_PID=$!

# Wait a moment for startup
sleep 2

# Simulate drag operation using AppleScript
osascript <<EOF
tell application "System Events"
    tell process "Inkwell"
        set frontmost to true
        delay 1
        -- Simulate dragging a file
        -- This would normally require actual file drag, just testing startup
    end tell
end tell
EOF

# Give it a moment
sleep 2

# Kill the app
kill $APP_PID 2>/dev/null

echo "Test completed - check for crashes"