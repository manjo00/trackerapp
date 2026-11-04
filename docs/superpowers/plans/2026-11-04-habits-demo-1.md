# Habits Demo 1 ("tick and see") Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans (Ahmed's rule: the chat builds it itself, no helpers).
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ahmed can add his own habits (tick or count, every day, chosen days or N a week, spare days, a part of the
day, a cue) and tick them in one tap on a Look A Habits screen, Today and Home, with a forgiving streak and a
strength %.

**Architecture:** One schema bump (27) adds every column the whole rebuild needs. The rules live as pure functions in
`lib/features/habits/domain/`; the repository hands them a habit plus its last 400 days of entries; Riverpod providers
combine habits, entries and "today" into one list of `HabitDayView`s that every screen reads.

**Tech Stack:** Flutter 3.44.9 (`D:\dev\flutter`), Drift 2.22, Riverpod 2.6 (+ generator), freezed 2.5, go_router.

**Spec:** `docs/superpowers/specs/2026-11-04-habits-rebuild-design.md` (approved by Ahmed, 2026-11-04: "Yes, plan
demo 1"). Read it with this plan.

## Global Constraints
- Work in `D:\projects\trackerapp-tester` on `tester/speed`; merge into master only after telling the Uplan chat; the
  phone gets a build only from master under the install rule (`docs/_Decisions_Log.md`, 2026-11-04).
- Schema 26 → 27, habit tables only (OK from the Uplan chat, 2026-11-04 19:30; it takes 28 after this merge if it
  needs one). Nothing under `lib/features/workout/` changes.
- Shared files, each announced to the Uplan chat right before its edit: `lib/core/database/app_database.dart`,
  `lib/core/router/app_router.dart`, `lib/core/backup/backup_service.dart`, `lib/app.dart`,
  `lib/features/today/presentation/screens/today_screen.dart`,
  `lib/features/home/presentation/widgets/habits_block.dart`, `test/core/database/workout_log_migration_test.dart`.
- No new packages. Stay on Flutter 3.44. Android CLI commands get `--no-metrics`.
- Day start is the constant `kHabitDayStartMinutes = 240` (04:00) in demo 1; the setting and the night-shift rule
  come in demo 3. Weeks follow the existing `settings.weekStartsSunday`.
- Copy: no strike-through, misses never red, no "streak lost". Labels exactly as written below.
- His data only ever as copies; his exact gym dates never go into the repo (it is public).
- Every new test is seen failing before its code; `flutter analyze` clean and the whole suite green before the merge.
- Commands (Git Bash, in the worktree): `F="/d/dev/flutter/bin/flutter"`, `D="/d/dev/flutter/bin/dart"`.

## Review Focus
1. **A tick between 00:00 and 03:59** counts for the day before (Task 4: "a tick at 01:30 counts for the day before").
2. **The app left open across 04:00** moves to the new day without a restart (Task 4: "the day flips at 04:00").
3. **A habit created mid-week** ("3 a week", created Friday) shows no misses before its first day (Task 3:
   "nothing before the first day counts").
4. **A schedule edited later** (every day → chosen days) re-scores the past without errors (Task 3: "a changed
   schedule re-scores the past").
5. **Typed count amounts**: 0 removes the day's entry, a blank or negative entry changes nothing, above 999 is
   refused (Task 4: "typed amounts").

---

### Task 0: Prepare the worktree
- [x] **Step 1:** In `D:\projects\trackerapp-tester`: `git merge --ff-only master` (tester/speed is 15 behind and 0
  ahead). Expected: fast-forward to master's head.
- [x] **Step 2:** `$D run build_runner build --delete-conflicting-outputs`. Expected: "Built with build_runner".
- [x] **Step 3:** Baseline: `$F test` and `$F analyze`; write the pass count in the history line later. Expected:
  all pass, "No issues found".
- [x] **Step 4:** `$F test tool/dump_schema_test.dart` → `test/core/database/fixtures/schema_v26.sql`. Commit:
  `test: schema v26 fixture for the habits migration`.

### Task 1: Schema 27
**Files:** Modify `lib/features/habits/data/tables/habits_table.dart`,
`lib/features/habits/data/tables/habit_completions_table.dart`, `lib/core/database/app_database.dart` (shared);
Create `lib/features/habits/data/tables/habit_pauses_table.dart`; Test
`test/core/database/habits_v27_migration_test.dart`; Modify `test/core/database/workout_log_migration_test.dart:41-44`
(shared: "lands on version 26" → `db.schemaVersion`).

**Interfaces — Produces:**
- `habits` new columns (Drift getter = JSON key): `kind` text default 'tick' · `goal` int 1 · `unit` text null ·
  `step` int 1 · `icon` text 'check_circle' · `color` int 0 · `schedule` text 'daily' · `weekdayMask` int 127 ·
  `perWeek` int null · `shiftMask` int 7 · `sparesPerWeek` int 0 · `section` text 'any' · `cue` text null (max 80) ·
  `sortOrder` int 0 · `autoSource` text null.
- `habit_completions` new columns: `value` int 1 · `status` text 'done' · `note` text null · `createdAt` dateTime null;
  `@TableIndex(name: 'habit_completions_habit_date', columns: {#habitId, #date}, unique: true)`.
- New table `HabitPauses`: `id` autoIncrement, `startDate` text, `endDate` text (inclusive), `createdAt` dateTime.
- `schemaVersion => 27`; migration step `if (from < 27)`: add every column above (`m.addColumn`), `m.createTable(
  habitPauses)`, `UPDATE habits SET schedule = 'per_week', per_week = target_per_week WHERE target_per_week < 7`,
  `DELETE FROM habit_completions WHERE id NOT IN (SELECT MIN(id) FROM habit_completions GROUP BY habit_id, date)`, then
  create the unique index (`m.createIndex` on the generated index; if Drift doesn't generate one, `CREATE UNIQUE INDEX
  IF NOT EXISTS habit_completions_habit_date ON habit_completions (habit_id, date)`).

- [x] **Step 1: Write the failing test** (fixture `schema_v26.sql` + rows, the `workout_log_migration_test.dart` way:
  habit 1 'H' target 7 archived; habit 2 'Run' target 3; ticks for habit 2: id 10 and 11 on '2026-11-02', id 12 on
  '2026-11-03'; one task and one workout session):
  - `the upgrade lands on version 27` → `user_version == 27`
  - `habits keep their rows and get the defaults` → H: kind 'tick', schedule 'daily', weekdayMask 127,
    sparesPerWeek 0, section 'any', archivedAt unchanged
  - `a target below 7 becomes N a week` → Run: schedule 'per_week', perWeek 3
  - `duplicate ticks shrink to one and the index refuses a new one` → habit 2 rows are ids {10, 12}; inserting
    (2, '2026-11-03') again throws `SqliteException`
  - `habit_pauses exists and is empty`
  - `other tables keep their rows` → the task and the workout session are unchanged
- [x] **Step 2:** `$F test test/core/database/habits_v27_migration_test.dart` → FAIL (version 26, missing columns).
- [x] **Step 3:** Tell the Uplan chat "editing app_database.dart and your migration test's version line now"; implement
  the columns, table, index and migration step; update the workout test's version check; rerun build_runner.
- [x] **Step 4:** The test file and `test/core/database/` pass.
- [x] **Step 4b: His real database, as a copy.** Copy `D:\backups\uplan\2026-11-04-kilos\after\life_tracker.db` (his
  newest, 18:45) into the scratchpad, never the backup itself, and run `$F test tool/migrate_copy_test.dart
  --dart-define=UPLAN_DB=<the copy>`. Expected: user_version 27, `PRAGMA integrity_check` ok, every table's row count
  the same as before, "H" still archived. (The Uplan chat read that copy: 1 habit, 0 ticks, 0 duplicate pairs, so
  the de-duplication removes nothing of his; Step 1's test still covers it.)
- [x] **Step 5:** Commit `feat(habits): schema 27 for the habits rebuild`.

### Task 2: Habit model, DAO and repository
**Files:** Create `lib/features/habits/domain/habit_types.dart`; Modify `lib/features/habits/data/models/habit_model.dart`,
`lib/features/habits/data/dao/habits_dao.dart`, `lib/features/habits/data/repositories/habits_repository.dart`;
Test `test/features/habits/data/habits_repository_test.dart`.

**Interfaces — Produces:**
- `habit_types.dart`: `enum HabitKind { tick, count }`, `enum HabitSchedule { daily, weekdays, perWeek, shifts }`,
  `enum HabitSection { wake, any, day, sleep }`, `enum EntryStatus { done, rest, sick }`, each with `String get db`
  ('tick', 'count'; 'daily', 'weekdays', 'per_week', 'shifts'; 'wake', 'any', 'day', 'sleep'; 'done', 'rest', 'sick')
  and `static X fromDb(String? s)` (unknown or null → the first value; for sections → `any`). Weekday mask: bit
  `DateTime.weekday - 1` (Mon 1 … Sun 64, all 127). `class HabitEntry { final int value; final EntryStatus status; }`,
  `class PauseRange { final String start, end; bool contains(String day); }`, `class HabitHistory { final Map<String,
  HabitEntry> entries; final List<PauseRange> pauses; }`.
- `HabitModel` (freezed) fields: `id`, `name`, `createdAt`, `kind` (tick), `goal` (1), `unit`, `step` (1), `icon`
  ('check_circle'), `color` (0), `schedule` (daily), `weekdayMask` (127), `perWeek`, `shiftMask` (7), `sparesPerWeek`
  (0), `section` (any), `cue`, `sortOrder` (0), `autoSource`, `reminderEnabled` (false), `reminderTime`.
  `targetPerWeek` stays until Task 7 removes it with the old screen; `saveHabit` writes `target_per_week = perWeek ??
  7`.
- **What goes when:** each old piece leaves in the task that removes its last user, so every task compiles: Task 2
  removes `toggleCompletion` and `watchAllCompletions`; Task 6 removes `watchHabitsWithStatus`, `calculateStreak`,
  `watchHabitsWithCompletions`, `habitsWithStatusProvider`, `HabitTile`, `StreakBadge` and `streak_logic_test.dart`;
  Task 7 removes `addHabit`, `updateHabit`, `AddHabit`, `UpdateHabit`, `targetPerWeek` and `add_habit_screen.dart`.
- `HabitsDao`: `Stream<List<Habit>> watchActiveHabits()` (archivedAt and deletedAt null; order sortOrder, id) ·
  `Stream<List<HabitCompletion>> watchCompletionsSince(String fromDay)` · `Stream<List<HabitCompletion>>
  watchCompletionsOn(String day)` · `Stream<List<HabitPause>> watchPauses()` · `Future<void> toggleTick(int habitId,
  String day)` (one transaction: delete if present, else insert value 1 status 'done') · `Future<void> setValue(int
  habitId, String day, int value)` (≤ 0 deletes; else upsert on the unique key). Keep `getAllHabits`, `isCompletedOn`,
  `getHabit`, the archive/delete/purge methods. Remove `watchHabitsWithCompletions` and `watchAllCompletions`.
- `HabitsRepository`: `Stream<List<HabitModel>> watchActiveHabits()` · `Stream<Map<int, HabitHistory>>
  watchHistorySince(String fromDay)` (entries grouped per habit; every history gets the same pause list) ·
  `Future<int> saveHabit(HabitModel h)` (id 0 → insert and return the new id; else update every field) ·
  `toggleTick`, `setValue` (pass-through) · `Stream<List<HabitWithStatus>> watchHabitsForDate(String day)` (the
  Planner's: active habits plus that day's ticks, two queries) · `getAllHabits()` · `deleteHabit`.

- [x] **Step 1: Write the failing tests** (in-memory `AppDatabase.forTesting`):
  - `saveHabit stores every field and reads it back` (a count habit: goal 8, unit 'glasses', step 1, weekdays mask 21,
    section sleep, cue 'After dinner', spares 2, icon 'water_drop', color 5)
  - `toggleTick once leaves one row (value 1, done); twice leaves none`
  - `setValue upserts one row per day; 0 removes it`
  - `watchHabitsForDate marks only that day's ticks`
  - `watchActiveHabits leaves out archived and deleted habits, ordered by sortOrder then id`
- [x] **Step 2:** Run → FAIL (missing methods/fields).
- [x] **Step 3:** Implement; regenerate. The Planner's provider keeps its name; `ToggleCompletion.toggle(int habitId,
  {String? date})` keeps its signature and calls `toggleTick` with `date ?? today`.
- [x] **Step 4:** Run → PASS; `$F analyze` clean.
- [x] **Step 5:** Commit `feat(habits): model, DAO and repository for schema 27`.

### Task 3: The rules (pure Dart)
**Files:** Create `lib/features/habits/domain/habit_day.dart`, `habit_rules.dart`, `habit_stats.dart`; Tests
`test/features/habits/domain/habit_day_test.dart`, `habit_rules_test.dart`, `habit_stats_test.dart`.

**Interfaces — Produces:**
- `habit_day.dart`: `const int kHabitDayStartMinutes = 240;` · `String dayKey(DateTime d)` ('yyyy-MM-dd' of the
  calendar date) · `String habitDayOf(DateTime moment, {int dayStartMinutes = kHabitDayStartMinutes})` · `String
  addDays(String day, int n)` (UTC arithmetic) · `String weekStartOf(String day, {required bool weekStartsSunday})`.
- `habit_rules.dart`: `enum DayState { beforeStart, notDue, open, away, rest, sick, kept, partial, missed, pending }` ·
  `bool isScheduledOn(HabitModel h, String day)` (daily, perWeek, shifts → true in demo 1; weekdays → mask bit) ·
  `DayState dayState(HabitModel h, HabitHistory hist, String day, {required String today, required bool
  weekStartsSunday})`. The first day is `habitDayOf(h.createdAt)`.
- `habit_stats.dart`: `enum StreakUnit { days, weeks }` · `class HabitSummary { DayState today; int todayValue; int
  streak; StreakUnit streakUnit; int strengthPercent; int weekCount; int sparesLeft; }` · `HabitSummary
  summarize(HabitModel h, HabitHistory hist, {required String today, required bool weekStartsSunday})` and its parts
  `currentStreak`, `strengthPercent`, `weekCount`, `sparesLeft` (same parameters).

**The order `dayState` checks in** (the tests pin it): before the first day → beforeStart · a rest/sick entry →
rest/sick · a done entry with (tick, or value ≥ goal) → kept · inside a pause → away · perWeek with the week's kept
days before `day` ≥ perWeek → notDue · not scheduled → notDue · a done count entry under its goal → partial · no entry:
`day == today` → pending; perWeek → open; else → missed.

**Streak (days):** walk back from today to the first day: kept +1; today pending or partial, open, notDue, away, rest,
sick → skip; a past partial or missed → use a spare if that week has one left (the day doesn't count), else stop.
**Streak (weeks, perWeek):** the current week +1 only once reached, else skip it; earlier weeks +1 when reached, skip
when every day was away, else stop. Kept weeks = kept days in the week ≥ perWeek.

**Strength:** start at 0 on the first day (or 400 days back, whichever is later; older days no longer show). Days:
each due day up to yesterday, plus today only when kept: `s += (v − s) / 20`, v kept 1, missed 0, partial
`min(1, value/goal)`; every other state changes nothing. Weeks (perWeek): each finished week, plus the current week
once reached: `s += (v − s) / 6`, `v = min(1, keptDays / perWeek)`; an all-away week changes nothing. Shown as
`(s * 100).round()`. **sparesLeft:** sparesPerWeek minus this week's past partial or missed days (floor 0); 0 for
perWeek. **weekCount:** kept days this week up to today.

- [x] **Step 1: Write the failing tests** (helper habits created 2026-10-01 10:00; `today` '2026-11-04', a Wednesday;
  Sunday weeks unless said):
  - habit day: 2026-11-05 02:30 → '2026-11-04'; 03:59 → '2026-11-04'; 04:00 → '2026-11-05'; `dayStartMinutes: 0` at
    00:00 → '2026-11-05'; `weekStartOf('2026-11-04')` → '2026-11-01' (Sunday), '2026-11-02' (Monday);
    `addDays('2026-12-31', 1)` → '2027-01-01'.
  - rules: daily past without entry → missed, today → pending, before the first day → beforeStart; weekdays mask 21
    (Mon, Wed, Fri): Tue 3 Nov → notDue, Wed 4 Nov → pending; perWeek 2 with ticks Sun 1 and Tue 3 Nov: Wed 4 Nov →
    notDue, Mon 2 Nov → kept, and with only Tue ticked Mon 2 Nov → open; count goal 8: today 5 → partial, 8 → kept;
    rest entry → rest; a pause 31 Oct–1 Nov → away, a tick inside it → kept.
  - streak: daily kept 28 Oct–3 Nov, today pending → 7; today kept → 8; spares 1 with one miss Wed 28 Oct among kept
    25 Oct–3 Nov → 9 and `sparesLeft` 1; kept 25 Oct–3 Nov but missed Tue 27 and Thu 29 Oct, 1 spare → 6 (the spare
    covers the 29th, the 27th stops it); a rest day and a pause are skipped; perWeek 2 with weeks reached, reached, current 1 → 2; current reached → 3.
  - strength: 10 kept days from the first day, today pending → 40; 20 kept then a miss → 61; 20 kept then a count of
    4 of 8 → 63; a rest day changes nothing; a spare-covered miss lowers it like a miss (61).
  - **nothing before the first day counts** (Review Focus 3): perWeek 3 created Fri 30 Oct with one tick Sat 31 Oct →
    every day before 30 Oct is beforeStart, no day is missed, streak 0 and `strengthPercent` 6 on 4 Nov (one finished
    week at 1 of 3).
  - **a changed schedule re-scores the past** (Review Focus 4): the same history read as daily and then as weekdays
    mask 21 gives different streaks and throws nothing.
  - **the gym fixture:** perWeek 2, created 2026-06-28 10:00, ticks on the first c days of each Sunday week from 28
    Jun for c = 5, 1, 2, 1, 0, 2, 4, 1, 2, 0, 3, 2, 2, 2, 0, 0, 0, 1 and 1 tick on Sun 1 Nov: on '2026-11-04' strength
    45, streak 0, weekCount 1; on '2026-10-04' strength 76.
- [x] **Step 2:** Run the three files → FAIL. Delete `streak_logic_test.dart`.
- [x] **Step 3:** Implement the three files to the rules above.
- [x] **Step 4:** Run → PASS.
- [x] **Step 5:** Commit `feat(habits): the rules for days, streaks and strength`.

### Task 4: Providers
**Files:** Rewrite `lib/features/habits/presentation/providers/habits_providers.dart`; Create
`lib/features/habits/presentation/models/habit_day_view.dart`; Modify `lib/app.dart` (shared, one added line); Test
`test/features/habits/presentation/habits_providers_test.dart`.

**Interfaces — Produces:**
- `class HabitDayView { final HabitModel habit; final HabitHistory history; final HabitSummary summary; }`.
- `final habitClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);` (tests override it).
- `habitTodayProvider` (Notifier<String>): `habitDayOf(clock())`; a Timer to the next 04:00 invalidates it.
- `activeHabitsProvider` (Stream<List<HabitModel>>) · `habitHistoryProvider` (Stream<Map<int, HabitHistory>>, since
  `addDays(today, -400)`) · `habitDayViewsProvider` (`Provider<AsyncValue<List<HabitDayView>>>`, sorted by section
  wake, any, day, sleep, then sortOrder, then id).
- `habitActionsProvider` → `HabitActions`: `tick(int habitId)` (today) · `addAmount(int habitId, int amount)` ·
  `setAmount(int habitId, String day, String typed)` (blank or negative → nothing; 0 → removes; above 999 → refused,
  returns false) · `save(HabitModel h)` → id. `ToggleCompletion` stays for the Planner. `app.dart` gains
  `ref.invalidate(habitTodayProvider)` beside its old `habitsWithStatusProvider` line (Task 6 drops that one).

- [x] **Step 1: Write the failing tests** (ProviderContainer, in-memory database, the clock overridden):
  - `a tick moves today from pending to kept`
  - `a tick at 01:30 counts for the day before` (clock 2026-11-05 01:30 → the row's date is '2026-11-04')
  - `the day flips at 04:00 without a restart` (clock 03:59 → '2026-11-04'; clock 04:01 plus an invalidate →
    '2026-11-05')
  - `+ adds the step and turns kept at the goal` (goal 8, step 1, from 7)
  - `typed amounts` ('' and '-2' change nothing; '0' removes; '1000' is refused; '12' stores 12)
- [x] **Step 2:** Run → FAIL.
- [x] **Step 3:** Implement; tell the Uplan chat before the one-line `app.dart` edit.
- [x] **Step 4:** Run → PASS; analyze clean.
- [x] **Step 5:** Commit `feat(habits): providers for the day views`.

### Task 5: Look A pieces
**Files:** Create in `lib/features/habits/presentation/widgets/`: `habit_palette.dart`, `habit_row.dart`,
`habits_week_strip.dart`, `habit_sections.dart`; Tests `test/features/habits/presentation/habit_row_test.dart`,
`habit_sections_test.dart`.

**Interfaces — Produces:**
- `habit_palette.dart`: 8 hues `[252, 205, 168, 130, 45, 20, 330, 290]`; `HabitColors.of(BuildContext, int index)` →
  `({Color container, Color onContainer, Color solid})` from HSL (light 72%/90%, 58%/27%, 52%/44%; dark 26%/25%,
  72%/82%, 62%/69%, as on the looks page); `const Map<String, IconData> kHabitIcons` with these 24 names, rounded
  icons: check_circle, water_drop, fitness_center, directions_walk, directions_run, self_improvement, menu_book,
  bedtime, mobile_off, restaurant, local_drink, medication, spa, school, edit_note, savings, cleaning_services, pets,
  language, music_note, brush, wb_sunny, favorite, smoke_free.
- `HabitRow({required HabitDayView view})` (ConsumerWidget): icon tile (40 dp, radius 12), name, one sub-line, a
  44 dp round tick on the right; a count shows "+" (adds `step`; long-press opens "Amount" with a number field) and a
  3 dp progress line along the row's bottom. Sub-line parts joined by " · ": the cue; for perWeek "1 of 2 this week";
  for counts "5 of 8 glasses" (unit omitted when empty); the streak as a small amber flame icon plus "6 days" /
  "1 day" / "3 weeks" (hidden at 0); for spares "1 spare left" / "2 spares left" / "No spares left this week" (not for
  perWeek). Tap and long-press open `/habits/edit` (the page comes in demo 2); swipe left archives with Undo, as
  today.
- `HabitsWeekStrip({required List<HabitDayView> views, required String today, required Map<String, WorkShiftModel>
  shifts, required bool weekStartsSunday})`: 7 days, each a ring of kept ÷ (kept + partial + missed + pending) over
  that day's `dayState`s (empty ring when none), the date inside, a sun (day shift) or moon (night shift) under it;
  today on a filled pill. Display only in demo 1.
- `HabitSections({required List<HabitDayView> views})`: sections "Wake-up", "Any time", "Daytime", "Before sleep" for
  rows whose today is pending or partial, each hidden when empty; then the folds "Done today · n" (kept) and "Not due
  today · n" (notDue, away, rest, sick), both collapsed at first, the latter with a reason per row ("Done for the
  week", "Not today", "Away", "Rest day", "Sick day"). A newly kept row stays in its section for 400 ms, then moves
  to the fold.

- [x] **Step 1: Write the failing tests:**
  - `a tick row shows the cue, the streak and the spares` ("After dinner · 6 days · 1 spare left", flame icon present)
  - `a count row shows 5 of 8 glasses and a + that adds the step` (fake `HabitActions` records `addAmount(id, 1)`)
  - `kept habits fold under Done today after the pause` (pump 300 ms: still in its section; pump 200 ms more: gone,
    fold reads "Done today · 1")
  - `empty sections are hidden`
  - `a habit not due today sits under Not due today with its reason`
  - `no text is struck through` (no `TextDecoration.lineThrough` in the tree)
- [x] **Step 2:** Run → FAIL.
- [x] **Step 3:** Implement.
- [x] **Step 4:** Run → PASS.
- [x] **Step 5:** Commit `feat(habits): Look A row, week strip and sections`.

### Task 6: The Habits screen, Today and Home
**Files:** Rewrite `lib/features/habits/presentation/screens/habit_list_screen.dart` and
`test/features/habits/habit_list_screen_test.dart`; Delete `widgets/habit_tile.dart`, `widgets/streak_badge.dart`;
Modify `lib/features/today/presentation/screens/today_screen.dart` and
`lib/features/home/presentation/widgets/habits_block.dart` (shared, announced first).

**Interfaces — Consumes:** `habitDayViewsProvider`, `habitTodayProvider`, `shiftsByDateProvider`, `settingsProvider`,
the Task 5 widgets.
- Habits screen: app bar "Habits"; a line with the date (`DateFormat('EEE d MMM')`, e.g. "Wed 4 Nov"), a chip "Day
  off" / "Day shift" / "Night shift" from `shiftsByDateProvider`, and "2 of 6 done" (kept ÷ habits due today, that is
  kept, pending or partial);
  the week strip; `HabitSections`; the + button opens `/habits/add`; empty state "No habits yet" with a button "Add
  your first habit"; the existing `CoachMarks(kCoachHabits)` wrapper stays.
- Today: its habits section shows `HabitSections` for today. Home's Habits block shows the rows still to do and a line
  "2 done" (no folds).

- [x] **Step 1: Write the failing tests:** `shows the sections, the week strip and the done count` · `the empty state
  offers Add your first habit` · `the + button opens the editor`.
- [x] **Step 2:** Run → FAIL.
- [x] **Step 3:** Implement; update Today and Home; remove the Task 6 pieces listed under Task 2's "What goes when"
  (and the old `app.dart` line).
- [x] **Step 4:** `$F test test/features/` → PASS; analyze clean.
- [x] **Step 5:** Commit `feat(habits): Look A on the Habits screen, Today and Home`.

### Task 7: The editor
**Files:** Create `lib/features/habits/presentation/screens/habit_editor_screen.dart`; Delete
`add_habit_screen.dart`; Modify `lib/core/router/app_router.dart` (shared: `/habits/add` and `/habits/edit` build
`HabitEditorScreen`); Test `test/features/habits/habit_editor_screen_test.dart`.

**Interfaces — Produces:** `HabitEditorScreen({HabitModel? habit})`. Title "New habit" / "Edit habit". Fields and
labels: "Name" (hint "e.g. Read 20 minutes", 1–120 characters) · "Icon and colour" (the 24 icons, 8 colours) ·
"Kind": "Tick" / "Count"; for Count "Goal per day" (1–999), "Unit" (hint "glasses"), "Each + adds" (1–goal) · "When":
"Every day" / "Chosen days" (weekday chips in the week-start order; at least one) / "A few times a week" ("Times a
week" 1–6, default 3) · "Spare days a week" 0/1/2 (default 1 for a new every-day habit, else 0; hidden for a few times
a week; helper "A missed day uses one, and the streak lives on.") · "Part of the day": "Wake-up" / "Any time" /
"Daytime" / "Before sleep" · "Cue" (hint "After I …", optional, up to 80 characters) · "Daily reminder" and "Reminder
time" as today · menu "Delete habit" (the existing Recently deleted flow, `archiveService.trashHabit`). Save →
`habitActions.save`, then the reminder booking exactly as `add_habit_screen.dart` does today.

- [x] **Step 1: Write the failing tests:** `a new every-day habit saves with 1 spare day` · `A few times a week hides
  spare days and saves perWeek` · `chosen days saves the mask and needs at least one day` · `a count habit saves goal,
  unit and step` · `editing keeps the id and its ticks` · `Delete habit sends it to Recently deleted`.
- [x] **Step 2:** Run → FAIL.
- [x] **Step 3:** Implement; tell the Uplan chat before the router edit; remove the Task 7 pieces listed under Task 2's
  "What goes when".
- [x] **Step 4:** Run → PASS.
- [x] **Step 5:** Commit `feat(habits): the new habit editor`.

### Task 8: Backup
**Files:** Modify `lib/core/backup/backup_service.dart` (shared, announced first); Test
`test/core/backup_service_test.dart` (add).

**Interfaces — Produces:** on import, each habit row is read as `Habit.fromJson({...defaults, ...row})` with the
Task 1 defaults by JSON key, and a row with no `schedule` key and `targetPerWeek` below 7 becomes `schedule
'per_week'`, `perWeek = targetPerWeek`; each completion as `{value: 1, status: 'done', note: null, createdAt: null,
...row}`; `habit_pauses` is imported and sits in the delete order before `habits`.

- [x] **Step 1: Write the failing tests:** `an old backup without the new habit keys imports with defaults` · `an old
  3-a-week habit imports as a few times a week` · `habit pauses survive a backup and restore`.
- [x] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [x] **Step 5:** Commit `fix(backup): older backups import into schema 27`.

### Task 9: Try it for real, then master
- [x] **Step 1:** `$F test` (whole suite) and `$F analyze` in the worktree → all pass, no issues; note the count.
- [x] **Step 2:** The fast build from the worktree (`$F build apk --profile`, debug key: emulator only) on the Flip
  emulator with a copy of his data (`.claude/skills/uplan-device-release/SKILL.md`; his copy's "H" stays archived);
  add 5 habits through the editor (a tick, a count, chosen days, a few times a week, one with a cue); tick, use +,
  watch the fold; screenshots of Habits (dark and light), Today and Home; restart the app and check the ticks stay.
- [x] **Step 3:** Tell the Uplan chat "merging tester/speed (habits demo 1, schema 27) into master now" and wait for
  its OK (no uncommitted app code of either chat). In `D:\projects\trackerapp`: `git pull`, `git merge tester/speed`,
  build_runner, `$F test`, `$F analyze`, push.
- [x] **Step 4:** Handover: the design's Status, `docs/_Master_Plan.md`, `docs/_Task_History.md`, `docs/_Week_Log.md`,
  `docs/_Current_Task.md`, and the Manual Test Steps for Ahmed. The phone install waits for his "Phone plugged in" and
  runs under the install rule (his data copied off first).
