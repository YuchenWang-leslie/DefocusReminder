# DefocusReminder

DefocusReminder is a clean, lightweight macOS menu bar app for work/break reminders.

It is a greenfield extraction of the useful ideas from HealthTick:

- custom work days and work hours
- configurable work and break durations
- menu bar countdown with current status
- click-to-start and click-to-finish break flow
- menu or floating break reminder
- local rest recommendations based on profession and body signals
- daily work/rest duration history

It intentionally omits badges, sharing, donations, auto-update, fullscreen enforcement, and check-in gamification.

## Build

Requires macOS 14+ and Swift 5.9+.

```bash
swift build -c release
```

To create a local app bundle:

```bash
bash build.sh
```

The build script generates `AppIcon.icns` from `Assets/AppIconSource.png` and
copies it into the app bundle.

To create a shareable DMG:

```bash
bash package-dmg.sh
```

The DMG is written to:

```text
dist/DefocusReminder-0.1.0.dmg
```

The script also creates a ZIP fallback:

```text
dist/DefocusReminder-0.1.0.zip
```

If someone cannot drag the app into `/Applications`, they can drag it to Desktop
or to their own `~/Applications` folder instead. The app does not have to live in
the system-wide Applications folder.

This default DMG is ad-hoc signed, which is fine for local testing and sharing
with a small group. macOS may still show an "unidentified developer" warning on
other machines. For public distribution, sign with a Developer ID certificate
and notarize the DMG:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" bash package-dmg.sh
xcrun notarytool submit dist/DefocusReminder-0.1.0.dmg --keychain-profile "notary-profile" --wait
xcrun stapler staple dist/DefocusReminder-0.1.0.dmg
```

## Data

State is stored as JSON at:

```text
~/Library/Application Support/DefocusReminder/state.json
```
