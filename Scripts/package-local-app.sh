#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Mole"
APP_EXECUTABLE="MoleApp"
APP_ID="com.mole.app"
SIGN_IDENTITY="${DEVELOPER_ID_APPLICATION:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$(mktemp -d /tmp/mole-build.XXXXXX)"
DMG_ROOT="$BUILD_DIR/dmg-root"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DIST_APP_PATH="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME-local.dmg"
RW_DMG_PATH="$BUILD_DIR/$APP_NAME-rw.dmg"

clear_packaging_xattrs() {
    local path="$1"
    xattr -cr "$path" 2>/dev/null || true
    xattr -d com.apple.FinderInfo "$path" 2>/dev/null || true
}

sign_and_verify_app() {
    local app_path="$1"
    local attempt

    for attempt in 1 2 3; do
        clear_packaging_xattrs "$app_path"
        local -a sign_args=(--force --deep --options runtime --sign "$SIGN_IDENTITY")
        if [[ "$SIGN_IDENTITY" != "-" ]]; then
            sign_args+=(--timestamp)
        fi
        if codesign "${sign_args[@]}" "$app_path" && codesign --verify --deep --strict --verbose=2 "$app_path"; then
            return 0
        fi
        sleep 0.2
    done

    codesign --verify --deep --strict --verbose=2 "$app_path"
}

rm -rf "$DIST_DIR"
mkdir -p \
    "$DIST_DIR" \
    "$APP_PATH/Contents/MacOS" \
    "$APP_PATH/Contents/Resources" \
    "$DMG_ROOT"

# Build using Swift Package Manager
cd "$ROOT_DIR"
echo "Building MoleApp..."
swift build -c release --product MoleApp

echo "Building MoleDaemon..."
swift build -c release --product MoleDaemon

BIN_PATH=$(swift build -c release --show-bin-path)

# Copy Binaries
cp "$BIN_PATH/MoleApp" "$APP_PATH/Contents/MacOS/$APP_EXECUTABLE"
cp "$BIN_PATH/MoleDaemon" "$APP_PATH/Contents/MacOS/MoleDaemon"

/usr/libexec/PlistBuddy -c "Clear dict" "$APP_PATH/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Mole" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $APP_ID" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_EXECUTABLE" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0.0" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" "$APP_PATH/Contents/Info.plist"
# Add LSUIElement to hide the dock icon if needed, but since it's an app, keep it visible.

chmod +x "$APP_PATH/Contents/MacOS/$APP_EXECUTABLE"
chmod +x "$APP_PATH/Contents/MacOS/MoleDaemon"

sign_and_verify_app "$APP_PATH"

ditto --noextattr --noqtn "$APP_PATH" "$DMG_ROOT/$APP_NAME.app"
clear_packaging_xattrs "$DMG_ROOT"
sign_and_verify_app "$DMG_ROOT/$APP_NAME.app"

hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_ROOT" -ov -format UDRW "$RW_DMG_PATH"
MOUNT_DIR="$(mktemp -d /tmp/mole-dmg.XXXXXX)"
hdiutil attach -nobrowse -mountpoint "$MOUNT_DIR" "$RW_DMG_PATH" >/dev/null
cleanup_mount() {
    hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
    rmdir "$MOUNT_DIR" 2>/dev/null || true
}
trap cleanup_mount EXIT
clear_packaging_xattrs "$MOUNT_DIR/$APP_NAME.app"
sign_and_verify_app "$MOUNT_DIR/$APP_NAME.app"
hdiutil detach "$MOUNT_DIR" >/dev/null
trap - EXIT
rmdir "$MOUNT_DIR" 2>/dev/null || true

hdiutil convert "$RW_DMG_PATH" -format UDZO -o "$DMG_PATH" -ov
clear_packaging_xattrs "$DMG_PATH"

if [[ "$SIGN_IDENTITY" != "-" ]]; then
    codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"
    if [[ -n "$NOTARY_PROFILE" ]]; then
        xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
        xcrun stapler staple "$DMG_PATH"
    fi
fi

sign_and_verify_app "$APP_PATH"

rm -rf "$DIST_APP_PATH"
ditto --noextattr --noqtn "$APP_PATH" "$DIST_APP_PATH"
clear_packaging_xattrs "$DIST_APP_PATH"
sign_and_verify_app "$DIST_APP_PATH"

printf 'Built app: %s\n' "$APP_PATH"
printf 'Copied app: %s\n' "$DIST_APP_PATH"
printf 'Built dmg: %s\n' "$DMG_PATH"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
    printf 'Signing: ad-hoc local build. Set DEVELOPER_ID_APPLICATION for public release.\n'
else
    printf 'Signing: %s\n' "$SIGN_IDENTITY"
fi
