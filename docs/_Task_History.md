# Task History

Append-only log of finished tasks, newest at the bottom. One line per task:
`YYYY-MM-DD | task | files: ... | commit | notes`. Never edit an old line; a correction is a new line.

Lines up to 2026-09-30 were rebuilt on 2026-10-27 from the git log (245 saves), the public releases in
`manjo00/uplan-releases` and `docs/superpowers/STATUS-2026-07-28.md`. They group the saves into one line per
feature or release, and "files" names the feature area rather than every file.

---

2026-05-26 | Project set up: Flutter app (first named life_tracker), database layer, repository, providers, streak tests | files: lib/core | f535985, fd26780 | -
2026-05-27 | MVP: habits, tasks and the Today tab, planner week strip, settings (theme, tab visibility), swipe-to-delete, edit, overdue section | files: lib/features/habits, tasks, today, planner, settings | d0cb5a6 … 681e1c9 | -
2026-05-27 | Reminders: a daily reminder, then per-item notifications for habits, tasks and trackers (schema v4) | files: lib/core notifications | 53cf10b, 2a6b2af, cbd18d4, 0b64aa8 | exact alarms needed on Samsung
2026-05-27 | Universal trackers: templates, checklists, session logs | files: lib/features/trackers | 0171f5c | -
2026-05-27 | Workout tab and program-based workouts (schema v5) | files: lib/features/workout | deba7c2, 4df86cc, 3f89516, 5dd4d99 | -
2026-06-08 | Workout phases A–E: rest timer bar, previous-set column, accordion day, grouping, finish summary | files: lib/features/workout | bca26e3 … ea369f3 | -
2026-06-08 | Navigation redesign (Inbox tab, 3-tab default, drawer) and daily-checklist trackers on Today | files: lib/core, lib/features/today | a16504d, d116907, 32f777c | -
2026-06-28 | Work shift schedule: month calendar, shift-aware task dates, shifts in the planner (schema v6) | files: lib/features/shifts, planner | e7fb54f … 1a3e793 | -
2026-06-28 | JSON backup export/import, foreign keys on | files: lib/features/settings | c1f68f5, c7cff9a | -
2026-06-30 | Home-screen widgets (Today glance, Upcoming agenda, month calendar with tasks) and the quick-add sheet | files: android widgets, lib/features/home | ecf9035 … 9b6c516 | the see-through window crashed on One UI, was reverted, then restored
2026-06-30 | Editable shift rotations (schema v7) and rotation labels | files: lib/features/shifts | c2b9900, 28b1584, 79f0b61 | -
2026-06-30 | Workout weekly muscle targets, scoreboard, shift-aware targets (schema v9) | files: lib/features/workout | decbac2 … 1f5a1f0 | -
2026-06-30 | Scheduled reminders fire reliably, via android_alarm_manager_plus | files: lib/core notifications, android | e8b7a02 … e071376 | several failed attempts first
2026-07-03 | Live dashboard notification: slideshow cards, complete and snooze actions, rest-timer Now Bar | files: lib/features/live, android | bd9ced7 … 6c7e763 | -
2026-07-03 | Field-test tools: diagnostics screen, crash capture, in-app update check against GitHub Releases | files: lib/features/settings | d4c01b4, 2ad9b06, 12e93f9 | first public releases v1.1.0 and v1.1.1 (2026-07-03)
2026-07-04 | Task organisation core: lists, sections, labels, Home and Lists tabs (schema v11); feedback lists pushed to GitHub | files: lib/features/tasks, home | d81f1a7 … 3c2592a | v1.2.0; spec 2026-07-03-task-organization-core
2026-07-05 | Home block engine: reorderable blocks, Edit Home, startup tab | files: lib/features/home | 47f225d … eca9ca3 | v1.4.0; spec 2026-07-04-home-block-engine
2026-07-06 | Time blocking: optional task time ranges, planner day grid (schema v12) | files: lib/features/planner, tasks | 1729fc8 … f230671 | v1.5.0; spec 2026-07-06-time-blocking
2026-07-06 | Archive system (schema v13) | files: lib/features/archive | 272fd17, 061f4e0 | v1.6.0; spec 2026-07-06-archive-system
2026-07-10 | Notes v1: notebooks and a block editor with text, checkbox and photo blocks (schema v14); Notes block on Home | files: lib/features/notes | 3cc6ba0 … 56123bf | v1.7.0, v1.7.1; spec 2026-07-10-notes-system-phase1
2026-07-11 | Note lines starting with a time ("@time") create linked tasks | files: lib/features/notes | 66e2279, 4bdf202 | v1.8.0 beta; plan 2026-07-11-note-time-tokens
2026-07-22 | Todoist-style date parser (WhenParser) and two-way note↔task sync, which ended the respawn bug | files: lib/core/text, lib/features/notes | 7388324 … 4d87777 | v1.9.0 beta
2026-07-28 | Today stays obvious on month calendars; PR #1 merged | files: lib/features/shifts | e53a255, 0766927 | v1.9.1; from feedback/app.md
2026-07-29 | Notes photo grid, open editor redesign, per-list auto-archive of done tasks, photo crop | files: lib/features/notes, tasks | 9f18a9a … ebee13a | v1.10.0; two feedback items closed
2026-07-31 | Notes rich text phase 1 (headings, highlight, bold, italic, divider), templates, insert anywhere | files: lib/features/notes | d76b23b … 23dca10 | v1.11.0, v1.11.1
2026-08-02 | Tame long notes: collapsible sections, capped photos, arrange mode with a custom drag engine (schema v19–v20) | files: lib/features/notes | 2358808 … 333e3b5 | v1.12.0
2026-08-03 | Home v2 (blocks in the database, task detail card, live pinned note) and v2.1 (control pack, new blocks, Done block) | files: lib/features/home | 96f6cda … 5b611b3 | v1.13.0, v1.13.5
2026-08-04 | The Codex (in-app manual) and My Workouts templates (schema v22) | files: lib/features/codex, workout | efff4c9 … e18f952 | v1.14.0
2026-08-14 | My Workouts fixes | files: lib/features/workout | 5920a45, 9422b29, 0f57768 | v1.14.1
2026-08-21 | Guided tour (coach marks), What's new shelf, lines can leave a section by dragging down | files: lib/features/coach, codex, notes | fb0561f … 8c53a58 | v1.15.0, v1.15.1: the last public release (2026-08-20)
2026-08-21 | Z Flip cover screen checked: the widget route is ruled out, the compact layout is parked | files: docs/superpowers/specs | aa9d4d8, c371834 | spec 2026-08-04-flip-cover-screen-feasibility
2026-08-21 | Archive v2: Recently deleted (30 days), archive from every tile, search inside | files: lib/features/archive | 64b5632 | built, not released
2026-08-25 | Widgets and the live notification stay on today's date; today shown as a ring | files: android widgets | dff1fd7, d0fa04b | v1.16.0, built, not released
2026-08-28 | Live-notification cards decide their own day (G5) and search inside notes (A6) | files: lib/features/live, notes | c3547dd | v1.17.0, built, not released
2026-09-01 | Brand, pricing and market study, also published as the Artifact "Uplan Goes Public" | files: docs/superpowers/2026-08-25-brand-pricing-and-market.md | 9e9a2f3, 3a2140f | -
2026-09-29 | Notes quick wins: star, sort, move, duplicate, cover photo, hold menu; star and sort for notebooks (schema v24–v25) | files: lib/features/notes | 504ff93, 9f9474a | v1.18.0, built, not released
2026-09-29 | Found that Smart App Control blocks release builds (gen_snapshot.exe) | files: docs/superpowers/STATUS-2026-07-28.md | b846279 | debug builds still work
2026-09-29 | De-clinicalised the user-facing text (G2) | files: lib/features/codex, coach | fda7ebd | -
2026-09-30 | Play-safe exact alarms with an inexact fallback (G4) | files: lib/core notifications, android manifest | b4cabcd, ff9e928 | timing the inexact path on the Flip is still owed
2026-10-27 | Device skill pointed at D:\projects\trackerapp after the Windows reinstall | files: .claude/skills/uplan-device-release/SKILL.md | 46c29b0 | -
2026-10-27 | Handover files: START HERE, master plan, rebuilt history, current task, decisions log, AGENTS.md, a start-up step that shows the last 5 history lines, and a free code map (graphify) | files: CLAUDE.md, AGENTS.md, docs/_*.md, .claude/settings.json, .graphifyignore, graphify-out/GRAPH_REPORT.md | 473dffd, 05d0b2a, then the map commit | map: 281 code files, 0 tokens, docs left out; refresh with `python -m graphify update .`
2026-10-31 | START HERE: a line on the code map's auto-refresh (graphify's git hooks, turned on 2026-10-30 in aef2725) | files: CLAUDE.md, docs/_Current_Task.md, docs/_Task_History.md | (this commit) | first fresh chat on the auto-load kit: START HERE, the current task and the last 5 history lines all loaded by themselves
