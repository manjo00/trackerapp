# Uplan: Master Plan

The whole project on one page, phase by phase: ✅ done · ⬜ to do · ⏸ parked.
Tick an item the moment it is done, and add a line to `docs/_Task_History.md`. Details live in the linked
files; this page only says what is done and what is left.

Rebuilt on 2026-10-27 from the git log, the public releases, `docs/superpowers/STATUS-2026-07-28.md`,
`docs/superpowers/NOTES-ROADMAP.md`, the brand study and `feedback/app.md`. The plan files in
`docs/superpowers/plans/` never had their own check boxes ticked, so this page is the record of what is done.

## ← We are here (2026-10-31)
- **Code:** v1.18.0+27, last changed 2026-09-30. **Last public release:** v1.15.1 (2026-08-20).
  v1.16.0, v1.17.0 and v1.18.0 are built and committed but not released.
- **This PC:** the build tools are back since 2026-10-31, in `D:\dev` (Flutter 3.44.9, Java 21, the Android SDK).
  What each change to the PC did and how to undo it: `docs/_Undo_Table.md`.
- **Next, in order:**
  1. ✅ Reinstall Flutter and the Android tools (2026-10-31, with Ahmed's OK; the laptop's Flutter 3.44 line).
  2. ⬜ Decide how to cross the signing-key change: the laptop's debug key is lost, so v1.18.0 can't install over the
     phone's Uplan. Likely: check the in-app backup carries everything (photos too), export it, uninstall, install,
     restore; and make a real signing key, backed up off C: (see "Before a Play Store launch").
  3. ⬜ Release v1.18.0 (it carries 1.16 and 1.17 too). Smart App Control blocks release builds whenever it is on.
  4. ⬜ G4's owed check: time the inexact-alarm path on the Z Flip 6 (recipe in STATUS, G4 section).
  5. ⬜ Heavy testing, then Google Play (Ahmed, 2026-10-31; see "Before a Play Store launch"). What the testing covers
     is still to be shaped with him. Testing on the phone needs step 2 first: no new build reaches it before then.

## Phase 1: MVP on Android ✅
- ✅ Habits: create, mark done daily, streaks (2026-05-27)
- ✅ Tasks: create, complete, due dates, priorities (2026-05-27)
- ✅ Today view: today's habits and due tasks together (2026-05-27)

## Phase 1.5 (from the original roadmap)
- ✅ Gym tracking: programs, sets, reps, weight, history, rest timer, weekly muscle targets, My Workouts (2026-05-27 → 2026-08-14)
- ⬜ Medications as their own feature (schedule, reminders, intake log). Not built; a tracker or a task reminder covers it today.
- ✅ Planner: day, week and month views, then time blocking (2026-05-27 → 2026-07-06)

## Built beyond the original roadmap ✅
- ✅ Work shifts: month calendar, shift-aware dates, editable rotations (2026-06-28 → 06-30)
- ✅ Reminders that really fire on Samsung, then the live dashboard notification and rest-timer Now Bar (2026-06-30 → 07-03)
- ✅ Home-screen widgets and quick add (2026-06-30)
- ✅ Lists, sections and labels; Home blocks v1, v2 and v2.1 (2026-07-04 → 08-03)
- ✅ Archive v1 and v2 (Recently deleted for 30 days, search inside) (2026-07-06, 08-21)
- ✅ Notes: block editor, photo grid, rich text phase 1, templates, collapsible sections, drag engine, search, star, sort, move, duplicate, cover photo (2026-07-10 → 09-29)
- ✅ The Codex manual, guided tour, What's new (2026-08-04 → 08-21)
- ✅ Diagnostics, crash capture, in-app updates, JSON backup, feedback sync to GitHub (2026-06-28 → 07-04)
- ✅ G2 de-clinicalised text, G4 Play-safe alarms, G5 live cards stay current (2026-08-28 → 09-30)

## Open now ⬜
- ⬜ Release v1.16 to v1.18 (see "We are here")
- ⬜ G4 owed: the inexact-alarm timing on the Z Flip 6
- ⬜ G6: remove or reword the stale "Coming in Phase 2" drawer tiles (NOTES-ROADMAP, G6)
- ⬜ Feedback from the app (`feedback/app.md`): 3 of its 4 items are done (today marker, auto-archive, photo crop), but the file is not ticked. The 4th, "a note design closer to Samsung's or Apple's", is largely answered by the notes redesign; word-level rich text (E) is the piece left.

## Notes roadmap (details in `docs/superpowers/NOTES-ROADMAP.md`)
- ✅ A1 to A8, B1, B2, B5 (shipped 2026-08-01 → 09-29)
- ⬜ A9 side-by-side blocks (L) · B3 bulk select (M) · B4 tags or colours (M) · B6 notes in Recently deleted (M)
- ⬜ C1 outline (M) · C2 sticky heading (M) · C3 collapse persistence (S; A7 may already cover it, check first)
- ⬜ D1 gallery block (L) · D2 photo captions (S) · D3 photo markup (S)
- ⬜ E word-level rich text (L) · F templates phase 2 · G3 coach and arrange-mode animation polish (S)

## Before a Play Store launch ⬜ (brand study, "Blocking work before any of this goes live")
**The order (Ahmed, 2026-10-31):** Uplan stays the main focus but goes to Google Play only after heavy testing; the
dock (New Desktop) goes on sale first, on Steam. His goal is side income. The plan and the checked Play facts:
`business/ideas.md` in `manjo00/claude-setup` (`D:\projects\claude-setup` on the PC), "Ideas and next steps" item 4.
- ⬜ Heavy testing first (what it covers is still to be shaped with Ahmed)
- ⬜ Privacy policy and the Play data-safety form
- ⬜ A real signing keystore (builds are debug-signed today)
- ⬜ Play's closed test for a new personal account: at least 12 testers, opted in for 14 days in a row (friends can be the testers)
- ✅ G4 alarms made Play-safe (2026-09-30) · ✅ G2 copy pass (2026-09-29)
- ⬜ Then the first Pro features, so it can earn: themes and icons, then insights (the study's order goes on: smart lists → rota photo to shifts (OCR) → calendar sync)

## Phase 2 and later ⬜
- ⬜ Cloud sync (Supabase) and accounts, multi-device
- ⬜ iOS (same codebase) · subtasks · recurring tasks (merge habits and tasks) · a performance pass
- ⬜ Phase 3: stylus note-taking with PDF annotation

## Parked ⏸
- ⏸ G1 Z Flip cover-screen compact layout (parked by Ahmed 2026-08-04; the widget route is ruled out)
- ⏸ Tracker templates · gym program auto-import · Assistant shortcuts (brand study: parked or minor)
- ⏸ Out of scope for now: web and desktop builds, sharing and social, AI suggestions, theming beyond light and dark, wearables

## Links
Designs `docs/superpowers/specs/` (15) · plans `docs/superpowers/plans/` (10) · status log and gotchas
`docs/superpowers/STATUS-2026-07-28.md` · notes roadmap `docs/superpowers/NOTES-ROADMAP.md` · brand study
`docs/superpowers/2026-08-25-brand-pricing-and-market.md` · feedback `feedback/app.md` · decisions `docs/_Decisions_Log.md`
