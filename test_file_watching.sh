#!/bin/bash

echo "📁 File Watching Test for Inkwell"
echo "================================="
echo ""
echo "This tests if Inkwell auto-reloads when files change externally."
echo ""
echo "1. Launching Inkwell with test file..."
./build_simple/Inkwell.app/Contents/MacOS/Inkwell test_document.md &
INKWELL_PID=$!

echo "2. Waiting for app to load..."
sleep 3

echo "3. Modifying the file externally..."
echo "" >> test_document.md
echo "## AUTO-RELOAD TEST - $(date)" >> test_document.md
echo "If you see this timestamp in Inkwell, file watching works!" >> test_document.md

echo ""
echo "✅ Check Inkwell - did it reload with the new content?"
echo "   You should see: AUTO-RELOAD TEST - [timestamp]"
echo ""
echo "Press Enter to close Inkwell and cleanup..."
read

kill $INKWELL_PID 2>/dev/null
echo "Test complete!"