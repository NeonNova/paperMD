#!/bin/bash
# Builds paperMD in release mode and assembles a signed dist/paperMD.app bundle.
# Requires only Command Line Tools — no Xcode.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/paperMD.app"
VERSION="${PAPERMD_VERSION:-1.0.0}"

echo "==> swift build -c release"
cd "$ROOT"
swift build -c release

BIN="$ROOT/.build/release/paperMD"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/paperMD"
# Bundle.module resolves these from the main bundle's Resources dir. Copy every
# SwiftPM resource bundle (paperMD_paperMD = preview assets, paperMD_paperMDCore
# = theme packs).
for bundle in "$ROOT"/.build/release/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

# App icon. Two supported drop-ins, in priority order:
#   1. A compiled Assets.car (built by Xcode/actool from paperMD.icon) placed at
#      Scripts/Assets.car — gives the true dynamic Liquid Glass icon on macOS 26.
#   2. Scripts/paperMD.icns (classic icon, e.g. `make-icon.sh` from the artwork).
# If neither is present the app uses the default icon. Nothing else needs to
# change to upgrade later — just drop the file in and rebuild.
ICON_KEY=""
if [[ -f "$ROOT/Scripts/Assets.car" ]]; then
    cp "$ROOT/Scripts/Assets.car" "$APP/Contents/Resources/Assets.car"
    ICON_KEY="<key>CFBundleIconName</key><string>paperMD</string>"
elif [[ -f "$ROOT/Scripts/paperMD.icns" ]]; then
    cp "$ROOT/Scripts/paperMD.icns" "$APP/Contents/Resources/paperMD.icns"
    ICON_KEY="<key>CFBundleIconFile</key><string>paperMD</string>"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>paperMD</string>
    <key>CFBundleIdentifier</key><string>com.washi.papermd</string>
    <key>CFBundleName</key><string>paperMD</string>
    <key>CFBundleDisplayName</key><string>paperMD</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key><string>15.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSSupportsAutomaticTermination</key><false/>
    ${ICON_KEY}
    <key>CFBundleDocumentTypes</key>
    <array>
      <dict>
        <key>CFBundleTypeName</key><string>Markdown Document</string>
        <key>CFBundleTypeRole</key><string>Editor</string>
        <key>LSHandlerRank</key><string>Owner</string>
        <key>LSItemContentTypes</key>
        <array><string>net.daringfireball.markdown</string></array>
        <key>CFBundleTypeExtensions</key>
        <array><string>md</string><string>markdown</string></array>
      </dict>
    </array>
</dict>
</plist>
PLIST

echo "==> Codesigning (ad-hoc)"
codesign --force --sign - "$APP"

echo ""
echo "Done: $APP"
echo "Run it:      open '$APP'"
echo "Install it:  cp -R '$APP' /Applications/"
