#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="DefocusReminder"
PRODUCT_NAME="DefocusReminder"
INFO_PLIST="Sources/DefocusReminderApp/Info.plist"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

if ! command -v swift >/dev/null 2>&1; then
    echo "error: swift was not found. Install Xcode or Xcode Command Line Tools first." >&2
    exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
    echo "error: hdiutil was not found. DMG packaging must run on macOS." >&2
    exit 1
fi

VERSION="$(
    /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null \
        || echo "0.1.0"
)"

DIST_DIR="$PWD/dist"
WORK_DIR="$PWD/.build/package-dmg"
APP_ROOT="$WORK_DIR/${APP_NAME}.app"
CONTENTS="$APP_ROOT/Contents"
DMG_ROOT="$WORK_DIR/dmg-root"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.zip"

echo "Building ${PRODUCT_NAME}..."
swift build -c release --product "$PRODUCT_NAME"
swift scripts/generate-icon.swift

rm -rf "$WORK_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$DIST_DIR"

cp ".build/release/${PRODUCT_NAME}" "$CONTENTS/MacOS/${APP_NAME}"
cp "$INFO_PLIST" "$CONTENTS/Info.plist"
cp ".build/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
chmod +x "$CONTENTS/MacOS/${APP_NAME}"
chmod -R a+rX "$APP_ROOT"

echo "Signing app with identity: ${SIGN_IDENTITY}"
codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_ROOT"

mkdir -p "$DMG_ROOT"
cp -R "$APP_ROOT" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
cat > "$DMG_ROOT/Install.txt" <<EOF
Install DefocusReminder

1. Drag DefocusReminder.app to Applications.
2. If dragging to Applications fails because of permissions, drag DefocusReminder.app to Desktop or to your own ~/Applications folder.
3. The DMG window itself is read-only. You cannot move files around inside the DMG.
4. On first launch, if macOS warns about an unidentified developer, right-click DefocusReminder.app and choose Open.

安装 DefocusReminder

1. 把 DefocusReminder.app 拖到 Applications。
2. 如果因为权限拖不进去，可以拖到桌面，或拖到你自己的 ~/Applications 文件夹。
3. DMG 窗口本身是只读的，不能在 DMG 里面移动文件。
4. 第一次启动如果 macOS 提示无法验证开发者，请右键 DefocusReminder.app，然后选择“打开”。
EOF

rm -f "$DMG_PATH"
echo "Creating DMG..."
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -f "$ZIP_PATH"
echo "Creating ZIP fallback..."
ditto -c -k --keepParent "$APP_ROOT" "$ZIP_PATH"

echo "Created: $DMG_PATH"
echo "Created: $ZIP_PATH"
echo "Users can drag ${APP_NAME}.app into Applications after opening the DMG."
