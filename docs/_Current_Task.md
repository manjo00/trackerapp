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
