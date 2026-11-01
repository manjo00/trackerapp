# Current Task: Tester, a speed and quality pass (2026-11-01)
**Date:** 2026-11-01 · **Branch:** master · **Chat:** Tester, a temporary chat the Uplan chat started at Ahmed's
request. It owns the repo's work until it hands back.

## Goal (Ahmed, 2026-11-01, his words)
"make the app cleaner and fast and responsive can you download it in multiple sims and ask helpers including yourself
to not just the product and visuals but the code also make a review in round table manner and find problems and fixes
and ideas need to be implemented like if something is coded inefficiently. i found that adding a task from the widget
is a bit laggy."

## Steps (in order)
1. ✅ Start: START HERE, this file, the history and the code map read (2026-11-01 09:50).
2. ⬜ **← here.** Size the whole job and get his yes before any helper starts (asked 2026-11-01 about 10:00; see
   "Proposed size").
3. ⬜ Emulators: his own click to turn on Windows Hypervisor Platform, a restart, then the emulator and two Android
   versions into `D:\dev\android-sdk`, with the AVDs in `D:\dev\android-avd` (not on C:). Spread: a small phone, a
   Flip-like 1080 × 2640 phone, a large phone; Android 16 (his phone's) and Android 13.
4. ⬜ The round table: helpers plus this chat review the product and flows, the visuals and the code (needless
   rebuilds, database queries, startup, the home-screen widgets). Each finding: the problem as behaviour, where in
   the code, the fix, its cost, its gain. One ranked list, on a page for his tablet and in `docs/`.
5. ⬜ The widget's laggy add-task: reproduce, measure on a profile or release build (not debug), find the cause
   (superpowers' systematic-debugging), fix it with a regression test that fails on the old code.
6. ⬜ The fixes he picks, demo first, in batches; analyze clean and tests green; commit on `master`; push.
7. ⬜ Hand back: state into these files, then offer to be archived.

## Checked so far (2026-11-01, read only; nothing on the PC or the phone changed)
- **The PC can run emulators after one Windows switch.** AMD virtualization is on in the BIOS
  (`Win32_Processor.VirtualizationFirmwareEnabled` True) and Windows' own hypervisor already runs for Memory Integrity
  (`Win32_DeviceGuard`: VBS and HVCI running). Windows Hypervisor Platform, Virtual Machine Platform and Hyper-V are
  all off (`Win32_OptionalFeature` InstallState 2). The emulator needs Windows Hypervisor Platform on: Ahmed's own
  click (Turn Windows features on or off), then a restart. Google's AMD driver (AEHD) is no way around it: as I
  remember Google's docs, it can't run while Windows' hypervisor does (not checked).
- 16 GB RAM (one emulator at a time is the comfortable load), 6 cores; free space C: 348 GB, D: 230 GB.
- `D:\dev\android-sdk` has no emulator, no system images and no AVDs (platforms 34–36, build-tools 36.0.0,
  cmdline-tools whose `sdkmanager` now hands over to `android.exe`: pass `--no-metrics`).
- Download sizes (Google's repository lists, read 2026-11-01): emulator 37.2.13 (stable) 455 MB; Android 16
  `system-images;android-36;google_apis;x86_64` 1,895 MB; Android 13 `android-33` 1,708 MB (Android 12 `android-31`
  1,471 MB; Android 17 `android-37.0` 2,144 MB). The emulator plus Android 16 and 13: about 4.1 GB.
- The code: 215 hand-written Dart files, about 36,700 lines in `lib/` (workout 8.4k, notes 5.0k, tasks 4.0k, trackers
  2.6k, home 2.1k), 46 test files. The home-screen widgets: Kotlin in
  `android/app/src/main/kotlin/com/lifetracker/life_tracker/` (`Uplan*WidgetProvider.kt`, `*RemoteViewsFactory.kt`,
  `MainActivity.kt`) plus `lib/core/widget/home_widget_service.dart` and
  `lib/features/tasks/presentation/screens/quick_add_task_screen.dart`.
- Not checked yet: whether a profile build keeps the phone's `run-as` door open (as I remember it, Flutter's profile
  build type copies the debug one, so probably yes; check the APK's `debuggable` flag before saying so).

## Proposed size (asked 2026-11-01 about 10:00, waiting on Ahmed)
Big, in rounds: my work about 2–3 h before the fixes (emulators 20–30 min, screenshots on three sizes 20–30 min, the
widget lag 45–90 min, the ranked page 30–45 min), plus 30–60 min of waiting (downloads, builds, tests); the fixes get
their own estimate once he picks. Tokens (guesses from earlier helpers' costs): two helpers (product and looks; code)
plus this chat about 0.9–1.4M; three helpers about 1.1–1.7M; this chat alone about 0.7–1.0M. His yes also covers the
4.1 GB download above.

## Must know (from the Uplan chat's brief)
- The phone's Uplan is a debug build (slow): judge speed on a profile or release build (an emulator, or his phone
  with his OK). A release build on the phone closes `adb run-as`, today the only full copy of its data: his call.
- Never uninstall the phone's app. Check an APK's fingerprint before `adb install -r` (device skill), and copy his
  data off first the way the move did (`docs/superpowers/plans/2026-11-01-signing-key.md`, Task 4).
- Stay on Flutter 3.44. Android CLI commands need `--no-metrics`. Never change Smart App Control.

## Carried over from the signing-key move (2026-11-01)
- **The signing-key move is done** (2026-11-01; plan `docs/superpowers/plans/2026-11-01-signing-key.md`, design
  `docs/superpowers/specs/2026-11-01-signing-key-design.md`). The phone's Uplan (v1.18.0+27, a debuggable build) is
  now signed with Uplan's own key (START HERE has its place and fingerprint), under the same app ID, with all its
  data: the database byte for byte (SHA-256 `9a9ad0ad…`), all 309 photos, the Settings. Uplan's alarm entries came
  back (40 after the move, 38 before). Ahmed's first look: "initial; look is ok".
- The checked copy of the phone's folder stays in `D:\backups\uplan\2026-11-01\` (personal data, never in git) until
  Ahmed is happy; what happens to it then is his call.
- Asked of Ahmed after the move, not confirmed yet: Alarms & reminders on, battery Unrestricted, the widgets added
  again, the feedback key typed in again if he uses it, and the key's password copied into his own safe place.

## Later
1. Release v1.18.0 (it carries v1.16.0 and v1.17.0 too) with the release ritual in
   `.claude/skills/uplan-device-release/SKILL.md`. A release build needs Smart App Control in evaluation mode. A
   release build on the phone isn't debuggable, so `run-as` would stop working there, and the app's backup leaves out
   photos and Settings: decide that with Ahmed first.
2. G4's owed check: time the inexact-alarm path on the Z Flip 6 (recipe in `docs/superpowers/STATUS-2026-07-28.md`, G4 section).
3. **Heavy testing, then Google Play** (Ahmed, 2026-10-31; master plan, "Before a Play Store launch").

## What the signing-key move found (2026-11-01; checked unless marked)
- **Google Play accepts our own key** (checked: support.google.com/googleplay/android-developer/answer/9842756):
  "Must be an RSA key of 2048 bits or more", uploaded with Google's PEPK tool. So a key made now can serve Play later,
  and the phone needs only this one reinstall. A lost upload key is recoverable later (Play's upload key reset).
- **The app ID `com.lifetracker.life_tracker` isn't used by any public app on Play** (checked: its Play page answers
  404 "Not Found"). An unpublished or removed app could still hold it; Play only says so at the first upload.
- **The backup has no photo files** (checked: `lib/core/backup/backup_service.dart`,
  `lib/core/images/image_storage_service.dart`). Photos live in `<app documents>/note_images/`; the backup JSON keeps
  only their file names, and the app has no share or save action for photos. Settings (SharedPreferences) aren't in
  it either.
- **But the phone's Uplan is a test build, so the cable tool can copy everything** (checked on the phone over adb,
  2026-11-01, after Ahmed asked why the photos can't move): `dumpsys` shows v1.18.0 (versionCode 27), installed
  2026-06-29, last updated 2026-09-29 23:49, with the `DEBUGGABLE` flag, and `adb shell run-as
  com.lifetracker.life_tracker` opens its private folder. Inside: `app_flutter/life_tracker.db`,
  `app_flutter/note_images/` (309 photos, 457 MB; `app_flutter` is 543 MB in all), `shared_prefs/` (settings, widget
  data, scheduled notifications), `databases/`, `files/`. The external folder
  `/sdcard/Android/data/com.lifetracker.life_tracker/files` is empty.
- **One thing can't be copied:** `flutter_secure_storage` keeps its values under a key in Android's key store, which
  dies with the install. Only `lib/core/github/github_feedback_service.dart` uses it (the in-app feedback's GitHub
  key), so that sign-in gets entered again. Its value is a secret: don't read or copy it.
- **The phone already runs v1.18.0, not v1.15.1** (the old assumption was wrong), so its data is already at schema 25
  and the old-backup restore bug (under Noticed) doesn't block this move.
- Assumed, not checked: only Ahmed uses Uplan.

## Decided
- **One app with the same ID, moved by a full copy of its private folder** (Ahmed, 2026-11-01: "Yes, one app").
  It replaced his earlier "side by side" pick, made while the photos looked impossible to copy. The uninstall comes
  only after the copy is checked on D: and a dress rehearsal in a throwaway test copy has passed.

## Also waiting on Ahmed
- **His opinion of the signing-key move, for its retro** (the retro is in `D:\projects\claude-setup\workflow\retros.md`
  with his words so far, "initial; look is ok"; add his opinion as a new line when he gives it).
- Written 2026-10-31 20:40, before that chat's fresh start:
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

## Done means (Tester)
- [ ] A ranked round-table report Ahmed has read (a page for his tablet, a copy in `docs/`).
- [ ] The widget's add-task lag fixed, or explained with numbers from a profile or release build.
- [ ] The fixes he picked built, analyze clean, all tests green, committed on `master` and pushed.
- [ ] The handover files updated; Tester hands back and offers to be archived.
(The signing-key move's own checklist is all done: `docs/superpowers/plans/2026-11-01-signing-key.md` and the history.)

## Do not touch
- The phone's Uplan: never uninstall it to get past an install error (that deletes its data). A build carrying the
  new key updates it in place with `adb install -r`.
- No key file or password in git, chat or logs. Smart App Control and other security settings stay as they are.
- `D:\backups\uplan\2026-11-01\` until Ahmed decides.

## Noticed (not fixing now)
- **v1.18.0 can't restore a backup made by an older version** (checked in the code, not by a test): schema 24 added
  `notes.isFavorite` and 25 added `notebooks.isFavorite`, both required booleans, and the generated `fromJson` throws
  on a missing key, so the whole import rolls back. Not needed for the signing-key move (the phone is on v1.18.0);
  worth a fix with a regression test before anyone restores an old backup. Found 2026-11-01.
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
