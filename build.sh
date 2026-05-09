#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="DefocusReminder"
APP_ROOT="$HOME/Applications/${APP_NAME}.app"
CONTENTS="$APP_ROOT/Contents"

swift build -c release
swift scripts/generate-icon.swift

rm -rf "$APP_ROOT"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
if [ -x ".build/release/${APP_NAME}" ]; then
    cp ".build/release/${APP_NAME}" "$CONTENTS/MacOS/"
else
    cp ".build/release/${APP_NAME}App" "$CONTENTS/MacOS/${APP_NAME}"
fi
cp "Sources/DefocusReminderApp/Info.plist" "$CONTENTS/Info.plist"
cp ".build/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP_ROOT"

echo "Installed to $APP_ROOT"
echo "Run: open \"$APP_ROOT\""
