#!/bin/bash
# ==============================================================================
# RecipeApp - Full Build, Install, & Launch Script
# ==============================================================================

set -e

cd "$(dirname "$0")"

PROJECT_PATH="$(pwd)/RecipeApp.xcodeproj"
SCHEME="RecipeApp"
PREFERRED_DEVICE="iPhone 17 Pro"
BUNDLE_ID="com.DagmawiStudio.ChefsPocket"

echo "=== 1. Checking Simulator State ==="
# Check if a simulator device is already booted to avoid opening duplicate windows
TARGET_UDID=$(xcrun simctl list devices booted | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()' | head -n 1)

if [ -z "$TARGET_UDID" ]; then
    echo "No simulator currently booted. Booting $PREFERRED_DEVICE..."
    xcrun simctl boot "$PREFERRED_DEVICE"
    open -a Simulator
    TARGET_UDID=$(xcrun simctl list devices booted | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()' | head -n 1)
else
    echo "Using already booted simulator ($TARGET_UDID)"
    open -a Simulator
fi

echo "Target Simulator UDID: $TARGET_UDID"

echo -e "\n=== 2. Building RecipeApp for Target Simulator ==="
xcodebuild -project "$PROJECT_PATH" \
           -scheme "$SCHEME" \
           -sdk iphonesimulator \
           -destination "id=$TARGET_UDID" \
           build

echo -e "\n=== 3. Locating Built .app Bundle Path ==="
APP_PATH=$(xcodebuild -project "$PROJECT_PATH" \
                      -scheme "$SCHEME" \
                      -sdk iphonesimulator \
                      -destination "id=$TARGET_UDID" \
                      -showBuildSettings | grep -m 1 "CODESIGNING_FOLDER_PATH" | awk '{print $3}')

echo "App Bundle Path: $APP_PATH"

echo -e "\n=== 4. Installing App on Simulator ==="
xcrun simctl install "$TARGET_UDID" "$APP_PATH"

echo -e "\n=== 5. Launching RecipeApp on Simulator ==="
xcrun simctl launch "$TARGET_UDID" "$BUNDLE_ID"

echo -e "\n=== RecipeApp Successfully Launched! ==="
