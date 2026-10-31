# Current Task: none in progress
**Date:** 2026-10-31 · **Branch:** master

## State
No task is in progress. The build tools are back on this PC since 2026-10-31 (details in START HERE in `CLAUDE.md`):
Flutter 3.44.9, Java 21 and the Android SDK, all in `D:\dev`. On them the code checker is clean, all 303 tests pass,
and debug and release builds work (the release build ran while Smart App Control was in evaluation mode).

## Suggested next step (needs Ahmed)
1. **Decide how to cross the signing-key change** before releasing. The laptop's debug key is lost, so v1.18.0 can't
   install over the Uplan on the phone. Likely path: check that the app's backup (Settings > Export data) carries
   everything, note photos included; export it and keep the file off the phone; uninstall; install v1.18.0; restore.
   Then make a real signing key and back it up off C: (master plan, "Before a Play Store launch").
   The real key is also one of the Play basics (Ahmed's Play decision, 2026-10-31). Made now, it could probably go to
   Google Play later as the app's own key, so the phone wouldn't need a second reinstall (from memory, not checked).
2. Release v1.18.0 (it carries v1.16.0 and v1.17.0 too) with the release ritual in
   `.claude/skills/uplan-device-release/SKILL.md`. A release build needs Smart App Control to stay in evaluation mode.
3. G4's owed check: time the inexact-alarm path on the Z Flip 6 (recipe in `docs/superpowers/STATUS-2026-07-28.md`, G4 section).
4. **Heavy testing, then Google Play** (Ahmed, 2026-10-31; master plan, "Before a Play Store launch"). First shape with
   him what the testing covers (superpowers' brainstorming). Testing on the phone needs step 1 first.

## Waiting on Ahmed (written 2026-10-31 20:40, before this chat's fresh start)
- **"Start on the signing-key step now?"** (asked 2026-10-31 in the next-step box; buttons "Yes, start it" / "Not now").
  "Yes, start it" means step 1. First check the guess in step 1 (Play App Signing), then shape the step with him
  (brainstorming) and ask one go-ahead that names everything it does: export a backup, uninstall, install, restore,
  make the real key.
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
- [ ] Written when a task starts.

## Do not touch
- Written when a task starts.

## Noticed (not fixing now)
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
