# Round table, Seat 1: Product and flows (2026-11-01, commit d3b3165)

How this was done: read-only. Read the brief, the 4 overview sheets, 4 full-size screenshots (first-launch, today,
tracker-routine, workout), `docs/_Master_Plan.md`, `feedback/app.md`, the router, the shell, the drawer and about 20
targeted greps/slices of the screen files. Not read in depth: the note editor, most of Settings, Create program, the
rotations editor. The screenshots are cold-start routes, not tap paths, so every tap count below comes from the code.
"checked" = I read the code or the screenshot that shows it. "guess" = my reading of how it feels.
Out of scope per the brief and not repeated: the widget "+" restart, start-up work, the quick-add sheet's keyboard band.

---

### 1. Overdue tasks pile up and there is no "move to tomorrow"
- What Ahmed notices: the same overdue tasks sit at the top of Home ("Urgent") and Today ("Overdue 8") every morning.
  The only ways out are to finish them, archive them (swipe left), or open each one, tap Edit, change the date, save
  (about 5 taps per task). Nothing says "not today, push it to tomorrow".
- Where: `lib/features/tasks/presentation/widgets/task_tile.dart:36-54` (swipe works one way only: `endToStart` =
  archive; tap opens the detail sheet, long-press opens Edit), `task_detail_sheet.dart:209-215` (its only labelled
  button is Edit). A grep for reschedule/snooze/postpone in tasks, today and home finds only the internal reminder
  re-booking (`rescheduleAll`), no user action. Screens: `flip-a16-light-home.png`, `flip-a16-light-today.png`.
- Fix: (a) swipe right on a task = "Move to tomorrow", with the usual Undo snackbar; (b) three small chips in the
  detail sheet: Today / Tomorrow / Next week; (c) a "Move all to today" button on the Overdue header. Moving a task must
  re-book its reminders (the add screen already does this: `add_task_screen.dart:361-373`).
- Cost: M
- Gain: the most repeated chore in the app drops from about 5 taps to 1 swipe per task (checked that no such action
  exists; how often he has overdue tasks is a guess, but the demo data and his own use of "Urgent" suggest daily).
- Risk: low (a moved task's reminders and the widgets must refresh; one regression test for each).

### 2. Two add-task experiences, and the screens he uses most have no "+"
- What Ahmed notices: from the widget "+" he gets a light sheet (list chips, name, date, time, priority). Inside the
  app the "+" opens the long full-screen form instead. Today and Planner have no "+" at all; adding a task on a given
  day in the Planner is a long-press on that day. A task quick-added with a time never gets a reminder (the sheet has no
  reminder choice and no "more options" button), which he may not expect (guess).
- Where: `lib/core/router/app_router.dart:232-254` (`/quick-add` exists only for the widget link; `/tasks/add` is the
  big form, 866 lines), `home_screen.dart:331` (FAB pushes `/tasks/add`), `today_screen.dart` and `planner_screen.dart`
  (no FloatingActionButton; checked by grep over all screens), `planner/presentation/widgets/week_strip.dart:183-184`
  and `day_time_grid.dart:100-107` (long-press to add), `quick_add_task_screen.dart` (no "reminder" anywhere).
  Screens: `flip-a16-light-quick-add.png` vs `flip-a16-light-task-add.png`, `flip-a16-light-planner.png`.
- Fix: make the in-app "+" open the same sheet as a bottom sheet (no new screen), add a "More" button that carries
  what is typed into the full form, add a "Remind me" chip, and put the same "+" on Today and Planner (pre-filled with
  the selected day). Fix the sheet's keyboard band first (the chair has it).
- Cost: M
- Gain: the most frequent action gets one look and fewer taps in every tab (checked how it works today; the saving is
  an estimate: about 2 taps and one full-screen switch per task).
- Risk: low to medium (the sheet's code calls `SystemNavigator.pop()` today, which would close the app if reused
  inside it: `quick_add_task_screen.dart:63`).

### 3. Nothing warns him that the phone holds the only copy of his data
- What Ahmed notices: nothing, until a phone is lost. The in-app backup is a JSON file without the 309 photos
  (457 MB) and without Settings; an older backup cannot be restored (v1.18.0 rejects it); and no screen ever says "last
  backup: 40 days ago".
- Where: `docs/_Current_Task.md` ("Noticed": backup leaves out photos and Settings; old-backup restore bug; both
  checked by the Tester chat, not re-read by me); a grep for lastBackup, lastExport or a backup reminder in `lib/`
  finds nothing (checked); Settings > Data (`flip-a16-light-settings.png`).
- Fix: step 1 (S): Settings > Data shows "Last backup: never / 12 days ago", and Home shows one gentle card after 14
  days; fix the old-backup restore with a test that fails on the old code. Step 2 (L): a zip backup with the photos
  folder and Settings.
- Cost: S for step 1, L for step 2
- Gain: protects everything he has written and photographed; it is the only finding here that could lose data (checked
  for the missing nudge; the data-loss scenario is by nature a guess).
- Risk: low for step 1; step 2 needs storage and time for 457 MB and must not be run on the main thread.

### 4. He can search notes and the archive, but not tasks, habits or lists
- What Ahmed notices: finding "that task about the car" means opening list after list, or the Archive. Notes have a
  search that looks inside notes; the Archive searches what is inside archived things; tasks have nothing.
- Where: a case-insensitive grep for "search" across tasks, home, today, habits, trackers and planner finds no match
  (only the workout exercise picker, `exercise_picker_screen.dart`); search exists in `notes_overview_screen.dart` and
  `archived_screen.dart`. Screens: `flip-a16-light-lists.png` (no search field), `flip-a16-light-notes.png`.
- Fix: a search icon in the Lists tab (and the "All tasks" view) that finds open, finished and archived tasks by title,
  description and list, with the due date and list shown in each hit.
- Cost: M
- Gain: "find something old" goes from browsing to 2 taps and a word (checked that it is missing; frequency is a guess).
- Risk: none (read-only feature; use the same text match the Archive already uses).

### 5. The default front door hides the best screens, and the menu looks like an account page
- What Ahmed notices: a new install opens on Home, whose default blocks are Urgent, Due today, Captured, This week,
  Workout, Notes: no habits. The screen that shows habits + due tasks + workout + trackers in one place (Today) sits
  in a side menu. The bottom bar has 3 tabs and grows a 4th (the screen you came to from the menu) that disappears
  again. Notes, Work schedule, Archive, Codex and Settings are all behind a round "account" icon. Home and Today then
  show the same overdue tasks under two names.
- Where: `lib/core/settings/app_settings.dart:124-132` (default tabs Home, Lists, Planner), `home_block_type.dart:74-81`
  (default blocks), `shell_scaffold.dart:99-105` (the appended 4th tab) and `:119-123` (the icon, tooltip "Menu"),
  `app_drawer.dart:59-63` ("My Account, Sign in coming soon"). The decisions log has nothing on this (grep: no hits).
  Settings already lets him choose the tabs and the start tab (`settings_screen.dart:255-290`), so his own phone may be
  set up differently; this mostly hits new users and the Play testers. Screens: `flip-a16-light-home.png` vs
  `flip-a16-light-today.png`.
- Fix (a choice for Ahmed, 3 options): 1. keep the layout, change only the new-install defaults: Habits block on Home,
  start on Today (S); 2. fold Today into Home (one front page, M); 3. replace the profile icon with a plain menu icon and
  drop "My Account" (S, can go with option 1).
- Cost: S (options 1 and 3), M (option 2)
- Gain: first minute for a new user gets simpler (guess); no gain for Ahmed's own tab set if he already tuned it.
- Risk: low; option 2 removes a screen he may use.

### 6. Editing and adding are hidden behind long-press, and every screen starts it differently
- What Ahmed notices: tap a task and a sheet opens (Edit is inside it); long-press opens the editor directly. A habit
  can only be edited or deleted by long-press (there is no menu on the row). Adding a task on a day = long-press the
  day. A note opens straight in its editor. The Codex needs a "Hidden gems" filter, and 6 of the first 11 entries on
  its screen carry the hidden-gem bulb.
- Where: `task_tile.dart:53-54`, `habits/presentation/widgets/habit_tile.dart` (onLongPress),
  `app_router.dart:264-270` (comment: the habit edit route is "passed from HabitTile's long-press"),
  `add_habit_screen.dart:181` (Delete habit lives inside the edit screen's menu), `week_strip.dart:183`.
  Screens: `flip-a16-light-habits.png`, `flip-a16-light-codex.png`.
- Fix: give habits the same tap-for-details sheet tasks have (with Edit and the streak), and put a visible "Add task"
  row at the end of each Planner day. Keep long-press as the shortcut.
- Cost: M
- Gain: no more "how did I do that again" (checked the gestures; the effect on Ahmed is a guess: he built much of this
  and may know it all, but friends testing for Play will not).
- Risk: low.

### 7. In the gym a confirm dialog asks before deleting a set; everywhere else it is swipe plus Undo
- What Ahmed notices: swipe a task, habit, tracker, list or note away and an "archived" bar with Undo appears. In an
  active workout, deleting a set opens "Delete Set? This cannot be undone." and a Cancel/Delete choice, with chalky
  hands. Tracker entries say "permanently removed", while templates and archived things wait 30 days.
- Where: `active_workout_screen.dart:312-326` (also `:125-159` Finish Workout, `:238-253` Discard Workout; those two
  are fine), `trackers/presentation/screens/tracker_detail_screen.dart:311`; the Undo pattern: SnackBarAction in 8 files
  (task_tile, habit_tile, trackers_screen, notebook_detail, notes_overview, note_editor, list_detail, archived).
- Fix: delete a set and delete a tracker entry the same way as the rest: remove at once, show "Set deleted" with Undo
  for a few seconds.
- Cost: S
- Gain: one tap fewer per mistake mid-workout, one habit across the app (checked the dialogs; the gym tap saving is a
  guess).
- Risk: low (Undo must put the set back in the same position; the smart-order work is in the same screen, so wait for
  the Uplan chat to say the gym files are free).

### 8. The menu still makes promises the app already keeps (G6)
- What Ahmed notices: the side menu lists "Export data: Coming in Phase 2" and "Cloud sync: Coming in Phase 2" as greyed
  tiles, although Export and Import already work in Settings > Data. The theme choice is in the menu ("Auto") and in
  Settings ("System") with different words.
- Where: `app_drawer.dart:256-268` (the two tiles), `:105` ("Auto"); Settings screenshot `flip-a16-light-settings.png`.
  Already listed as G6 in `docs/_Master_Plan.md` ("Open now").
- Fix: delete both tiles and "Sign in coming soon" (see 5), say "System" in both places; keep one theme control (the
  one in Settings), or leave the menu one and rename the Settings one.
- Cost: S
- Gain: trust and a cleaner menu; matters before Play testers see it (checked).
- Risk: none.

### 9. Dates are written in three different ways
- What Ahmed notices: "Sunday, Nov 1" on Today and "Today, Nov 1" in the Planner (month first), but "Thu, 29 Oct" in
  Workout, "24 Oct" on note cards, "16 Nov" on tasks, and "Thursday, 29 October 2026" in tracker history (day first,
  full words). Month names are typed out by hand, in English only, in 7 files.
- Where: `shell_scaffold.dart:77-87` (hand-built month-first date), the same hand-written month list in
  `note_grid_card.dart`, `planner_screen.dart`, `week_strip.dart`, `add_task_screen.dart`, `quick_add_task_screen.dart`,
  `task_tile.dart`; plus `DateFormat('EEE, d MMM')` (4 uses) and `DateFormat('EEEE, d MMMM yyyy')` (1). Screens:
  `flip-a16-light-today.png`, `flip-a16-light-workout.png`, `flip-a16-light-tracker-routine.png`.
- Fix: one small helper (Today / Yesterday / Tomorrow, then "Thu 29 Oct", the year only when it is not this year) and
  use it in those 7 files plus the DateFormat spots, with a unit test for the words.
- Cost: S to M (many small edits, one test)
- Gain: calmer reading; no more thinking "which date is 6/11" (checked in the screenshots; the English-only month
  names matter only if the phone language changes, which is a guess).
- Risk: low (strings in tests and widget text that match the old format need updating).

### 10. Trackers are a second place to tick daily things, four taps away
- What Ahmed notices: a daily-routine tracker is much like a habit list, but to tick it he goes Trackers (a menu
  screen) > tracker > "Log entry" > tick > save. The tracker card cannot be ticked, Home has no Trackers block (only
  Today has a section for them), and the widget does not show them.
- Where: `trackers/presentation/widgets/tracker_progress_card.dart:55` (the card only has onTap), `home_screen.dart:91-177`
  (no tracker case in the block switch), `today_screen.dart:192` (Trackers section), `log_entry_screen.dart`.
- Fix: let a checklist tracker's items be ticked on its card (and on the Today section) and save at once; later, think
  about whether checklist trackers and habits should be one thing (the master plan already lists "merge habits and
  tasks" as later).
- Cost: M
- Gain: a daily check-in goes from about 4 taps to 1 (checked the path; whether he uses a checklist tracker daily is
  a guess).
- Risk: low to medium (today's log entry rules: one entry per day).

### 11. The home-screen task list cannot tick a task off
- What Ahmed notices: the widget shows tasks and has "+", but a row only opens the app (or nothing special); he cannot
  complete a task from the home screen.
- Where: `android/app/src/main/kotlin/com/lifetracker/life_tracker/CombinedTasksRemoteViewsFactory.kt:113,122`
  (`setOnClickFillInIntent(..., Intent())` is empty), `UplanWidgetProvider.kt:46,54` (open and "+" only). I read only
  these two files; the agenda and month widgets were not checked.
- Fix: a tick circle on each widget row that completes the task through the same background callback the "+" refresh
  already uses, then redraws the list.
- Cost: L (Kotlin, background database access, race with the open app)
- Gain: the first thing you do with a to-do list from the home screen (guess how much he would use it).
- Risk: medium (two writers on one database; needs a real-device try).

---

## Ideas
1. **Launcher shortcuts** (long-press the app icon): New task, New note, Start workout. Checked: none exist (only 3
   widget XML files in `res/xml`, no "shortcut" in the manifest). Not the parked "Assistant shortcuts". S.
2. **Share to Uplan**: from any app (a photo, a link, a copied line) into Unfiled notes or as a task. Checked: the
   manifest has no SEND intent. M.
3. **Overdue stack that is calm**: Today shows the 3 oldest overdue tasks and "5 more", with "Move all to today"
   (goes with finding 1). Home already has an "items shown" cap, Today does not. S.
4. **A "New note" button next to "+" in the widget** (or a second small widget) so a photo note is one tap from the
   home screen. S to M.
5. **Week start from the phone's region by default** instead of Monday (the setting exists, off by default:
   `app_settings.dart:63`); a guess that matters for friends in the Gulf more than for Ahmed. S.

## Top 5 (gain for cost)
1. Backup nudge: "Last backup: N days ago" + the old-backup restore fix, photos in the backup later (finding 3, S then L).
2. Overdue: swipe right / chips "Move to tomorrow", "Move all to today" (finding 1, M).
3. One add-task sheet inside the app, a "+" on Today and Planner, a reminder chip (finding 2, M).
4. Delete-with-Undo for gym sets and tracker entries instead of dialogs (finding 7, S).
5. Task search across open, finished and archived tasks (finding 4, M).
(Next in line: menu cleanup G6 with finding 5's option 3 (S); one date helper (finding 9).)

## Checked and fine (leave alone)
- Swipe-to-archive with Undo is the same on tasks, habits, trackers, lists, notebooks and notes; Recently deleted keeps
  things 30 days. Archive has its own search.
- Workout: "Train Push" is one tap from the Workout tab and a block on Home; finish, discard and the summary sheet
  are clear.
- A habit is one tap to tick; habits have a weekly target already (`habits_table.dart:25`), so "habits are daily only"
  is not a problem.
- Planner and shifts are connected (shift handling in `day_column.dart`, `day_time_grid.dart`, `day_detail_view.dart`).

## Caveats (not findings)
- `flip-a16-light-tracker-routine.png` shows no tracker name in the title and a "00:00" on each entry. The title is
  blank because the shot was opened by route with no `extra` data (`app_router.dart:289-304` reads the name and the
  items from `state.extra`), so it is an artefact of how the screenshot was taken, not what he sees when he taps in. The
  same dependency is a small code-seat fragility: after Android restores the app, the tracker screens may open
  blank (guess; not tried). The "00:00" is probably the logged time-of-day of made-up entries (guess, code not read).
- Everything about taps is from reading code; none of it was tried on a device.
