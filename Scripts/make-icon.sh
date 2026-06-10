#!/bin/bash
# Builds a classic Scripts/paperMD.icns from the icon artwork using sips +
# iconutil (no Xcode needed). This is the static fallback icon; a compiled
# Assets.car from Icon Composer/Xcode (for the dynamic Liquid Glass variants)
# takes priority in build-app.sh when present.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Scripts/icon-source.png"
ICONSET="$(mktemp -d)/paperMD.iconset"
mkdir -p "$ICONSET"

[[ -f "$SRC" ]] || { echo "Missing $SRC (the icon artwork)."; exit 1; }

gen() { sips -z "$2" "$2" "$SRC" --out "$ICONSET/$1" >/dev/null; }
gen icon_16x16.png      16
gen icon_16x16@2x.png   32
gen icon_32x32.png      32
gen icon_32x32@2x.png   64
gen icon_128x128.png    128
gen icon_128x128@2x.png 256
gen icon_256x256.png    256
gen icon_256x256@2x.png 512
gen icon_512x512.png    512
gen icon_512x512@2x.png 1024

iconutil --convert icns "$ICONSET" --output "$ROOT/Scripts/paperMD.icns"
echo "Wrote $ROOT/Scripts/paperMD.icns"
