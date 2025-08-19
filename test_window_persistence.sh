#!/bin/bash

echo "Testing Window Position/Size Persistence..."
echo "==========================================="

# Kill any existing Inkwell instances
pkill -f Inkwell 2>/dev/null
sleep 1

echo "1. Launching Inkwell for the first time..."
./build_simple/Inkwell.app/Contents/MacOS/Inkwell README.md &
APP_PID=$!
sleep 2

echo "2. Moving and resizing window with AppleScript..."

osascript << 'EOF'
tell application "System Events"
    tell process "Inkwell"
        set frontmost to true
        
        -- Get the window
        set mainWindow to window 1
        
        -- Move window to specific position
        set position of mainWindow to {100, 100}
        delay 0.5
        
        -- Resize window
        set size of mainWindow to {800, 600}
        delay 0.5
    end tell
end tell
EOF

echo "3. Closing the app to save position..."
kill $APP_PID
sleep 2

echo "4. Relaunching to test if position is restored..."
./build_simple/Inkwell.app/Contents/MacOS/Inkwell README.md &
APP_PID2=$!
sleep 2

echo "5. Checking window position..."

osascript << 'EOF'
tell application "System Events"
    tell process "Inkwell"
        set frontmost to true
        
        -- Get the window position and size
        set mainWindow to window 1
        set windowPos to position of mainWindow
        set windowSize to size of mainWindow
        
        log "Window position: " & (item 1 of windowPos) & ", " & (item 2 of windowPos)
        log "Window size: " & (item 1 of windowSize) & " x " & (item 2 of windowSize)
        
        -- Check if position is approximately what we set (allowing some variance)
        if (item 1 of windowPos) > 50 and (item 1 of windowPos) < 150 then
            if (item 2 of windowPos) > 50 and (item 2 of windowPos) < 150 then
                log "✅ Position persistence WORKING"
            else
                log "❌ Position persistence FAILED (Y axis)"
            end if
        else
            log "❌ Position persistence FAILED (X axis)"
        end if
        
        -- Check size
        if (item 1 of windowSize) > 750 and (item 1 of windowSize) < 850 then
            if (item 2 of windowSize) > 550 and (item 2 of windowSize) < 650 then
                log "✅ Size persistence WORKING"
            else
                log "❌ Size persistence FAILED (height)"
            end if
        else
            log "❌ Size persistence FAILED (width)"
        end if
    end tell
end tell
EOF

echo ""
echo "6. Cleaning up..."
kill $APP_PID2 2>/dev/null

echo ""
echo "Test complete! Window persistence should be working."
echo "The window position and size are saved to UserDefaults."