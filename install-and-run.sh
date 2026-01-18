#!/bin/bash

set -e

echo "🔨 Building ScreenDay..."
cd ScreenDay
xcodebuild -project ScreenDay.xcodeproj -scheme ScreenDay -configuration Release build -quiet

echo "📦 Finding built app..."
BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData/ScreenDay-*/Build/Products/Release -name "ScreenDay.app" -type d | head -1)

if [ -z "$BUILT_APP" ]; then
    echo "❌ Could not find built app"
    exit 1
fi

echo "📍 Found: $BUILT_APP"

# Kill existing app if running
killall ScreenDay 2>/dev/null || true

# Remove old version from Applications
if [ -d "/Applications/ScreenDay.app" ]; then
    echo "🗑️  Removing old version from Applications..."
    rm -rf "/Applications/ScreenDay.app"
fi

# Copy to Applications folder
echo "📋 Copying to /Applications..."
cp -R "$BUILT_APP" /Applications/

# Clear quarantine attribute so macOS trusts it
echo "🔓 Removing quarantine attribute..."
xattr -cr /Applications/ScreenDay.app

echo "✅ Installation complete!"
echo ""
echo "⚠️  IMPORTANT: You must now:"
echo "1. Go to System Settings > Privacy & Security > Screen Recording"
echo "2. Remove ScreenDay from the list (if present)"
echo "3. Launch ScreenDay from Applications"
echo "4. Grant Screen Recording permission when prompted"
echo ""
echo "🚀 Launching ScreenDay from Applications..."
sleep 2
open /Applications/ScreenDay.app

echo ""
echo "📊 To view logs, run: ./view-logs.sh"
