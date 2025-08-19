#!/bin/bash

# Test script to verify search functionality doesn't crash
# This simulates the operations that were causing the crash

echo "Testing Inkwell search functionality..."
echo "======================================="

# Kill any existing Inkwell instances
pkill -f Inkwell 2>/dev/null
sleep 1

# Create a test file with content to search
cat > test_search.md << 'EOF'
# Search Test Document

This document contains various **search** terms to test the search functionality.

## Testing Search Crashes

The word search appears multiple times in this document. We need to test:

1. Opening search with Cmd+F
2. Typing a search term
3. Navigating through results with Cmd+G
4. Closing search with ESC
5. Reopening search immediately after

### Code Blocks

```javascript
// The word search in a code block
function searchDatabase() {
    return "search results";
}
```

### More Search Terms

- Search term one
- Search term two  
- Search term three

The goal is to ensure that rapidly opening and closing search doesn't cause a crash.

**Search** should be highlighted when found.

EOF

echo "1. Launching Inkwell with test document..."
./build_simple/Inkwell.app/Contents/MacOS/Inkwell test_search.md &
APP_PID=$!
sleep 2

echo "2. Testing search operations with AppleScript..."

# Use AppleScript to test search
osascript << 'EOF'
tell application "System Events"
    -- Open search with Cmd+F
    keystroke "f" using command down
    delay 0.5
    
    -- Type search term
    keystroke "search"
    delay 0.5
    
    -- Navigate results with Cmd+G (3 times)
    keystroke "g" using command down
    delay 0.2
    keystroke "g" using command down
    delay 0.2
    keystroke "g" using command down
    delay 0.2
    
    -- Close search with ESC
    key code 53 -- ESC key
    delay 0.5
    
    -- Immediately reopen search (this was causing crash)
    keystroke "f" using command down
    delay 0.5
    
    -- Type different search term
    keystroke "test"
    delay 0.5
    
    -- Close again
    key code 53 -- ESC key
    delay 0.5
    
    -- One more rapid open/close cycle
    keystroke "f" using command down
    delay 0.2
    key code 53 -- ESC key
end tell
EOF

echo "3. Waiting to check for crashes..."
sleep 2

# Check if Inkwell is still running
if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ SUCCESS: Inkwell is still running - no crash detected!"
    echo "4. Cleaning up..."
    kill $APP_PID
else
    echo "❌ FAILURE: Inkwell crashed during search test"
    exit 1
fi

echo ""
echo "Test complete - search functionality is working without crashes!"