#!/bin/bash

echo "======================================"
echo "Drag & Drop Effects Testing"
echo "======================================"
echo ""
echo "This test will launch Inkwell and help you verify:"
echo "1. Screen dimming works for all effects"
echo "2. Visual effects appear correctly"
echo "3. Effect switching via keyboard shortcuts"
echo ""

# Create test files if needed
if [ ! -f test_drag_source.md ]; then
    cat > test_drag_source.md << 'EOF'
# Drag Source File

This file is for dragging onto the main window.

## Instructions

1. Drag this file onto the Inkwell window
2. Observe the visual effects
3. Try different effects with keyboard shortcuts

EOF
fi

# Launch with debug logging
echo "Launching Inkwell with debug logging..."
echo ""
echo "TEST CHECKLIST:"
echo "---------------"
echo "[ ] Classic Blue (Cmd+Shift+E):"
echo "    - Screen dims with dark overlay"
echo "    - Blue border appears around window"
echo ""
echo "[ ] Ripple (Cmd+Shift+D):"
echo "    - Screen dims with dark overlay"
echo "    - Ripple circles appear at drag location"
echo ""
echo "[ ] Stardust (Cmd+Shift+F):"
echo "    - Screen dims with dark overlay"
echo "    - Particles emit from drag location"
echo ""
echo "Press ENTER to launch Inkwell..."
read

# Launch the app
./build/Inkwell.app/Contents/MacOS/Inkwell test_document.md 2>&1 | tee inkwell_debug.log &
APP_PID=$!

echo ""
echo "Inkwell is running (PID: $APP_PID)"
echo "Drag 'test_drag_source.md' onto the window to test effects"
echo ""
echo "Press ENTER when done testing to close the app..."
read

kill $APP_PID 2>/dev/null
echo ""
echo "Test complete. Debug log saved to inkwell_debug.log"