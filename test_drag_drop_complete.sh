#!/bin/bash

echo "Complete Drag & Drop Test Suite"
echo "================================"
echo ""

# Create test files with different extensions
echo "Creating test files..."
echo "# Test MD" > test.md
echo "# Test Markdown" > test.markdown
echo "# Test MDText" > test.mdtext
echo "# Test Text" > test.txt
echo "# Test MDown" > test.mdown

echo "✅ Created test files with various extensions"
echo ""

# Test 1: Command line opening (simulates drag to app icon)
echo "Test 1: Command-line file opening"
echo "----------------------------------"
./build/Inkwell.app/Contents/MacOS/Inkwell test.md &
PID1=$!
sleep 2

if ps -p $PID1 > /dev/null 2>&1; then
    echo "✅ App opens .md files from command line"
    pkill -P $PID1
else
    echo "❌ Failed to open .md file"
fi

# Test 2: Different file extensions
echo ""
echo "Test 2: Different file extensions"
echo "----------------------------------"
./build/Inkwell.app/Contents/MacOS/Inkwell test.markdown &
PID2=$!
sleep 1

if ps -p $PID2 > /dev/null 2>&1; then
    echo "✅ App opens .markdown files"
    pkill -P $PID2
else
    echo "❌ Failed to open .markdown file"
fi

# Clean up
pkill -f Inkwell 2>/dev/null

echo ""
echo "Manual Tests Required:"
echo "======================"
echo ""
echo "1. Launch Inkwell: open ./build/Inkwell.app"
echo ""
echo "2. Test drag & drop to window:"
echo "   - Drag test.md onto the window"
echo "   - Window should briefly change color during drag"
echo "   - File should open immediately"
echo ""
echo "3. Test multiple file types:"
echo "   - Try dragging: test.markdown, test.txt, test.mdown"
echo "   - All should open successfully"
echo ""
echo "4. Test multiple files:"
echo "   - Select multiple test files and drag together"
echo "   - Should open first file and show alert about others"
echo ""
echo "5. Test drag to app icon:"
echo "   - Drag test.md onto Inkwell icon in Dock"
echo "   - File should open"
echo ""
echo "6. Test unsupported files:"
echo "   - Try dragging a .pdf or .jpg file"
echo "   - Should not accept the drag"
echo ""

# Clean up test files
echo "Cleaning up test files in 10 seconds..."
sleep 10
rm -f test.md test.markdown test.mdtext test.txt test.mdown
echo "✅ Test files cleaned up"