#!/bin/bash

# Inkwell CLI installer script
set -e

INKWELL_APP="/Applications/Inkwell.app"
INKWELL_EXEC="$INKWELL_APP/Contents/MacOS/Inkwell"
SYMLINK_PATH="/usr/local/bin/inkwell"

# Check if Inkwell.app exists
if [ ! -e "$INKWELL_APP" ]; then
    echo "Error: Inkwell.app not found in /Applications"
    echo "Please install Inkwell.app first"
    exit 1
fi

# Create /usr/local/bin if it doesn't exist
if [ ! -d "/usr/local/bin" ]; then
    echo "Creating /usr/local/bin directory..."
    sudo mkdir -p /usr/local/bin
fi

# Remove existing symlink if present
if [ -L "$SYMLINK_PATH" ] || [ -e "$SYMLINK_PATH" ]; then
    echo "Removing existing inkwell command..."
    sudo rm -f "$SYMLINK_PATH"
fi

# Create the symlink
echo "Installing inkwell command..."
sudo ln -s "$INKWELL_EXEC" "$SYMLINK_PATH"

# Verify installation
if [ -L "$SYMLINK_PATH" ]; then
    echo "✓ Successfully installed!"
    echo ""
    echo "You can now use 'inkwell' from the terminal:"
    echo "  inkwell file.md"
    echo "  inkwell ~/Documents/README.md"
    echo ""
    
    # Check if /usr/local/bin is in PATH
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        echo "Note: /usr/local/bin is not in your PATH."
        echo "Add this line to your ~/.zshrc or ~/.bash_profile:"
        echo "  export PATH=\"/usr/local/bin:\$PATH\""
    fi
else
    echo "Error: Installation failed"
    exit 1
fi