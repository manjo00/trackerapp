# Current Task: the signing-key step (move to a real signing key without losing data)
**Started:** 2026-11-01 (Ahmed: "Yes, start it") · **Branch:** master · **Path:** the careful one (brainstorm, a
one-page design he approves, a short plan), because an uninstall deletes the app's data

## Goal
Get v1.18.0 onto Ahmed's Z Flip 6 without losing any of his data, signed with a real release key that is backed up
off C: and can later become the app's signing key on Google Play.

## Found so far (2026-11-01; checked unless marked)
- **Google Play accepts our own key** (checked: support.google.com/googleplay/android-developer/answer/9842756):
  "Must be an RSA key of 2048 bits or more", uploaded with Google's PEPK tool. So a key made now can serve Play later,
  and the phone needs only this one reinstall. A lost upload key is recoverable later (Play's upload key reset).
- **The app ID `com.lifetracker.life_tracker` isn't used by any public app on Play** (checked: its Play page answers
  404 "Not Found"). An unpublished or removed app could still hold it; Play only says so at the first upload.
- **The backup has no photo files** (checked: `lib/core/backup/backup_service.dart`,
  `lib/core/images/image_storage_service.dart`). Photos live in `<app documents>/note_images/`; the backup JSON keeps
  only their file names, so restored photo blocks show "Image unavailable". The app has no share or save action for
  photos (checked: no share code under `lib/features/notes`). The phone's Uplan is a release build (per the release
  ritual; not checked on the phone), so `adb run-as` can't copy the files out either. Photos picked from the Gallery
  may still have their originals there; photos taken with the in-app camera likely don't (from memory).
- **v1.18.0 can't restore a v1.15.1 backup yet** (checked in the code, not yet by a test): v1.15.1 is schema 22,
  v1.18.0 is 25. Schema 24 added `notes.isFavorite` and 25 added `notebooks.isFavorite`, both required booleans, and
  the generated `fromJson` throws when a key is missing, so the whole import rolls back. Needed whichever way he
  picks: fill the defaults for keys an older backup lacks, with a regression test that fails on today's code.
- **Settings choices aren't in the backup** (checked: 10 files in `lib/` use SharedPreferences; the backup reads only
  the database). List them before the move so he can set them again.
- Assumed, not checked: only Ahmed uses Uplan; the phone runs v1.15.1 (check with adb before the move).

## Decided
- **Side by side** (Ahmed, 2026-11-01, over "uninstall and restore"): v1.18.0 gets a new app ID and installs beside
  the old app, so nothing is deleted; the old app stays as a photo album until he has moved what he wants.

## Waiting on Ahmed
- **His OK on the design:** `docs/superpowers/specs/2026-11-01-signing-key-design.md` (asked 2026-11-01). Then a
  short plan (superpowers' writing-plans, carried out in this chat with executing-plans) and one go-ahead that names
  every step on the phone.

## Later, after this step
1. Release v1.18.0 (it carries v1.16.0 and v1.17.0 too) with the release ritual in
   `.claude/skills/uplan-device-release/SKILL.md`. A release build needs Smart App Control to stay in evaluation mode.
2. G4's owed check: time the inexact-alarm path on the Z Flip 6 (recipe in `docs/superpowers/STATUS-2026-07-28.md`, G4 section).
3. **Heavy testing, then Google Play** (Ahmed, 2026-10-31; master plan, "Before a Play Store launch"). First shape with
   him what the testing covers (superpowers' brainstorming).

## Also waiting on Ahmed (written 2026-10-31 20:40, before this chat's fresh start)
- **His opinion for two retros** (asked: "in a few words, how did this install round feel to you?"). Then add both to
  `D:\projects\claude-setup\workflow\retros.md`:
  1. The auto-load kit's first live test (2026-10-31): START HERE, the current task and the last 5 history lines all
     loaded by themselves.
  2. The build-tools install (2026-10-31): estimate "small: 20–30 min of my work, 20–40 min of downloads, then a
     5–10 min first build"; real about 75 min (14:16–15:30), with an unplanned switch from Flutter 3.47.9 to 3.44.9
     and a 17-min first build. Demo first, no helpers. Mistakes: the newest Flutter went in before reading the app's
     pinned version; two Android SDK installs sent Google usage data before `--no-metrics`; the build estimate forgot
     a fresh PC's downloads. Tokens: not counted yet (count them from this chat's transcript the Live Tracker's way).
- **His own OK for two START HERE lines** (from this chat's round-table plan, which he approved through the Manager on
  2026-10-31; a `CLAUDE.md` edit waits for his word in this chat): the pinned versions (Flutter 3.44 from `.metadata`;
  AGP, Gradle, Kotlin and the NDK from the Android build files), and `docs/_Undo_Table.md` in the handover-files line.
- **His yes to switch Flutter's and Dart's usage reporting off outside the Claude app too.** Checked from outside on
  2026-10-31: the opt-out was saved under `%APPDATA%`, so it holds only inside the app (`docs/_Undo_Table.md`, row 3).
  Nothing runs Flutter outside the app today. The fix: run `D:\dev\flutter\bin\flutter.bat --disable-analytics` and
  `D:\dev\flutter\bin\dart.bat --disable-analytics` from a `.cmd` started through explorer.exe.
- This chat's round-table plan (approved 2026-10-31) also says: read the project's pinned versions before any install,
  switch a new tool's usage reporting off before its first run, and lead every reply with the answer.

## Done means
- [x] Ahmed picks the way to move his data: side by side (2026-11-01).
- [ ] A one-page design he approves (`docs/superpowers/specs/2026-11-01-signing-key-design.md`), then a short plan.
- [ ] v1.18.0 restores a v1.15.1 backup: a regression test that fails on today's code and passes after the fix.
- [ ] A real release key (RSA 4096) made, kept outside the repo and backed up off C:; its passwords only in the
      git-ignored `android/key.properties` and Ahmed's own safe place; release builds signed with it.
- [ ] v1.18.0 on the phone with all his data, checked by him; the old app handled the way he picked.
- [ ] The release ritual signs with the new key and checks the signature before publishing.

## Do not touch
- The phone: nothing installed, uninstalled or exported until Ahmed's go-ahead names every step.
- No key file or password in git, chat or logs. Smart App Control and other security settings stay as they are.

## Noticed (not fixing now)
- **The backup could carry photos and Settings** (a zip with the JSON plus `note_images/`), so a lost phone or a
  future reinstall keeps them. Found 2026-11-01; not this task. For the master plan's parked list if Ahmed wants it.
- **AppData writes from a chat stay inside the Claude app's private copy**, like the registry. Checked from outside on
  2026-10-31: `%LOCALAPPDATA%\pip`, `%LOCALAPPDATA%\npm-cache` and `%APPDATA%\GitHub CLI` exist only inside the app.
  That's why the build tools and the Dart package cache live in `D:\dev`. Passed to the AI management chat.
- `flutter doctor` says "Android license status unknown": it can't read the new Android CLI's license list. The build's
  own license check passes. Only the Android SDK license was accepted (Ahmed's OK, 2026-10-31).
- The first build on this PC left `android/.kotlin/` (Kotlin's build session folder) untracked. It belongs in `android/.gitignore`; not committed.
- The 10 plan files in `docs/superpowers/plans/` never had their check boxes ticked, although the work shipped. The master plan is the record of what is done.
- `feedback/app.md` still shows all 4 items unticked. 3 are done (today marker in v1.9.1; per-list auto-archive and photo crop in v1.10.0); the 4th (a Samsung- or Apple-style note design) is largely answered by the notes redesign.
- STATUS refers to "Working Style #11" (general, non-clinical examples in user-facing text), but this repo's `CLAUDE.md` lists only 8 Working Style rules. STATUS also says the durable project history lived in a CLAUDE.md in OneDrive, outside the repo. No such file was found in OneDrive on this PC (2026-10-27), so rules 9 and up may be lost. The decisions log records #11.
- STATUS's "IN-FLIGHT" section (2026-07-28) is out of date: the editor redesign and the photo grid shipped in v1.10.0, and the August shift entry is long past.
- `README.md` is still Flutter's default text.
- GitHub shows this repo as public, while the device skill calls it "the private source repo". Worth checking which one Ahmed wants.
