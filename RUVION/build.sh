#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
OUTPUT="$ROOT/build/RUVION.app"
mkdir -p "$ROOT/build"
if [[ -e "$OUTPUT" ]]; then
  mv "$OUTPUT" "$ROOT/build/RUVION.previous-$(date +%Y%m%d%H%M%S).app"
fi

mkdir -p "$OUTPUT/Contents/MacOS" "$OUTPUT/Contents/Resources/web"
SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
CLANG="/Library/Developer/CommandLineTools/usr/bin/clang"
"$CLANG" -fobjc-arc -fmodules -isysroot "$SDK" -mmacosx-version-min=13.0 \
  -framework Cocoa -framework WebKit "$ROOT/AppDelegate.m" -o "$OUTPUT/Contents/MacOS/RUVION"
cp "$ROOT/Info.plist" "$OUTPUT/Contents/Info.plist"
cp -R "$ROOT/web/." "$OUTPUT/Contents/Resources/web/"
echo "$OUTPUT"
