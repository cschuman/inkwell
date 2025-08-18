#!/bin/bash

# Quick test script to launch Inkwell with our test file

echo "🚀 Launching Inkwell..."
echo "========================"
echo ""
echo "MOMENT OF TRUTH: Can it display actual markdown text?"
echo ""
echo "Opening test_unfucked.md..."
echo ""
echo "Check if you see:"
echo "  ✓ Actual text (not colored rectangles)"
echo "  ✓ Formatted headers"
echo "  ✓ Bold and italic text"
echo "  ✓ Code blocks"
echo ""
echo "Press Ctrl+C to stop..."
echo ""

# Launch the app with the test file
./Inkwell.app/Contents/MacOS/Inkwell test_unfucked.md