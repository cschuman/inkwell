#!/bin/bash

echo "🍺 Setting up Homebrew Tap for Inkwell"
echo "======================================"

# Check if homebrew-tap directory already exists
if [ -d "../homebrew-tap" ]; then
    echo "❌ homebrew-tap directory already exists!"
    echo "   Please remove it first or choose a different location"
    exit 1
fi

# Create tap directory structure
echo "📁 Creating tap directory structure..."
mkdir -p ../homebrew-tap/Casks
cd ../homebrew-tap

# Copy the cask formula
echo "📝 Copying Inkwell cask formula..."
cp ../inkwell/homebrew/inkwell.rb Casks/inkwell.rb

# Initialize git repository
echo "🔧 Initializing git repository..."
git init

# Create README
echo "📖 Creating README..."
cat > README.md << 'EOF'
# Homebrew Tap for Inkwell

This tap contains the Homebrew formula for [Inkwell](https://github.com/cschuman/inkwell), a native macOS markdown viewer.

## Installation

```bash
brew tap cschuman/tap
brew install --cask inkwell
```

## Updating

```bash
brew update
brew upgrade --cask inkwell
```

## Uninstallation

```bash
brew uninstall --cask inkwell
brew untap cschuman/tap
```
EOF

# Create initial commit
echo "💾 Creating initial commit..."
git add .
git commit -m "Initial commit: Add Inkwell cask formula"

echo ""
echo "✅ Homebrew tap setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Create a new repository on GitHub named 'homebrew-tap'"
echo "   Go to: https://github.com/new"
echo ""
echo "2. Add the remote and push:"
echo "   cd ../homebrew-tap"
echo "   git remote add origin https://github.com/cschuman/homebrew-tap.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Test the tap:"
echo "   brew tap cschuman/tap"
echo "   brew install --cask inkwell"
echo ""
echo "4. Share installation instructions:"
echo "   Users can install Inkwell with:"
echo "   brew tap cschuman/tap && brew install --cask inkwell"