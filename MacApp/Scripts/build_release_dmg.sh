#!/bin/bash
set -e

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[1/5] Preparing Release Environment...${NC}"
cd "$(dirname "$0")/.."
PROJECT_DIR=$(pwd)
BUILD_DIR="$PROJECT_DIR/build/Release"
APP_NAME="Mole"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="Mole_Premium.dmg"

# Temizlik
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Library/LaunchServices"

echo -e "${BLUE}[2/5] Compiling Swift Package (Release Mode)...${NC}"
# -c release ve arch arm64 ile M-serisi çipler için optimize edilmiş derleme
swift build -c release --arch arm64

echo -e "${BLUE}[3/5] Assembling App Bundle...${NC}"
# Binaries
cp ".build/arm64-apple-macosx/release/MoleApp" "$APP_BUNDLE/Contents/MacOS/Mole"
cp ".build/arm64-apple-macosx/release/MoleDaemon" "$APP_BUNDLE/Contents/Library/LaunchServices/com.mole.daemon"

# Info.plist oluşturma
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Mole</string>
    <key>CFBundleIdentifier</key>
    <string>com.mole.app</string>
    <key>CFBundleName</key>
    <string>Mole</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

echo -e "${BLUE}[4/5] Generating Entitlements and Applying Hardened Runtime...${NC}"
# Hardened Runtime Entitlements
ENTITLEMENTS_FILE="$BUILD_DIR/Mole.entitlements"
cat > "$ENTITLEMENTS_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
    <!-- Tam Disk Erişimi (Full Disk Access) talebi için -->
    <key>com.apple.developer.system-extension.install</key>
    <true/>
    <!-- Bildirim İzni -->
    <key>com.apple.developer.usernotifications.communication</key>
    <true/>
</dict>
</plist>
EOF

# Temizleme: Resource fork veya Finder xattr kalıntılarını temizle (codesign hatasını önler)
xattr -cr "$APP_BUNDLE"

# Kod İmzalama (Local Ad-Hoc sign with Hardened Runtime for development)
# Gerçek ortamda "Developer ID Application: ..." kimliği kullanılır.
codesign --force --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign - "$APP_BUNDLE/Contents/MacOS/Mole"

echo -e "${BLUE}[5/5] Creating Premium Drag-and-Drop DMG...${NC}"
# Basit DMG Oluşturma (Arkaplan için create-dmg gerekebilir, burada standart hdiutil kullanıyoruz)
DMG_PATH="$PROJECT_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

# Geçici bir klasör oluşturup app'i oraya kopyala
STAGING_DIR="$BUILD_DIR/dmg_staging"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
# Uygulamalar klasörü kısayolu
ln -s /Applications "$STAGING_DIR/Applications"

# DMG Arkaplan resmi için gizli klasör
mkdir -p "$STAGING_DIR/.background"
# Geçici olarak bir gradient görseli oluştur (ImageMagick veya benzeri yoksa sadece klasör kalır)
# Şık DMG'yi hdiutil ile yarat
hdiutil create -volname "Mole" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo -e "${GREEN}✅ Build Complete!${NC}"
echo -e "${GREEN}Premium DMG is ready at: $DMG_PATH${NC}"
