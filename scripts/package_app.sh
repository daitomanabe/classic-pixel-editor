#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configuration="${CONFIGURATION:-release}"
build_path="${BUILD_PATH:-${TMPDIR:-/tmp}/classic-pixel-editor-package-build}"
dist_dir="$repo_root/dist"
app_name="Classic Pixel Editor"
bundle_id="ws.daito.classic-pixel-editor"
version="${VERSION:-0.1.0}"
build_number="${BUILD_NUMBER:-1}"
min_macos="${MACOSX_DEPLOYMENT_TARGET:-13.0}"
app_bundle="$dist_dir/$app_name.app"
contents_dir="$app_bundle/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
executable_name="ClassicPixelEditor"

cd "$repo_root"

swift build -c "$configuration" --product "$executable_name" --build-path "$build_path"

rm -rf "$app_bundle"
mkdir -p "$macos_dir" "$resources_dir"
cp "$build_path/$configuration/$executable_name" "$macos_dir/$executable_name"
chmod 755 "$macos_dir/$executable_name"

cat > "$contents_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$app_name</string>
  <key>CFBundleExecutable</key>
  <string>$executable_name</string>
  <key>CFBundleIdentifier</key>
  <string>$bundle_id</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$app_name</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$version</string>
  <key>CFBundleVersion</key>
  <string>$build_number</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.graphics-design</string>
  <key>LSMinimumSystemVersion</key>
  <string>$min_macos</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>PNG image</string>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.png</string>
      </array>
    </dict>
    <dict>
      <key>CFBundleTypeName</key>
      <string>JPEG image</string>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.jpeg</string>
      </array>
    </dict>
    <dict>
      <key>CFBundleTypeName</key>
      <string>TIFF image</string>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.tiff</string>
      </array>
    </dict>
    <dict>
      <key>CFBundleTypeName</key>
      <string>BMP image</string>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>com.microsoft.bmp</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

printf 'APPL????' > "$contents_dir/PkgInfo"

if command -v plutil >/dev/null 2>&1; then
  plutil -lint "$contents_dir/Info.plist"
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$app_bundle" >/dev/null
fi

printf 'Packaged %s\n' "$app_bundle"
