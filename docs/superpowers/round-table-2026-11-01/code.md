# Seat 3 (Code): round-table report on Uplan at d3b3165

Read only, 2026-11-01. Nothing was run or measured: every size below is arithmetic from the code or a labelled guess.
"checked" = I read the code that does it (and, where a claim rested on a library, that library's source in
`D:\dev\pub-cache` or `D:\dev\flutter`). "guess" = reasoning I did not confirm.

**Coverage.** Read: the Drift layer (`app_database.dart`, every DAO, the table files), the providers of tasks, habits,
notes, lists, planner, trackers, workout and home; Home, Today (part), Planner, note editor (part), notes grid, active
workout and set rows, `smart_order.dart` and its callers; Kotlin: the three `RemoteViewsFactory` classes,
`MidnightRefreshReceiver.kt` and `LiveDashboardService.kt` in full, `WidgetDates.kt`/`LiveCards.kt` by grep only;
Drift 2.28.2, go_router 14.8.1, Riverpod 2.6.1 and Flutter 3.44 sources for the library claims. **Not read:**
`add_task_screen`, the settings screens, codex, the Archived screen's layout, `workout_home_screen` body, program
screens, tracker screens, `notification_service` outside the chair's path, `CheckboxBlockView` beyond its save path,
the other Kotlin providers/receivers (`Uplan*WidgetProvider`, `LiveActionReceiver`, `LiveBootReceiver`,
`RestLiveUpdate`).

**Two facts that explain several findings** (both checked):
- Drift re-runs every live query on a table after ANY write to that table and re-sends the result even when nothing in
  it changed (`drift-2.28.2/lib/src/runtime/executor/stream_queries.dart:272-289` and `:346-351`: no comparison with the
  last result). So the number of live queries on `tasks`, `note_blocks`, `habit_completions` is the cost of every write.
- Riverpod 2.6.1 providers written by hand as `StreamProvider.family` are never closed (only `.autoDispose` ones are).
  The generated `@riverpod` ones are. The repo mixes both.

---

### 1. Typing a weight or reps during a workout makes the phone do a lot of hidden work
- What Ahmed notices: entering weight and reps mid-workout can feel a little laggy and warm the phone, and it will get
  worse as months of workouts pile up. (Checked in the code, not felt: the cost per key is real, how it feels is a guess.)
- Where:
  - `lib/features/workout/presentation/widgets/set_row.dart:408-411` (the field saves on every keystroke) ->
    `lib/features/workout/presentation/providers/workout_providers.dart:455-470` (`updateSet`: a personal-record check,
    a write, then a whole new workout state).
  - `lib/features/workout/data/dao/workout_dao.dart:86-96`: the record check loads EVERY past set of that exercise,
    sorts them, and keeps the first, instead of asking the database for the biggest weight.
  - `workout_providers.dart:679-688` + `lib/features/workout/presentation/widgets/exercise_accordion_card.dart:52-54`:
    each exercise card's "last time" hint watches the WHOLE workout state, so every keystroke re-reads the full history of
    every exercise card (`workout_dao.dart:162-175` loads all earlier sets and filters in Dart).
  - `lib/features/today/presentation/screens/today_screen.dart:43`, `workout_home_screen.dart:35`,
    `lib/features/home/presentation/widgets/workout_block.dart:31`, `workout_list_screen.dart:18,79` also watch the whole
    workout state, so they rebuild on every keystroke even while hidden.
- Fix: (a) hints provider: `ref.watch(activeWorkoutProvider.select((a) => a.valueOrNull?.sessionId))` so it runs once
  per workout; (b) `getBestWeightForExercise` as `MAX(weight_kg)` and `getLastSessionSets` with a latest-session
  subquery; run the record check only when the weight changed; (c) the other four screens watch only
  `.select((a) => a.valueOrNull != null)`; (d) write the typed value about 400 ms after the last keystroke and on
  blur/Finish. Regression test: a counting fake repository that fails on the old code.
- Cost: M (30-90 min).
- Gain: per keystroke today = 1 history read for the record check + one full-history read per exercise card + 4-5 screens
  rebuilt; after = 0 or 1 small read and the workout screen only. Example (guess on the numbers): 7 exercises x 100 past
  sessions x 4 sets = about 2,800 rows moved per key. (Checked in code; size is a guess.)
- Risk: low. The last typed value must still be flushed on Finish and on leaving the screen (the current per-key save
  exists for that reason, `set_row.dart:408-409`).

### 2. Photos are decoded at full size everywhere (notes grid, Home pinned note, editor, arrange mode)
- What Ahmed notices: the notes grid and a pinned note on Home can stutter or flash while scrolling, memory spikes, and
  Android may close the app sooner.
- Where:
  - `lib/features/notes/presentation/widgets/note_grid_card.dart:132-141` (a card about 190 dp wide decodes the whole
    file); `lib/features/home/presentation/widgets/pinned_note_block.dart:247-248` (every photo of the pinned note, drawn
    as 90 dp strips, on the start tab; the block builds ALL lines of the note, `:93`);
    `lib/features/notes/presentation/widgets/photo_block_view.dart:75-79`;
    `lib/features/notes/presentation/screens/note_editor_screen.dart:941-945` (arrange thumbnails, 140 dp).
    Zero `cacheWidth`/`cacheHeight`/`ResizeImage` anywhere in `lib/` (grep).
  - `lib/core/images/image_storage_service.dart:30-33`: import limits only the WIDTH to 2000 px, so a portrait photo is
    2000 x 2667 = 5.3 million pixels; no `imageQuality`, so the re-encode is at the plugin default (guess: about 100).
  - `image_storage_service.dart:19-24` + `note_grid_card.dart:133-134`: every card build asks Android for the documents
    folder again and stats the file in `build` (`File(path).existsSync()`, `:138`).
- Fix: add `cacheWidth` (about 2x the shown width in pixels: ~600 for grid cards, ~1100 for the editor and Home) to those
  four `Image.file` calls; remember the images folder path inside `ImageStorageService`; optional `imageQuality: 85` for
  new imports. Leave the full-screen viewer (`photo_view_screen.dart:55`) at full size.
- Cost: S.
- Gain: decoded size per photo falls from 12 MB (2000 x 1500) or 21 MB (2000 x 2667) to roughly 1 MB (grid card) or
  3-4 MB (editor/Home) (checked: width x height x 4 bytes). Flutter's picture cache holds 100 MiB
  (`flutter/lib/src/painting/image_cache.dart:19`), i.e. only 5-8 full-size photos, so scrolling a photo-heavy grid
  re-decodes constantly (checked). How much smoother it feels is a guess until a profile build confirms it.
- Risk: none visible; a card may look a touch softer if `cacheWidth` is set too low.

### 3. The workout screen redraws completely once every second
- What Ahmed notices: nothing directly; the phone works for a whole workout (45-90 min) and typing competes with it.
  Battery and smoothness during the gym session.
- Where: `lib/features/workout/presentation/screens/active_workout_screen.dart:57-61` (a 1-second timer calls
  `setState` on the whole screen), `:339-451` (the whole body, app bar and every visible exercise card are rebuilt);
  `_elapsed` is read in one place only, `:406`. The timer also keeps firing while the app is in the background (guess).
- Fix: move the clock into a tiny widget with its own timer (or a `ValueListenableBuilder`) so only the "time elapsed"
  text redraws; pause it when the app is in the background.
- Cost: S.
- Gain: about 3,600 full-screen rebuilds per hour become 3,600 one-label redraws (checked: the code path; gain size is a
  guess but it is the whole workout list).
- Risk: none.

### 4. Note text is saved only when you leave the line (and Back right after typing may lose a new line: guess)
- What Ahmed notices: if Android closes the app, or he swipes it away, while the cursor is still in a line, that line
  is gone. (Checked: saves happen only on blur and on Enter.) Worse, and a guess to verify in 2 minutes on the emulator:
  open a new note, type a few words, press Back twice; the line may be deleted as "empty".
- Where: `lib/features/notes/presentation/widgets/text_block_view.dart:58-65,87-98,111-120` (save on blur and on
  newline; no save while typing); `checkbox_block_view.dart:50-56,77-86,99-105` (same pattern);
  `lib/features/notes/presentation/screens/note_editor_screen.dart:315-333` (`_onLeave` reads the SAVED lines from the
  database and deletes every empty text line) called at `:345-353` when the page is popped. If that read happens before the
  blur-save lands, a line holding unsaved text looks empty and is deleted. No test covers the editor screen (grep of
  `test/`).
- Fix: save about 600 ms after the last keystroke, on app pause, and on dispose; make `_onLeave` flush pending saves (or
  unfocus and wait) before it reads; do `updateBlockContent` + `touchNote` in ONE transaction (today two commits and two
  wake-up waves: `text_block_view.dart:116-117`). Widget test: type, pop, reopen.
- Cost: M.
- Gain: no lost lines; one database commit instead of two per save. (Checked: the save path; the lost-line race is a
  guess.)
- Risk: low to medium. The line already ignores outside changes while focused (`text_block_view.dart:101-109`), so
  saving mid-typing should not clobber the caret; test it with the Arabic/RTL lines too.

### 5. Every day, week, note and list he looks at keeps running in the background until the app is closed
- What Ahmed notices: pressing Enter in a note, ticking a task or a habit gets slower the longer the app has been open
  and the more he has browsed (planner weeks, months, notebooks). A restart "fixes" it.
- Where: hand-written, never-closed `StreamProvider.family`:
  `lib/features/planner/presentation/providers/planner_providers.dart:35-50` (`habitsForDateProvider`,
  `tasksForDateProvider`: one pair per date; the week strip makes 7 pairs, `day_column.dart:38`; the month grid one per
  cell, 28-42 per month, `lib/features/shifts/presentation/widgets/shift_month_calendar.dart:280-281`);
  `lib/features/notes/presentation/providers/notes_providers.dart:39-54` (`notesForNotebookProvider`,
  `noteBlocksProvider` = one per note card ever shown, `noteByIdProvider`);
  `lib/features/home/presentation/providers/home_blocks_providers.dart:25-26` (`watchNoteProvider`);
  `lib/features/tasks/presentation/providers/lists_providers.dart:34-52` (`sectionsForListProvider`,
  `tasksForListProvider`, `labelIdsForTaskProvider`, `taskIdsForLabelProvider`). `app.dart:109-118` re-creates only the
  Home/Today providers on resume, not these.
- Fix: add `.autoDispose` to those ten families (`StreamProvider.autoDispose.family`). Nothing else changes in the
  widgets.
- Cost: S.
- Gain: with Drift's rule above, one note-line save re-runs one query PER note card ever shown and one tick re-runs one
  query per day browsed. After 300 note cards or 60 browsed days that is hundreds of hidden queries per write; after the
  fix it is only what is on screen. (Checked: the providers and Drift's rule; the milliseconds are a guess.)
- Risk: low. A screen opened for the first time shows its "loading" value for one frame (planner day detail already shows
  a spinner then); cards under an open grid stay alive because the grid still watches them.

### 6. Ticking a habit re-reads every completion ever recorded (the planner re-reads them 8 or more times)
- What Ahmed notices: a small hitch when ticking a habit, growing each month; the Planner dots lag behind.
- Where:
  - `lib/features/habits/data/dao/habits_dao.dart:142-174` (`watchHabitsWithCompletions`: joins habits with ALL their
    completions of all time; one row per completion with the habit's columns repeated) used by
    `habits_repository.dart:41-64`, which builds a set of all dates per habit for each tick.
  - `habits_repository.dart:73-91` (`watchHabitsForDate`): triggered by `habits_dao.dart:132-134` (`select(habitCompletions)
    .watch()` - loads the whole completions table only to ignore it), then `getAllHabits()` and one `isCompletedOn` query
    PER HABIT. One of these streams exists per planner day (finding 5), so a tick runs this 8+ times.
  - Same N+1 in `lib/core/notifications/live_dashboard_service.dart:167-169`.
- Fix: (a) the streak/done-today stream only joins completions from the last ~400 days (a streak above 400 would read
  "400+": Ahmed's call); (b) one query for a date: habits LEFT JOIN completions on (habit_id, date = ?), watching both
  tables; (c) no `select(...).watch()` as a bare trigger.
- Cost: M.
- Gain: per tick, rows moved fall from (habits x days kept) to (habits x 400 days at most) for the list and (habits) for
  each planner day. 10 habits over a year = 3,650 rows per tick today (guess: I do not know how many habits he has).
  (Checked: the code.)
- Risk: low; there are habit tests to extend. Streak over the window needs his decision.

### 7. "Start workout" reads the whole history of that workout day first (new today, smart order)
- What Ahmed notices: a short wait after tapping Start when the smart-order switch is on, growing with the months of
  history. Today probably unnoticeable (guess).
- Where: `lib/features/workout/data/dao/workout_dao.dart:184-212` (`recentExerciseOrders`: no `LIMIT`; it loads every
  filled set of every past workout of this plan day, joined with its session, then the Dart loop stops after 3 workouts,
  `:205`); called from `workout_providers.dart:354-403` before the session is created. The ordering itself
  (`smart_order.dart`) is sound: checked, at most 14 exercises it tries about 3.2 million steps (a few tens of ms), and
  at the usual 6-9 exercises it is instant; it runs once, not per rebuild.
- Fix: first select the ids of the last 3 sessions of that plan day that have a filled set (subquery with
  `ORDER BY created_at DESC, id DESC LIMIT 3`), then load only their sets. Keep the existing behaviour tests and add one
  with 5 past workouts proving only the newest 3 count.
- Cost: S.
- Gain: start-up work stays constant instead of growing. (Checked: the code; size is a guess.)
- Risk: low; keep the "skipped workouts with nothing filled in do not count" rule from the comment at `:177-183`.

### 8. Home does too much on every task change
- What Ahmed notices: after ticking a task, Home redraws everything at once (and Today/Planner redraw behind it).
- Where: `lib/features/home/presentation/screens/home_screen.dart:53-65`: one big `build` that watches seven providers,
  including `allTasksProvider` (`:60-61`), which loads and sorts EVERY non-archived task, finished ones included, and is
  needed only by the "label" and "done" blocks (`:153-154`, `:169-173`). It is watched even when neither block is on
  Home. Five more separate queries on the same table feed urgent / today / captured / this week.
- Fix: move the `allTasksProvider` watch inside the `label` and `done` cases (two lines, the provider is
  auto-disposed); later, make each block its own small consumer so only the block whose data changed redraws, and feed
  the task blocks from one "open tasks" stream.
- Cost: S (gating) / M (splitting).
- Gain: when no Label or Done block is on Home, one whole-table load, sort and rebuild per task write disappears.
  Finished tasks that were never archived make that list grow forever. (Checked: code; his layout unknown.)
- Risk: none for the gating.

### 9. The database has no indexes and no write-ahead log
- What Ahmed notices: nothing yet; each month of use makes every list query a little slower and deleting a note a little
  slower.
- Where: `lib/core/database/app_database.dart:46-85` and every table file: the only constraint is a unique key on
  `work_shifts.date` (grep: no `@TableIndex`, no `CREATE INDEX`). Foreign keys are switched on (`:352-357`), so deleting
  a note, habit or workout checks the child tables row by row without an index (e.g. `tasks.source_note_block_id`
  cascades from `note_blocks`, `tasks_table.dart:89`). `app_database.dart:426-431` opens the file without
  `PRAGMA journal_mode=WAL`, so each write is a full rollback-journal commit.
- Fix: v26 migration adding indexes on `note_blocks(note_id, order_index)`, `habit_completions(habit_id, date)`,
  `tasks(due_date)`, `tasks(list_id)`, `tasks(source_note_block_id)`, `workout_sets(session_id)`,
  `workout_sets(exercise_name)`, `workout_sessions(program_session_id, created_at)`, `tracker_logs(tracker_id)`,
  `tracker_log_values(log_id)`, `task_labels(task_id)`, `notes(notebook_id, updated_at)`; and open with
  `NativeDatabase.createInBackground(file, setup: (db) => db.execute('PRAGMA journal_mode=WAL;'))`.
- Cost: S.
- Gain: guess: small today (tables are a few thousand rows), protects growth; WAL makes each small write cheaper
  (checked: neither is set; speed-up is a guess and probably small on the Flip 6's fast storage).
- Risk: indexes: low (additive). WAL: the database becomes three files (`life_tracker.db`, `-wal`, `-shm`). A raw copy
  of the `.db` alone can then miss the newest data. The 2026-11-01 move copied the whole folder, which is safe, but write
  that rule into the device skill before anyone copies a single file.

### 10. Notes grid: one live database query per card, and cards fill in after they appear
- What Ahmed notices: scrolling a notebook, cards first show as bare colour tiles and then pop into photos and text;
  saving a line in an open note wakes every card that has ever been shown (finding 5).
- Where: `lib/features/notes/presentation/screens/notebook_detail_screen.dart:350-358` (each card watches
  `noteBlocksProvider(note.id)` = all blocks of that note, only to take the first photo, the first line and a count;
  `lib/features/notes/domain/note_preview.dart:27-51`), grid at `:91-108`. No index on `note_blocks.note_id` (finding 9).
- Fix: one preview query per notebook (first photo or the chosen cover, first non-empty line cut to ~120 characters, photo
  count; grouped by note) as one stream the grid watches; cards become plain widgets.
- Cost: M.
- Gain: the grid gets data in its first frame (no pop-in); a keystroke-save no longer re-queries every card; far fewer
  rows copied across (whole text of every block of every visible note today). (Checked: code; effect size a guess.)
- Risk: low to medium: keep `notePreview()` semantics (cover wins, dividers skipped) and compare the two in a test.

### 11. Trackers: a query per tracker per refresh, and Today may show stale ticks (guess)
- What Ahmed notices: Trackers and Today recompute slowly with many trackers; a checklist ticked on the Trackers screen
  may not tick on Today until the app is reopened (guess, 2 minutes to check on the emulator).
- Where: `lib/features/trackers/data/repositories/trackers_repository.dart:21-60` and `:71-104`: driven by
  `watchAllTrackers()`, which only reads the `custom_trackers` table, then 2-3 queries PER tracker (items, today's logs,
  values of each log). Log writes do not re-emit them; the writers call `ref.invalidate(trackersWithProgressProvider)`
  by hand (`trackers_providers.dart:107,135,161,177,193`) but never for `checklistTrackersForTodayProvider`, which is only
  refreshed on app resume (`app.dart:116`) while `_TrackerInlineCard` assumes a tab revisit syncs it
  (`today_screen.dart:382-387`).
- Fix: quick patch: also invalidate `checklistTrackersForTodayProvider` in the log writers. Proper fix: one Drift
  `customSelect` that reads all four tracker tables (`readsFrom: {...}`) so the stream updates itself and the N+1
  disappears.
- Cost: S (patch) / M (proper).
- Gain: correctness plus fewer queries. (Checked: the code path; the stale display is a guess.)
- Risk: low.

### 12. Tabs he visited keep working while hidden
- What Ahmed notices: nothing directly; every database change makes Home, Today, Planner, Lists, Workout redo their
  work even when he is on another tab or inside the active workout.
- Where: `lib/core/router/app_router.dart:87` (`StatefulShellRoute.indexedStack`) with go_router 14.8.1: a tab is built on
  first visit (`preload` is false, `route.dart:1024`) and then kept in an `IndexedStack` inside `Offstage` +
  `TickerMode(enabled: false)` (`route.dart:1516-1538`); an offstage child still gets built and laid out when its
  providers change.
- Fix: do NOT drop the stack (tab switches would reload and flash). Make the hidden tabs cheap instead: findings 1, 5, 6
  and 8 remove most of it; then, if still wanted, give each tab root a small wrapper that skips heavy rebuild work while
  `TickerMode.of(context)` is false and refreshes on becoming visible.
- Cost: M.
- Gain: guess; mostly the sum of findings 1, 5, 6, 8. (Checked: the structure.)
- Risk: medium for the wrapper (a tab could come back stale); none for the other four.

### 13. Live dashboard and widget sync do more than needed
- What Ahmed notices: nothing visible; some extra work at every launch, resume and widget-button press.
- Where: `android/app/src/main/kotlin/com/lifetracker/life_tracker/LiveDashboardService.kt:76-85` (rebuilds the whole
  notification once per changed key; `syncCards` writes three watched keys one after the other,
  `lib/core/notifications/live_dashboard_service.dart:172-176`, so up to three rebuilds per sync);
  `live_dashboard_service.dart:148-149` loads every task including finished ones and filters in Dart, and `:167-169`
  asks the database once per habit (finding 6). Called at `app.dart:101-102,163-164` and
  `lib/core/notifications/live_background_callback.dart:62`.
- Fix: coalesce the Kotlin listener (post a refresh about 150 ms later, cancel if another key arrives); in Dart, one
  query for "habit ids done today" and open tasks only.
- Cost: S.
- Gain: small. Checked and fine: the three `RemoteViewsFactory` classes parse their JSON once per data change, not per
  row (`AgendaRemoteViewsFactory.kt:24-47`, `MonthRemoteViewsFactory.kt:33-63`,
  `CombinedTasksRemoteViewsFactory.kt:42-93`); `MidnightRefreshReceiver.kt` books one inexact alarm a day. The
  foreground service is a deliberate always-on design.
- Risk: low.

### 14. Tidy list (small, but each can cause a bug later)
- What Ahmed notices: nothing now.
- Where / Fix (all checked):
  - `pubspec.yaml:51` lists `timezone` but nothing in `lib/` or `test/` imports it (it comes in through
    `flutter_local_notifications` anyway): remove the line.
  - Two providers with the same job and name: `allNotesProvider` in `home_blocks_providers.dart:29` and
    `notes_providers.dart:57`; `watchNoteProvider` (`home_blocks_providers.dart:25`) = `noteByIdProvider`
    (`notes_providers.dart:53`). Keep one of each.
  - `day_time_grid.dart:48` creates a `ScrollController` inside `build()` and never disposes it (a new one on every
    redraw); make the widget stateful. Dialog helpers create controllers they never dispose:
    `settings_screen.dart:352-353`, `list_detail_screen.dart:360`, `rotations_editor_screen.dart:66`,
    `program_detail_screen.dart:74` (found by counting, each worth a glance).
  - `workout_providers.dart:328-335` uses try/catch around `firstWhere` as an "is it there?" test, run per exercise card
    on each rebuild (`active_workout_screen.dart:427-428`): use `firstWhereOrNull`.
  - Multi-step moves are not atomic, so a kill half-way leaves a half-archived state:
    `archive_service.dart:87-91,142-146,246-250,288-293` (wrap each in `transaction`).
  - Habit toggle is read-then-write with no unique key on (habit_id, date): two quick taps, or a tap racing the
    notification tick (`live_background_callback.dart:40-48`), can store the day twice
    (`habits_repository.dart:118-132`, `habit_completions_table.dart:15-25`). Add the unique index with finding 9 after
    a one-off de-duplication.
  - Quiet failures (16 `catch (_)`): mostly intended ("never break the app"), but none writes to the existing crash log;
    log them in debug/profile builds so a broken widget sync is visible in Settings > Diagnostics.
- Cost: S in total, if done as one batch.
- Gain: fewer surprises; no speed change.
- Risk: none to low.

---

## Ideas
1. **A small thumbnail next to every photo** (about 480 px, made once at import or on first show; a one-time background
   pass for the existing 309 photos). Lists, the grid, Home and arrange mode use the thumbnail; only the full-screen viewer
   opens the original. Makes the notes grid light with or without the `cacheWidth` fix.
2. **A slow-frame meter in Settings > Diagnostics** (frame timings above 32 ms, with the screen name, kept in the
   existing log). It lets the chair measure the real jank on his phone instead of trusting the guesses above.
3. **One "open tasks" stream** feeding Home, Today, Planner dots, widgets and the live dashboard, with urgent / today /
   captured / week derived in code: one query per task write instead of about eight, and the finished-task history leaves
   the hot path.
4. **A "tidy up" button** (Settings): archive finished tasks older than 30 days, empty Recently deleted early. Keeps the
   Home "Done" block and every task list short without a per-list switch.
5. **"Hidden tabs sleep"**: a tiny shared wrapper so Planner, Today and Home skip work while another tab is showing and
   refresh when shown (finding 12, done once for all tabs).

## Top 5
1. Photos: add `cacheWidth` in the four `Image.file` spots and remember the images folder (S): 10x less picture memory in the grid and on Home.
2. Workout typing: narrow the "last time" hint provider, ask the database for MAX instead of loading history, save after a pause (M): removes the per-key history reads.
3. Workout clock in its own widget (S): stops 3,600 full-screen rebuilds an hour.
4. `.autoDispose` on the ten never-closed family streams (S): writes stop getting slower the more he browses.
5. Notes: save while typing in one transaction and flush before leaving (M): no lost lines; check the Back-after-typing case on the emulator first.
