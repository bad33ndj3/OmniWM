#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFTLY="${SWIFTLY_HOME_DIR:-$HOME/.swiftly}/bin/swiftly"
APP_DIR="$ROOT_DIR/dist/OmniWM Dashboard Dev.app"
cd "$ROOT_DIR"

# Keep this package independent: it must never bootstrap the window manager.
"$SWIFTLY" run swift build --package-path "$ROOT_DIR/dashboard" --product PersonalWMDashboard
BUILD_DIR="$("$SWIFTLY" run swift build --package-path "$ROOT_DIR/dashboard" --show-bin-path)"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BUILD_DIR/PersonalWMDashboard" "$APP_DIR/Contents/MacOS/PersonalWMDashboard"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleIdentifier</key><string>com.barut.OmniWM.dashboard.dev</string>
    <key>CFBundleName</key><string>OmniWM Dashboard Dev</string>
    <key>CFBundleExecutable</key><string>PersonalWMDashboard</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
plutil -lint "$APP_DIR/Contents/Info.plist"
codesign --force --sign - "$APP_DIR"
codesign --verify --strict "$APP_DIR"
echo "Built: $APP_DIR"
echo "Launch separately: open \"$APP_DIR\""
