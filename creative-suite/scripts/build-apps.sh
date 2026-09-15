#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-release}"
if [[ "$MODE" != "release" && "$MODE" != "debug" ]]; then
    printf 'Usage: bash scripts/build-apps.sh [release|debug]\n' >&2
    exit 1
fi
swift build --package-path "$ROOT" -c "$MODE"
BIN="$(swift build --package-path "$ROOT" -c "$MODE" --show-bin-path)/DevinStudio"
DIST="${DEVIN_DIST:-$ROOT/dist/v0.4}"
if pgrep -f "$DIST/.*\\.app/Contents/MacOS/DevinStudio" >/dev/null; then
    printf 'Close the apps in %s before rebuilding them, or set DEVIN_DIST to a new destination.\n' "$DIST" >&2
    exit 1
fi
mkdir -p "$DIST"
"$BIN" --generate-icons "$DIST/.icons"
for TOOL in studio pixel form press lens cut motion sound frame folio code batch space; do
    NAME="Devin $(printf '%s' "$TOOL" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
    APP="$DIST/$NAME.app"
    mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
    cp "$BIN" "$APP/Contents/MacOS/DevinStudio"
    iconutil -c icns "$DIST/.icons/$TOOL.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
    cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>$NAME</string>
<key>CFBundleDisplayName</key><string>$NAME</string>
<key>CFBundleIdentifier</key><string>ai.devin.creative.$TOOL</string>
<key>CFBundleExecutable</key><string>DevinStudio</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.4.2</string>
<key>CFBundleVersion</key><string>6</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>DevinTool</key><string>$TOOL</string>
<key>CFBundleDocumentTypes</key><array><dict>
<key>CFBundleTypeName</key><string>Devin Creative Project</string>
<key>CFBundleTypeRole</key><string>Editor</string>
<key>LSHandlerRank</key><string>Alternate</string>
<key>LSItemContentTypes</key><array><string>ai.devin.creative.project</string></array>
</dict></array>
<key>UTExportedTypeDeclarations</key><array><dict>
<key>UTTypeIdentifier</key><string>ai.devin.creative.project</string>
<key>UTTypeDescription</key><string>Devin Creative Project</string>
<key>UTTypeConformsTo</key><array><string>public.json</string></array>
<key>UTTypeTagSpecification</key><dict>
<key>public.filename-extension</key><array><string>devin</string></array>
<key>public.mime-type</key><string>application/vnd.devin.project+json</string>
</dict></dict></array>
</dict></plist>
EOF
    plutil -lint "$APP/Contents/Info.plist"
    codesign --force --sign - "$APP"
    codesign --verify --strict "$APP"
    printf 'Built %s\n' "$APP"
done
printf '\nLaunch with: open "%s/Devin Studio.app"\n' "$DIST"
