---
name: uplan-device-release
description: Uplan's verified device + release workflow. Use whenever deploying the app to the Z Flip 6 or the emulator, taking or tapping device screenshots via adb, driving the phone UI, committing with a multi-line message, or publishing an app update / GitHub release. Every pattern here was learned by hitting the failure the naive approach causes — follow these verbatim instead of rediscovering.
---

# Uplan device & release workflow

Project root: `C:\Projects\life_tracker` (run all flutter/git commands from there).
Shell is Windows PowerShell 5.1 unless noted — that shapes several gotchas below.

## Devices & adb

- adb lives at `"$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"` (not on PATH).
- Real device: Samsung Z Flip 6, serial `R5CX631BMJB`, screen **1080 × 2640**, One UI 8.
- Emulator: `emulator-5554`.
- App package id: `com.lifetracker.life_tracker` (display name "Uplan").
- When both devices are attached, always pass `-s <serial>`.

## Deploying a build

Emulator (day-to-day dev): `flutter run -d emulator-5554`.

Real device (release APK — release builds are debug-signed, fine for sideload):

```powershell
flutter build apk --release
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s R5CX631BMJB install -r build\app\outputs\flutter-apk\app-release.apk
```

Relaunch cleanly after install (force-stop first — otherwise you may resume a stale
activity and test old code):

```powershell
& $adb -s R5CX631BMJB shell am force-stop com.lifetracker.life_tracker
& $adb -s R5CX631BMJB shell monkey -p com.lifetracker.life_tracker -c android.intent.category.LAUNCHER 1
```

(`monkey` is used because it needs no activity name; 1 event = just launch.)

## Screenshots & tapping the phone

**Never** redirect screencap output through PowerShell (`adb exec-out screencap -p > x.png`)
— PowerShell's `>` re-encodes the byte stream and corrupts the PNG. Always write on the
device, then pull:

```powershell
& $adb -s R5CX631BMJB shell screencap -p /sdcard/uplan_shot.png
& $adb -s R5CX631BMJB pull /sdcard/uplan_shot.png <scratchpad>\shot.png
& $adb -s R5CX631BMJB shell rm /sdcard/uplan_shot.png
```

Then Read the pulled PNG to view it.

**Coordinate scaling:** the Read tool displays the 1080×2640 screenshot at ~818×2000.
To tap something you located in the displayed image, multiply both coordinates by
**1.32** before `shell input tap X Y`. After any tap, take a fresh screenshot to verify
— the UI may have shifted (dialogs, shade collapse), and a stale mental model sends
taps into the wrong app.

## Git commits with multi-line messages

PowerShell here-strings passed to `git commit -m` shatter into pathspecs when the
message contains quotes, parentheses, or `#`. Always write the message to a scratchpad
file and use `-F`:

```powershell
git commit -F <scratchpad>\commit_msg.txt
```

Conventional Commits (`feat:`/`fix:`/`chore:`…), and end with the Co-Authored-By line
per the harness convention. Commit after every working feature/fix; `master` stays green.

## Publishing an app update (release ritual)

Updates ship through the **public releases-only repo `manjo00/uplan-releases`** — never
the private source repo `manjo00/trackerapp`. The in-app UpdateService polls
`releases/latest` unauthenticated.

1. Bump `version:` in `pubspec.yaml` (both semver and build number, e.g. `1.2.0+4`) —
   the tag must match the semver or the update dialog never fires.
2. `flutter build apk --release` → `build\app\outputs\flutter-apk\app-release.apk`.
3. Create the release with gh (or browser):

```powershell
gh release create vX.Y.Z --repo manjo00/uplan-releases --title "Uplan vX.Y.Z" --notes "changelog here" build\app\outputs\flutter-apk\app-release.apk
```

Hard-learned rules:
- **The `.apk` asset is mandatory** — UpdateService silently ignores releases with no
  `.apk` attached (this looked like "update check broken" once; it wasn't).
- **Publish, not draft** — a draft release is invisible to the API; the browser flow
  quietly saves drafts if the APK upload hasn't finished when you click.
- The in-app auto-check is throttled to once per 24 h; to test immediately use
  Settings → "Check for updates" (manual tile bypasses the throttle).

## Build hygiene checkpoints

- After any Drift schema or freezed model change:
  `dart run build_runner build --delete-conflicting-outputs`.
- `flutter analyze` must be clean before any commit (Definition of Done).
