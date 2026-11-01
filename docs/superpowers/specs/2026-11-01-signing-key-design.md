# The signing-key step: design
**Date:** 2026-11-01 · **Status:** approved by Ahmed on 2026-11-01 ("Looks right") · **Plan:**
`docs/superpowers/plans/2026-11-01-signing-key.md` · **Task:** `docs/_Current_Task.md`

## Why
Android only lets an update replace an app when both carry the same signature, made with a signing key. Uplan's key
lived in the laptop's user folder, which was erased on 2026-10-24, so nothing built on this PC can update the Uplan on
Ahmed's Z Flip 6. The app's own backup (Settings > Export data) also leaves out the photos and the Settings.

## What we found on the phone (checked over adb, 2026-11-01)
The phone runs v1.18.0 (versionCode 27), a **debuggable** build, so `adb shell run-as com.lifetracker.life_tracker`
can read its private folder: `app_flutter/life_tracker.db`, `app_flutter/note_images/` (309 photos, 457 MB),
`shared_prefs/` (Settings, widget data, scheduled notifications), `databases/` and `files/`. Only the values kept by
`flutter_secure_storage` can't move, because Android's key store locks them to the old install. The only thing kept
there is the in-app feedback's GitHub key (`lib/core/github/github_feedback_service.dart`).

## What Ahmed picked (2026-11-01)
**One app with the same ID** (`com.lifetracker.life_tracker`), moved by a full copy of its private folder. This
replaced his earlier "side by side" pick, made while the photos looked impossible to copy.

## The design
1. **A real signing key.** One RSA 4096 key, valid 10,000 days (about 27 years), PKCS12, made with
   `D:\dev\jdk-21\bin\keytool.exe` at `D:\keys\uplan\uplan-release.jks`, outside every repo. Its password is random,
   made by a script and written only into `android/key.properties` (git-ignored); it never appears in chat, logs or
   git. Google Play accepts this key later as the app's own (checked: "Must be an RSA key of 2048 bits or more",
   uploaded with Google's PEPK tool).
2. **Its backup.** With Ahmed's yes, a copy of the key file goes into a folder in his OneDrive (for example
   `OneDrive\Uplan key backup`). He keeps the password in his password manager or a locked note on his phone, never
   next to the key file. The key's SHA-256 fingerprint (public, safe to share) goes into START HERE and the device
   skill.
3. **Builds.** `android/app/build.gradle.kts` signs debug and release builds with the new key when
   `android/key.properties` exists, and falls back to the debug key when it doesn't (cloud chats, fresh clones), so
   builds never break. The phone gets a debug build first, like today's, because only a debuggable app lets `run-as`
   put the data back. No Dart code changes.
4. **The copy.** With the app force-stopped, `adb exec-out run-as … tar` streams the private folder to
   `D:\backups\uplan\2026-11-01\`, outside every repo (it is his personal data, and the repo shows as public on
   GitHub). Checks on the PC: SQLite's integrity check passes, every photo the notes point to is in `note_images/`
   (309 files), and the row counts per table are written down so the rehearsal and the move can be compared with
   them. Left out when putting it back: `cache/`, `code_cache/`, `app_flutter/flutter_assets/` and the `res_timestamp`
   file (the new install makes its own), and the secure-storage files (unreadable in a new install, so that part
   starts empty).
5. **Dress rehearsal.** A throwaway debug build with a different ID (`com.lifetracker.life_tracker.rehearsal`, a
   temporary local change, never committed) installs next to his app. The copy goes into it with
   `adb exec-in run-as … tar`; its database's row counts are compared with the copy's, and Ahmed checks his notes,
   photos and Settings in it. It gets no notification permission, so it can't send reminders. Then it is removed.
   This proves the "put it back" step on his phone before his real app is touched.
6. **The move.** From the final copy to the end, Ahmed doesn't use the app. A final copy and a quick re-check; remove
   the old app (`adb uninstall`); install the new-key debug build under the same ID; put the copy back before the
   app's first start; compare the row counts; open it. He checks it, allows notifications and alarms again, adds the
   widgets again, and enters the feedback key again if he uses it. Reminders: the number of Uplan alarms Android holds
   (`dumpsys alarm`) is counted before and after; if they don't come back when the app starts, a phone restart brings
   them back.
7. **The release ritual** (`.claude/skills/uplan-device-release/SKILL.md`) signs with the new key and checks the APK's
   fingerprint before any install or release. The old debug key (cert `94392f58…f94ee6b3`) is retired.

## Not in this step
- A normal (non-debuggable) release build on the phone, and publishing v1.18.0 on `manjo00/uplan-releases`: the next
  step, with his OK. Once the phone runs a normal build, `run-as` stops working, so a backup that carries photos and
  Settings (parked idea) matters more from then on.
- The old-backup restore bug (under Noticed in the current task).
- The Google Play upload and a separate upload key (when Play comes).

## Testing
The code checker and all tests, once; `apksigner verify --print-certs` shows the new fingerprint on both APKs; the
copy's checks above; then the dress rehearsal and the real move, which only Ahmed's eyes can confirm.

## Risks
- **The uninstall deletes the old app's folder.** It happens only after the copy is checked on D: and the rehearsal
  has passed, and the copy stays on D: until he is happy.
- `run-as` can't write into a new install (a phone or Samsung limit): the rehearsal shows it before anything is
  removed, and then we stop and rethink.
- The USB link drops mid-copy if the phone sleeps: keep its screen on during the copy; the checks catch a short copy.
- Reminders don't ring during the few minutes the app is off the phone.
- An unpublished or removed Play app could still hold the ID; Play only says so at the first upload.
