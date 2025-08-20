#!/bin/bash

echo "================================================"
echo "Finder Drag & Drop Test"
echo "================================================"
echo ""
echo "This test verifies drag & drop from Finder works"
echo ""

# Create test files in a visible location
mkdir -p ~/Desktop/inkwell_test
cat > ~/Desktop/inkwell_test/test1.md << 'EOF'
# Test File 1
This file can be dragged from Finder
EOF

cat > ~/Desktop/inkwell_test/test2.md << 'EOF'
# Test File 2  
Another file to test drag & drop
EOF

echo "Created test files on Desktop in 'inkwell_test' folder"
echo ""
echo "TESTING INSTRUCTIONS:"
echo "====================="
echo "1. The app will launch with debug output"
echo "2. Open Finder and navigate to Desktop/inkwell_test"
echo "3. Drag test1.md from FINDER onto the Inkwell window"
echo "4. Watch for these debug messages:"
echo "   - 'DragEntered: Available types: ...'"
echo "   - 'Got URLs via ...' (should show which method worked)"
echo "   - 'DragEntered: Markdown file detected'"
echo "5. The effect overlay should appear"
echo "6. Drop the file - it should open"
echo ""
echo "Press ENTER to launch Inkwell with debug output..."
read

echo "Launching Inkwell..."
./build/Inkwell.app/Contents/MacOS/Inkwell test_document.md 2>&1 | grep -E "(DragEntered|Available types|Got URLs|KeyHandlingView|NoEffect|Opening dropped)" &

echo ""
echo "Inkwell is running with debug output."
echo "Test dragging from Finder now!"
echo "Press ENTER when done to close..."
read

pkill -f Inkwell
echo ""
echo "Cleaning up test files..."
rm -rf ~/Desktop/inkwell_test
echo "Test complete!"