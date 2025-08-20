#!/bin/bash

echo "Testing drag & drop dimming overlay..."
echo "This script will launch Inkwell for manual testing"
echo ""
echo "INSTRUCTIONS:"
echo "1. The app will open with a test document"
echo "2. Try dragging any markdown file onto the window"
echo "3. You should see:"
echo "   - The whole screen dims (semi-transparent dark overlay)"
echo "   - The selected effect appears (blue border, ripple, or particles)"
echo ""
echo "4. Test each effect using keyboard shortcuts:"
echo "   - Cmd+Shift+E: Classic Blue (blue border)"
echo "   - Cmd+Shift+D: Ripple (expanding circles)"
echo "   - Cmd+Shift+F: Stardust (particle emitter)"
echo ""
echo "5. Each effect should include screen dimming when dragging"
echo ""
echo "Press any key to launch Inkwell..."
read -n 1

# Create a test markdown file if it doesn't exist
if [ ! -f test_document.md ]; then
    cat > test_document.md << 'EOF'
# Test Document

This is a test document for drag & drop testing.

## Features to Test

1. **Drag & Drop** - Drag another markdown file onto this window
2. **Effect Switching** - Use Cmd+Shift+E/D/F to switch effects
3. **Screen Dimming** - All effects should dim the screen

## Expected Behavior

When dragging a file:
- Screen dims with semi-transparent overlay
- Selected effect appears
- Drop to open the file

EOF
fi

# Launch the app
./build/Inkwell.app/Contents/MacOS/Inkwell test_document.md