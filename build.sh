#!/bin/bash

echo "🔨 Building ScreenDay..."
xcodebuild clean build -project ScreenDay/ScreenDay.xcodeproj -scheme ScreenDay -configuration Debug
