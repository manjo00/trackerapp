# Current Task: none in progress
**Date:** 2026-10-27 · **Branch:** master

## State
No task is in progress. The last app work was G4, Play-safe exact alarms (2026-09-30, commit ff9e928).
On 2026-10-27 the handover files were added: this file, `docs/_Master_Plan.md`, the rebuilt
`docs/_Task_History.md`, `docs/_Decisions_Log.md`, `AGENTS.md`, the start-up step in `.claude/settings.json`
and the code map in `graphify-out/`.

## Suggested next step (each needs Ahmed's OK)
1. Reinstall Flutter, the Android SDK (with adb) and a JDK on the new PC, preferably on D: so a future C: wipe can't take them. About 10 GB.
2. Release v1.18.0 (it carries v1.16.0 and v1.17.0 too) with the release ritual in `.claude/skills/uplan-device-release/SKILL.md`. A release build needs Smart App Control to stay in evaluation mode; debug builds always work.
3. G4's owed check: time the inexact-alarm path on the Z Flip 6 (recipe in `docs/superpowers/STATUS-2026-07-28.md`, G4 section).

## Done means
- [ ] Written when a task starts.

## Do not touch
- Written when a task starts.

## Noticed (not fixing now)
- The 10 plan files in `docs/superpowers/plans/` never had their check boxes ticked, although the work shipped. The master plan is the record of what is done.
- `feedback/app.md` still shows all 4 items unticked. 3 are done (today marker in v1.9.1; per-list auto-archive and photo crop in v1.10.0); the 4th (a Samsung- or Apple-style note design) is largely answered by the notes redesign.
- STATUS refers to "Working Style #11" (general, non-clinical examples in user-facing text), but this repo's `CLAUDE.md` lists only 8 Working Style rules. STATUS also says the durable project history lived in a CLAUDE.md in OneDrive, outside the repo. No such file was found in OneDrive on this PC (2026-10-27), so rules 9 and up may be lost. The decisions log records #11.
- STATUS's "IN-FLIGHT" section (2026-07-28) is out of date: the editor redesign and the photo grid shipped in v1.10.0, and the August shift entry is long past.
- `README.md` is still Flutter's default text.
- GitHub shows this repo as public, while the device skill calls it "the private source repo". Worth checking which one Ahmed wants.
