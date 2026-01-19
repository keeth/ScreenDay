#!/bin/bash

echo "🧹 Cleaning ScreenDay build cache..."

# Kill any running instances
pkill -9 ScreenDay 2>/dev/null && echo "  ✓ Killed running app instances"

# Navigate to project directory
cd "$(dirname "$0")"

# Clean Xcode build
echo "  → Running xcodebuild clean..."
xcodebuild clean -project ScreenDay/ScreenDay.xcodeproj -scheme ScreenDay > /dev/null 2>&1
echo "  ✓ Xcode build cleaned"

# Remove DerivedData
echo "  → Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ScreenDay-*
echo "  ✓ DerivedData removed"

echo "✅ Build cache cleared successfully"
echo ""
echo "Run ./build.sh to rebuild the project"
