#!/bin/bash

echo "Testing drag operation with Gravitational Wake effect..."

# Create a test file to drag
echo "Test content" > /tmp/test_drag_file.txt

# Launch app with Gravitational Wake effect selected
osascript <<'EOF'
tell application "Terminal"
    do script "cd /Users/corey/Markdown/corey-md-cpp && ./build/Inkwell.app/Contents/MacOS/Inkwell test_drag_drop.md"
end tell

delay 3

tell application "System Events"
    tell process "Inkwell"
        set frontmost to true
        delay 1
        
        -- Select Gravitational Wake effect (4th in list)
        keystroke "p" using {command down, shift down}
        delay 0.5
        type text "drag effect"
        delay 0.5
        key code 125 -- down arrow
        key code 125 -- down arrow  
        key code 125 -- down arrow
        key code 36 -- return
        delay 1
    end tell
end tell

-- Note: Can't actually simulate file drag programmatically
-- Would need manual testing or a UI testing framework
EOF

echo "App launched with Gravitational Wake effect"
echo "Please manually drag a file to test for crashes"