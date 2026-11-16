#!/usr/bin/env bash
# Build the macOS installer (.pkg) and disk image (.dmg) of a release into OUT (default dist/).
# Both carry "Claude Multi Desktop.app", a small AppleScript front end with the script inside; the .pkg also
# installs the command to /usr/local/bin. They are not signed with an Apple Developer ID (the app is signed
# ad hoc), so Gatekeeper asks the user to allow them once. Usage: packaging/build.sh [OUT]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="$(sed -n 's/^VERSION="\(.*\)"$/\1/p' claude-multi-desktop)"
OUT="$(mkdir -p "${1:-dist}" && cd "${1:-dist}" && pwd)"
ID=io.github.jackson-cmd.claude-multi-desktop
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# 1. The app
APP="$W/stage/Claude Multi Desktop.app"
mkdir -p "$W/stage"
osacompile -o "$APP" packaging/manager.applescript
install -m 755 claude-multi-desktop "$APP/Contents/Resources/claude-multi-desktop"
osascript -l JavaScript packaging/draw-icon.js "$W/icon.png" "+" >/dev/null
mkdir -p "$W/icon.iconset"
for sz in 16 32 128 256 512; do
  sips -z "$sz" "$sz" "$W/icon.png" --out "$W/icon.iconset/icon_${sz}x${sz}.png" >/dev/null
  sips -z $((sz * 2)) $((sz * 2)) "$W/icon.png" --out "$W/icon.iconset/icon_${sz}x${sz}@2x.png" >/dev/null
done
iconutil -c icns "$W/icon.iconset" -o "$APP/Contents/Resources/applet.icns"
rm -f "$APP/Contents/Resources/Assets.car"            # the stock script icon; ours is applet.icns
PL="$APP/Contents/Info.plist"
plutil -remove CFBundleIconName "$PL" 2>/dev/null || true
plutil -replace CFBundleIconFile -string applet "$PL"
plutil -replace CFBundleIdentifier -string "$ID.app" "$PL"
plutil -replace CFBundleName -string "Claude Multi Desktop" "$PL"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$PL"
plutil -replace CFBundleVersion -string "$VERSION" "$PL"
plutil -replace NSHumanReadableCopyright -string "MIT License. Unofficial; not affiliated with Anthropic." "$PL"
codesign --force --deep --sign - "$APP" 2>/dev/null
codesign --verify --deep --strict "$APP"

# 2. The installer: the command in /usr/local/bin, the app in /Applications
mkdir -p "$W/root/usr/local/bin" "$W/root/Applications"
install -m 755 claude-multi-desktop "$W/root/usr/local/bin/claude-multi-desktop"
ditto "$APP" "$W/root/Applications/Claude Multi Desktop.app"
pkgbuild --analyze --root "$W/root" "$W/components.plist" >/dev/null
plutil -replace 0.BundleIsRelocatable -bool NO "$W/components.plist"
pkgbuild --quiet --root "$W/root" --component-plist "$W/components.plist" --identifier "$ID" --version "$VERSION" \
  --install-location / "$W/component.pkg"
mkdir -p "$W/res"
cp packaging/pkg/welcome.html packaging/pkg/conclusion.html "$W/res/"
cp LICENSE "$W/res/LICENSE.txt"
cat > "$W/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>claude-multi-desktop $VERSION</title>
  <welcome file="welcome.html" mime-type="text/html"/>
  <license file="LICENSE.txt"/>
  <conclusion file="conclusion.html" mime-type="text/html"/>
  <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
  <domains enable_localSystem="true"/>
  <volume-check><allowed-os-versions><os-version min="12.0"/></allowed-os-versions></volume-check>
  <choices-outline><line choice="default"><line choice="$ID"/></line></choices-outline>
  <choice id="default"/>
  <choice id="$ID" visible="false"><pkg-ref id="$ID"/></choice>
  <pkg-ref id="$ID" version="$VERSION" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
XML
productbuild --quiet --distribution "$W/distribution.xml" --resources "$W/res" --package-path "$W" \
  "$OUT/claude-multi-desktop-$VERSION.pkg"

# 3. The disk image: drag the app to Applications
ln -s /Applications "$W/stage/Applications"
hdiutil create -quiet -volname "claude-multi-desktop $VERSION" -srcfolder "$W/stage" -fs HFS+ -format UDZO -ov \
  "$OUT/claude-multi-desktop-$VERSION.dmg"

ls -l "$OUT"/claude-multi-desktop-"$VERSION".{pkg,dmg}
