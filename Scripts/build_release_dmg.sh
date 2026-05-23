#!/bin/bash
# build_release_dmg.sh — Mole Release Build & DMG Packager
# Usage: ./Scripts/build_release_dmg.sh [--sign "Developer ID Application: Name (TEAMID)"]
# Requires: Xcode Command Line Tools, swift, codesign, hdiutil
set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# ─── Configuration ───────────────────────────────────────────────────────────
cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)
BUILD_DIR="$PROJECT_DIR/build/Release"
APP_NAME="Mole"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="Mole_Premium.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"

# Source-controlled entitlements (not generated inline)
ENTITLEMENTS_FILE="$PROJECT_DIR/Resources/Mole.entitlements"

# Signing identity: default to ad-hoc, override with --sign flag
SIGN_IDENTITY="-"
if [[ "${1:-}" == "--sign" && -n "${2:-}" ]]; then
    SIGN_IDENTITY="$2"
fi

# ─── Validate prerequisites ──────────────────────────────────────────────────
echo -e "${BLUE}[0/5] Validating prerequisites...${NC}"
if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    echo -e "${RED}❌ Missing entitlements: $ENTITLEMENTS_FILE${NC}"
    exit 1
fi
plutil -lint "$ENTITLEMENTS_FILE" || { echo -e "${RED}❌ Invalid entitlements plist${NC}"; exit 1; }
plutil -lint "$PROJECT_DIR/com.mole.backgroundscan.plist" || { echo -e "${RED}❌ Invalid backgroundscan plist${NC}"; exit 1; }

# ─── Clean Build Directory ───────────────────────────────────────────────────
echo -e "${BLUE}[1/5] Preparing Release Environment...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Library/LaunchServices"
mkdir -p "$APP_BUNDLE/Contents/Library/LaunchAgents"

# ─── Compile ─────────────────────────────────────────────────────────────────
echo -e "${BLUE}[2/5] Compiling Swift Package (Release / arm64)...${NC}"
swift build -c release --arch arm64

# ─── Assemble App Bundle ─────────────────────────────────────────────────────
echo -e "${BLUE}[3/5] Assembling App Bundle...${NC}"

# Main executable (named "Mole" to match CFBundleExecutable in Info.plist)
cp ".build/arm64-apple-macosx/release/MoleApp" "$APP_BUNDLE/Contents/MacOS/Mole"

# Privileged helper (XPC daemon)
cp ".build/arm64-apple-macosx/release/MoleDaemon" "$APP_BUNDLE/Contents/Library/LaunchServices/com.mole.daemon"

# Background scan LaunchAgent plist
cp "com.mole.backgroundscan.plist" "$APP_BUNDLE/Contents/Library/LaunchAgents/com.mole.backgroundscan.plist"

# Source-controlled Info.plist
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# ─── Code Sign ───────────────────────────────────────────────────────────────
echo -e "${BLUE}[4/5] Signing with Hardened Runtime...${NC}"

# Clear resource forks and quarantine xattrs to prevent codesign errors
xattr -cr "$APP_BUNDLE"

# Deep-sign: helper first, then main bundle (reverse-dependency order required)
echo -e "${YELLOW}  Signing privileged helper...${NC}"
codesign --force --options runtime \
    --entitlements "$ENTITLEMENTS_FILE" \
    --sign "$SIGN_IDENTITY" \
    "$APP_BUNDLE/Contents/Library/LaunchServices/com.mole.daemon"

echo -e "${YELLOW}  Signing main app bundle...${NC}"
codesign --force --deep --options runtime \
    --entitlements "$ENTITLEMENTS_FILE" \
    --sign "$SIGN_IDENTITY" \
    "$APP_BUNDLE"

# Verify signature
echo -e "${YELLOW}  Verifying signature...${NC}"
codesign --verify --deep --strict "$APP_BUNDLE" && \
    echo -e "${GREEN}  ✅ Signature verified${NC}"

# ─── Create DMG ──────────────────────────────────────────────────────────────
echo -e "${BLUE}[5/5] Creating Drag-and-Drop DMG...${NC}"
rm -f "$DMG_PATH"

STAGING_DIR="$BUILD_DIR/dmg_staging"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "Mole" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
rm -rf "$STAGING_DIR"

echo -e "${GREEN}✅ Build Complete!${NC}"
echo -e "${GREEN}DMG: $DMG_PATH${NC}"
if [ "$SIGN_IDENTITY" = "-" ]; then
    echo -e "${YELLOW}⚠️  Signed ad-hoc (development). For distribution, run:${NC}"
    echo -e "${YELLOW}   ./Scripts/build_release_dmg.sh --sign \"Developer ID Application: Your Name (TEAMID)\"${NC}"
fi
