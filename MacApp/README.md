# Mac Maintenance Suite

Native macOS maintenance app inspired by CleanMyMac's module structure, implemented with SwiftUI and local macOS APIs.

This milestone is no longer a Mole shell wrapper. The app now ships a native service layer for:

- Smart Care dashboard and transparent health score
- Cleanup planning and reversible fast cleanup to Trash
- Protection foundation with bundled AV test signature and persistence checks
- Privacy artifact metadata scan
- CPU/load, RAM, memory pressure, storage, process, and thermal snapshot
- Installed application inventory
- Large files, duplicates, and similar-image clutter scan
- Space Lens folder inventory
- Cloud sync folder discovery
- Lightweight menu bar monitor

App updater is intentionally excluded. Malware definition update is a separate product channel and still needs a signed remote definition feed before public release.

## Local Build

```bash
./MacApp/Scripts/package-local-app.sh
```

Outputs:

- `MacApp/dist/MacMaintenanceSuite.app`
- `MacApp/dist/MacMaintenanceSuite-local.dmg`

The default build uses ad-hoc signing for local testing.

## Developer ID Build

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="your-notarytool-profile" \
./MacApp/Scripts/package-local-app.sh
```

When `DEVELOPER_ID_APPLICATION` is set, the app is signed with Hardened Runtime and the DMG is signed. When `NOTARY_PROFILE` is also set, the script submits the DMG with `notarytool` and staples the result.

## Verification

```bash
swiftc -typecheck -parse-as-library -target arm64-apple-macosx14.0 MacApp/Sources/*.swift
hdiutil verify MacApp/dist/MacMaintenanceSuite-local.dmg
codesign --verify --deep --strict --verbose=2 MacApp/dist/MacMaintenanceSuite.app
spctl -a -vv MacApp/dist/MacMaintenanceSuite-local.dmg
```

`spctl` rejects ad-hoc local builds. It should only pass after Developer ID signing and notarization.
