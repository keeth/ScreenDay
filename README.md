# ScreenDay

A lightweight macOS menu bar application that captures periodic screenshots to a configurable folder with automatic storage management.

## Features

- **Menu Bar Only**: No dock icon, just a clean menu bar presence
- **Automatic Screenshot Capture**: Configurable intervals (5s to 5 minutes)
- **Smart Storage Management**: Automatically prunes oldest screenshots when approaching storage limits
- **Visual Status Indicators**:
  - Green: Actively capturing
  - Yellow: Pruning old files
  - Gray: Paused
- **System-Aware**: Pauses during sleep and screen lock
- **Customizable Settings**:
  - Choose destination folder
  - Set capture interval
  - Configure maximum storage size

## Requirements

- macOS 14.0 or later
- Screen Recording permission (will be requested on first launch)

## Building

### Via Xcode
1. Open `ScreenDay/ScreenDay.xcodeproj` in Xcode
2. Select your development team in the project settings
3. Build and run (⌘R)

### Via Command Line
```bash
cd ScreenDay
xcodebuild -project ScreenDay.xcodeproj -scheme ScreenDay -configuration Debug build
```

## Running the App

### ⚠️ Important: Permission Issues with Debug Builds

macOS has strict security requirements for screen recording permissions. Apps running from Xcode's DerivedData folder **will not work properly** and will repeatedly ask for permissions.

**You MUST install the app to /Applications:**

```bash
./install-and-run.sh
```

This script will:
1. Build a Release version
2. Copy it to /Applications
3. Remove quarantine attributes
4. Launch the app

**After installation:**
1. Go to System Settings > Privacy & Security > Screen Recording
2. Remove any old ScreenDay entries (especially ones from DerivedData)
3. Grant permission to the new ScreenDay app in /Applications
4. Restart ScreenDay if needed

### First Launch Experience

1. Configure your preferences in the Settings window:
   - **Check permissions status** - Green checkmark means ready to go
   - Choose where to save screenshots
   - Set screenshot interval
   - Set maximum storage size
2. If permission is not granted, click "Open System Settings" in either:
   - The Settings window (Permissions section)
   - The menu dropdown (warning banner)
3. Click the camera icon in the menu bar
4. Toggle "Capture Screenshots" ON (will turn blue)
5. Screenshots will start being captured automatically

### Permission Handling

The app uses a smart permission system:
- Permission status is checked automatically
- If denied, the toggle is disabled and a warning is shown
- Click "Open System Settings" to grant permission
- The app will NOT repeatedly prompt you - it shows status instead

## Debugging

### View Live Logs

To see what the app is doing in real-time:
```bash
./view-logs.sh
```

This will show detailed logging including:
- 🚀 App launch
- 🎯 Capture state changes
- 📸 Screenshot capture events
- 💾 File save operations
- ❌ Errors and issues
- 💤 System sleep/wake events
- 🔒 Screen lock/unlock events

### Common Issues

**No screenshots being captured:**
1. Check logs with `./view-logs.sh`
2. Verify Screen Recording permission is granted in System Settings
3. Ensure capture toggle is ON (blue background)
4. Check destination folder is set and accessible

## Project Structure

```
ScreenDay/
├── ScreenDay/
│   ├── App/
│   │   ├── ScreenDayApp.swift        # Main app entry point
│   │   ├── AppDelegate.swift         # App delegate, creates status bar
│   │   └── AppState.swift            # Observable state management
│   ├── Core/
│   │   ├── ScreenshotService.swift   # Screenshot capture logic
│   │   └── StorageMonitor.swift      # Storage monitoring and pruning
│   ├── Menu/
│   │   ├── StatusBarController.swift # Status bar item management
│   │   └── StatusMenuView.swift      # Menu dropdown UI
│   ├── Settings/
│   │   ├── SettingsManager.swift     # UserDefaults wrapper
│   │   └── SettingsView.swift        # Settings window UI
│   └── Assets.xcassets/              # App assets
└── ScreenDay.xcodeproj
```

## Implementation Details

### Screenshot Capture

- Uses `SCScreenshotManager` from ScreenCaptureKit
- Saves JPEG images at 85% quality
- Scaled to ~1080p height while maintaining aspect ratio
- Filenames use timestamp format: `YYYYMMDD_HHMMSS.jpg`

### Storage Management

- Monitors folder size every 30 seconds
- When folder reaches 90% of limit, starts pruning
- Deletes oldest files (by modification date) until under 80% of limit
- Pruning operation is visible via yellow status icon

### System Integration

- Respects system sleep/wake events
- Pauses during screen lock
- Resumes automatically after wake/unlock
- Persists capture state across app restarts

## Default Settings

- **Destination Folder**: `~/Pictures/ScreenDay/`
- **Screenshot Interval**: 10 seconds
- **Max Folder Size**: 10 GB

## Icon Assets

The app uses SF Symbols as fallback icons. For custom icons:

1. Create 18x18 PDF files for:
   - `StatusIconGreen.pdf` - Active state
   - `StatusIconYellow.pdf` - Pruning state
   - `StatusIconOff.pdf` - Paused state
2. Add them to the respective image sets in Assets.xcassets

## CI/CD

This project uses GitHub Actions for continuous integration and releases:

### Continuous Integration

On every push to `main` or `develop` branches:
- Builds the app to verify compilation
- Runs tests (if any)

See [.github/workflows/ci.yml](.github/workflows/ci.yml) for details.

### Release Process

To create a new release:

```bash
# Tag the release
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically:
1. Build a Release version of the app
2. Sign the app (if certificates are configured)
3. Notarize the app (if Apple ID credentials are configured)
4. Create a GitHub release with the tag
5. Upload `ScreenDay.app.zip` as a release artifact

See [.github/workflows/release.yml](.github/workflows/release.yml) for details.

### Code Signing

To enable code signing and notarization for releases, see [CODESIGNING.md](CODESIGNING.md) for setup instructions.

Without code signing:
- ✅ Builds will work
- ⚠️ Users will see "unidentified developer" warnings
- 🖱️ Users must right-click → Open on first launch

With code signing + notarization:
- ✅ Professional signed releases
- ✅ Minimal security warnings
- ✅ Users can double-click to open

## License

Copyright © 2026. All rights reserved.
