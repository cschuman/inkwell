#!/bin/bash

echo "================================================"
echo "Final Drag & Drop Effects Test"
echo "================================================"
echo ""
echo "Testing after memory management fixes"
echo ""

# Create test files
cat > test_drag1.md << 'EOF'
# Test File 1
First test file for dragging
EOF

cat > test_drag2.md << 'EOF'
# Test File 2
Second test file for dragging
EOF

echo "IMPORTANT TESTING STEPS:"
echo "========================"
echo ""
echo "1. The app will launch with test_document.md"
echo "2. Drag test_drag1.md onto the window"
echo "   - You should see the Classic Blue overlay"
echo "3. Drop the file, then drag test_drag2.md"
echo "   - The effect should work again (fixed memory issue)"
echo ""
echo "4. Switch effects with keyboard shortcuts:"
echo "   - Cmd+Shift+E: Classic Blue"
echo "   - Cmd+Shift+D: Ripple (cyan overlay + ripples)"
echo "   - Cmd+Shift+F: Stardust (purple overlay + particles)"
echo ""
echo "5. Test each effect multiple times to ensure they reset properly"
echo ""
echo "Debug logs will be shown in the terminal"
echo ""
echo "Press ENTER to launch Inkwell..."
read

echo "Launching with debug output..."
./build/Inkwell.app/Contents/MacOS/Inkwell test_document.md 2>&1 | grep -E "(DragEntered|DragExited|PerformDrag|NoEffect|Current effect|Setting up effect)" &

echo ""
echo "Inkwell is running. Test drag & drop now."
echo "Press ENTER when done testing to close the app..."
read

pkill -f Inkwell
echo "Test complete!"