#!/bin/bash

echo "🚀 Launching Inkwell v0.1.0-unfucked"
echo "====================================="
echo ""
echo "✅ WORKING FEATURES:"
echo "  ✓ Markdown rendering (real text!)"
echo "  ✓ File → Open"
echo "  ✓ Command-line file opening"
echo "  ✓ Syntax highlighting"
echo ""
echo "🔍 TEST THESE:"
echo "  • File watching (edit the file in another editor)"
echo "  • Vim navigation (j/k to scroll)"
echo "  • Command Palette (Cmd+K)"
echo "  • Drag & drop"
echo ""
echo "Opening test_unfucked.md..."
echo "Press Ctrl+C to stop..."
echo ""

# Launch the app with the test file (command-line opening now works!)
./build_simple/Inkwell.app/Contents/MacOS/Inkwell test_unfucked.md