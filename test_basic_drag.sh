#!/bin/bash

echo "Testing basic drag & drop..."
echo "Creating test file..."

cat > drag_test.md << 'EOF'
# Drag Test File

This file is for testing drag and drop functionality.
EOF

echo "Launching Inkwell..."
echo "Instructions:"
echo "1. Drag 'drag_test.md' onto the Inkwell window"
echo "2. You should see a blue border effect"
echo "3. Use Cmd+Shift+E/D/F to try different effects"
echo ""
echo "Press any key to launch..."
read -n 1

./build/Inkwell.app/Contents/MacOS/Inkwell test_document.md