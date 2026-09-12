#!/bin/bash
# Build locally with Xcode; no downloads, account access or installation.
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$project_dir/build"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/reset-radar-build.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT
mkdir -p "$build_dir"
cd "$project_dir"
for cpu in arm64 x86_64; do
  xcrun swiftc -warnings-as-errors -target "$cpu-apple-macos13.0" \
    -module-cache-path "$temp_dir/cache-$cpu" \
    Sources/main.swift -o "$temp_dir/ResetRadar-$cpu" \
    -framework Cocoa -framework SwiftUI -framework Security
done
app_dir="$temp_dir/Reset Radar.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
lipo -create "$temp_dir/ResetRadar-arm64" "$temp_dir/ResetRadar-x86_64" -output "$app_dir/Contents/MacOS/ResetRadar"
cp "$project_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/Resources/Connection Guide.html" "$app_dir/Contents/Resources/Connection Guide.html"
cp "$project_dir/LICENSE" "$app_dir/Contents/Resources/LICENSE.txt"
"$app_dir/Contents/MacOS/ResetRadar" --self-test
xattr -cr "$app_dir"
codesign --force --sign - "$app_dir"
codesign --verify --deep --strict "$app_dir"
# Do not overwrite an app that somebody may currently be running from build/.
# The archive is the single build output; extract it wherever you want to test.
ditto -c -k --norsrc --noextattr --keepParent "$app_dir" "$build_dir/Reset Radar.zip"
(cd "$build_dir" && shasum -a 256 "Reset Radar.zip" > SHA256.txt)
printf 'Built and tested: %s\n' "$build_dir/Reset Radar.zip"
