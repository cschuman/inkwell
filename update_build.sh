#!/bin/bash

# Update build number in version.h
VERSION_FILE="include/version.h"

# Get current build number
CURRENT_BUILD=$(grep "#define MDVIEWER_BUILD_NUMBER" $VERSION_FILE | awk '{print $3}')

# Increment build number
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update the file
sed -i '' "s/#define MDVIEWER_BUILD_NUMBER.*/#define MDVIEWER_BUILD_NUMBER $NEW_BUILD/" $VERSION_FILE

# Get git commit hash if available
if command -v git &> /dev/null; then
    GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
else
    GIT_HASH="unknown"
fi

# Update git hash
sed -i '' "s/#define GIT_COMMIT_HASH.*/#define GIT_COMMIT_HASH \"$GIT_HASH\"/" $VERSION_FILE

echo "Updated build number from $CURRENT_BUILD to $NEW_BUILD"
echo "Git commit: $GIT_HASH"

# Update build timestamp in Info.plist
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "Build timestamp: $TIMESTAMP"