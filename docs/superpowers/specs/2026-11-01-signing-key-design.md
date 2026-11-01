# The signing-key step: design
**Date:** 2026-11-01 · **Status:** draft, waiting for Ahmed's OK · **Task:** `docs/_Current_Task.md`

## Why
Android only lets an update replace an app when both carry the same signature, made with a signing key. Uplan's key
lived in the laptop's user folder, which was erased on 2026-10-24, so nothing built on this PC can update the Uplan on
Ahmed's phone (v1.15.1, assumed). The app's backup also leaves out note photos (it keeps only their file names), so
the usual "back up, uninstall, reinstall, restore" would lose every photo.

## What Ahmed picked (2026-11-01)
**Side by side:** v1.18.0 installs as a second app next to the old one, and nothing is uninstalled. The old app stays
as a photo album until he has moved what he wants; removing it later is his call.

## The design
1. **A new app ID: `io.github.manjo00.uplan`** (Claude's call). The app ID is the hidden name Android and Google Play
   know the app by. It is permanent and becomes the Play ID. It follows the usual pattern for a project on GitHub
   (`manjo00.github.io` turned around). No public Play app uses it (checked 2026-11-01: its Play page answers 404).
   Only `applicationId` in `android/app/build.gradle.kts` changes. The code's own package (`com.lifetracker.life_tracker`,
   the `namespace`) stays, so the widgets, alarms and live dashboard keep working (checked: the Kotlin code always
   targets its own classes, the in-app updater only opens a download link, and the manifest's providers use
   `${applicationId}`).
2. **A real signing key:** one RSA 4096 key, valid about 27 years (10,000 days), made with Java 21's `keytool` and
   kept at `D:\keys\uplan\uplan-release.jks`, outside every repo. Its password is random, made by a script and written
   only into `android/key.properties` (git-ignored); it never appears in chat, logs or git. Google Play accepts this key
   later as the app's own (checked: "Must be an RSA key of 2048 bits or more", uploaded with Google's PEPK tool), so
   the phone won't need another move for Play.
3. **Its backup:** with Ahmed's yes, a copy of the key file goes into a folder in his OneDrive (for example
   `OneDrive\Uplan key backup`). He keeps the password in his password manager or a locked note on his phone, never
   next to the key file. The key's fingerprint (public, safe to share) goes into START HERE so every release can be
   checked against it.
4. **Builds:** release builds sign with the new key when `android/key.properties` exists, and fall back to the debug
   key when it doesn't (cloud chats, fresh clones), so builds never break. Before anything is published, the release
   ritual checks that the APK carries the new key's fingerprint.
5. **The restore fix:** v1.18.0 learns to read older backups. Fields added after a backup was made (for example
   `isFavorite` on notes and notebooks, added in schemas 24 and 25) get their defaults instead of failing the whole
   import. A regression test with a backup shaped like v1.15.1's (schema 22) fails on today's code and passes after.

## Moving his data (his hands, guided one step at a time)
1. **Old app:** Settings > Export data, and the file comes to the PC. A test on the PC restores his real file into
   v1.18.0 and compares the counts (notes, tasks, habits and the rest) before anything is installed. His file stays
   out of git: it holds his personal data, and the repo shows as public on GitHub.
2. **Install** v1.18.0 next to the old app. In the new app: Settings > Import data, pick the file, then compare the
   counts with the old app.
3. **New app:** allow notifications and alarms, add the home-screen widgets again, and set the Settings again from a
   checklist of what the backup doesn't carry.
4. **Old app:** notifications off, its widgets removed, its icon moved into a folder (for example "Old Uplan"). Nothing
   new goes into it from then on, because the new app won't see it.
5. **Photos:** open them in the old app, screenshot the ones he wants, and add them to the notes in the new app, at his
   own pace.

## Not in this step
- Backups that carry photos and Settings (a parked idea, noted in the current task).
- The Google Play upload and a separate upload key (when Play comes).
- Publishing v1.18.0 on `manjo00/uplan-releases` (the next step, with his OK).

## Testing
The restore regression test; the code checker and all tests; a release build signed with the new key, checked with
`apksigner`; then the real try on his phone (the steps above), which only his eyes can confirm.

## Risks
- Until the old app's notifications are off, reminders come twice.
- Both apps show up as "Uplan" in the share menu and the app list until the old one is removed.
- If Smart App Control turns itself on, release builds stop working on this PC. It is never changed, so the move
  would wait.
- An unpublished or removed Play app could still hold the new ID; Play only says so at the first upload. Then the Play
  version would need another ID, and the phone another move like this one.
