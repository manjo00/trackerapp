# Gym clean-up: Targets and Programs out, quick starts and the editor kept

**Date:** 2026-11-01 · **Status:** waiting for Ahmed's yes · **Chat:** the Uplan chat · **Path:** a short design
with its steps (it touches about 20 files, but needs no database change and deletes none of his data).

## What Ahmed asked (his words, 2026-11-01)
- "this feature is developer mode only" (the smart order), "delete the target system its gonna be replaced with the
  analysis", "delete programs instead saved exercise like it is right now".
- Then: "keep quick starts so i see recent once and click them fast", "make sure the editor and exercise (push pull
  full body) stays", "later about the program it will be replaced with scheduling tool to add the exercises in the
  schedule".

## The Workout tab after the change
Top to bottom:
1. The resume banner, when a workout is running (as now).
2. **Quick starts:** his 3 most recently done saved workouts; one tap starts one.
3. **My Workouts:** every saved workout, as now: tap to start, ✎ to edit, + New, hold to delete.
4. **Recent Sessions**, as now.

Gone: the Targets/Program switch, the weekly muscle scoreboard and its targets editor, the "Set up your workout plan
/ Create Program" card, the program card and its "This week" strip.

## Elsewhere
- **Home's workout card:** the same quick starts, or "Workout in progress" while one runs. No "Set up a program".
- **Today:** "Workout in progress" while one runs; no suggested program session (the scheduling tool brings
  "today's workout" back later).
- **Smart order:** its switch in the workout editor shows only in developer mode (About in the side menu, tapped 7
  times), and Start uses it only when developer mode is on and the switch is on. With developer mode off, workouts
  keep their saved order; the switch keeps its setting for when developer mode is back on.
- **Help:** the in-app manual (Codex) and the coach tips stop mentioning Targets and Programs (25 and 17 places to
  check).

## Quick starts: which workouts
His saved workouts, ordered by when he last did each, newest first; the first 3. A saved workout never done yet comes
after the done ones, in My Workouts' order. A quick start starts the workout exactly like tapping it in My Workouts,
so history and the smart order keep working. (Today's quick starts are built-in Push/Pull templates with library
exercises he doesn't use, and the workouts they start are linked to nothing.)

## What stays underneath (his data)
- No database change, and nothing of his data deleted. My Workouts are stored as sessions of a hidden program
  (`ProgramRepository.kMyWorkoutsContainer`), so the program tables, the workout editor
  (`program_session_editor_screen.dart`) and its route `/workout/programs/:id/session/:sid` stay. Workouts logged
  from old programs keep their history.
- His weekly muscle targets stay in the database, unused, and the backup still carries them.
- The old empty "Push" program (two empty sessions; not his "Push" saved workout) simply stops showing anywhere.

## Code that goes
The screens `create_program_screen.dart`, `program_detail_screen.dart`, `muscle_targets_editor_screen.dart`; the
widgets `weekly_scoreboard_card.dart` and `week_attendance_strip.dart`; `quick_start_templates.dart` and
`startQuickTemplate`; `program_template_data.dart` (the Push/Pull/Legs and Upper/Lower templates) and its test; the
routes `/workout/programs/create`, `/workout/programs/:id` and the targets editor's; the providers `allPrograms`,
`programTemplates`, `programById`, `activeProgram`, `todaysSuggestedSession`, `WorkoutTargetsMode` and the
scoreboard's. The repository keeps what My Workouts use. The code checker gives the exact list once the screens are
gone.

## Steps
1. Quick starts from recent workouts: a query for each saved workout's last date and a pure ordering rule, test
   first.
2. The smart order behind developer mode, test first (Start keeps the saved order when developer mode is off).
3. The Workout tab, Home's card and Today rebuilt as above; the program and targets screens, routes and providers
   removed; the code checker clean.
4. The manual and the coach tips updated.
5. All tests, the code checker, a debug build with the fingerprint check, then a try: on an emulator (one at a time,
   shared with the Tester) for the Workout tab, Home's card and a quick start, and on his phone, with his OK, for the
   screens only (starting a workout there adds an entry to his history).

Size (a guess): about 1–2 hours of Claude's work, then about 10 minutes of tests and a build; about 300k tokens; no
helpers.

## Not in this change
- The scheduling tool that replaces programs (later, its own design).
- The analysis dashboard that replaces Targets (the next big piece, its own design).
- The Snapchat summary sticker (its own small design, after a check of Snap's current rules).
