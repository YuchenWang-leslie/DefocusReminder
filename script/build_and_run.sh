#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="DefocusReminder"
PRODUCT_NAME="DefocusReminder"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
APP_BINARY="$MACOS/$APP_NAME"
INFO_PLIST="$ROOT_DIR/Sources/DefocusReminderApp/Info.plist"

cd "$ROOT_DIR"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --disable-sandbox --product "$PRODUCT_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"
cp "$(swift build --disable-sandbox --show-bin-path)/$PRODUCT_NAME" "$APP_BINARY"
cp "$INFO_PLIST" "$CONTENTS/Info.plist"
if [ -f "$ROOT_DIR/.build/AppIcon.icns" ]; then
  cp "$ROOT_DIR/.build/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi
chmod +x "$APP_BINARY"
codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"com.local.defocusreminder\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
