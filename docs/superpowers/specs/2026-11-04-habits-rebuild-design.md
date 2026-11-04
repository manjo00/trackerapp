# Habits rebuild: design (Look A)

**Date:** 2026-11-04 · **Status:** written for Ahmed's OK. He asked "i want to rebuild the habit tracker research and
come back to me with good design" and picked **Look A, the day list** ("Look A", 2026-11-04) from the looks page
https://claude.ai/artifact/GAkkbPjK3PCQmd6S8hLNid. No code yet. · **Chat:** Tester · **Path:** the full one, because
it changes the database (schema 26 → 27): this design → his OK → a plan in `docs/superpowers/plans/` → demos.
**Shared with the Uplan chat** (install rule, 2026-11-04, `docs/_Decisions_Log.md`): the schema bump and every shared
file below are announced to it first; the code is built on `tester/speed` in `D:\projects\trackerapp-tester` and
merged into master only after telling it.

## 1. Goal
A habit tracker Ahmed actually uses: he adds his own habits, ticks them in one tap from Home or the Habits screen, a
missed day never wipes out his progress, night shifts count properly, and it stays instant as months pass.
**Not in this rebuild (parked):** habits to avoid ("no sugar"), a home-screen widget with tick buttons, folding
Trackers into habits, Health Connect auto-ticks (steps, sleep), sharing.

## 2. What we know
### His real use (read only, from a scratchpad copy of `D:\backups\uplan\2026-11-04-history\after\life_tracker.db`)
- **Habits were never really used:** one habit ever ("H", created and archived 2026-08-25 20:34, never ticked);
  `habit_completions` and `custom_trackers` have never held a row. Nothing of his to migrate except that one row.
- **Gym:** 29 workout days since 2026-06-29, counted the way the workout log counts them (a session with at least one
  set whose weight or reps is filled in; `workout_repository.dart`). Weeks start on Sunday in these numbers.
- **Shifts:** 72 between 2026-06-02 and 2026-10-24, 41 day (07:00–19:00) and 31 night (19:00–07:00), in day months
  (July, August) and night months (September, October). Nothing entered after 24 Oct, so the app reads every later
  day as a day off.
- **Gym against shifts:** of the 27 workout days inside the schedule's range, 18 fell on days off, 5 on day shifts,
  4 on night-shift days. During the night block (4–24 Oct) three weeks had no workout.
- **His Home** has no Habits block (pinned note, due today, urgent, this week, workout, notes, shift, a list, a label).

### The current code (`lib/features/habits`, about 1,300 lines) and its flaws
1. `HabitsRepository.calculateStreak` stops at the first day without a tick, starting from today, so a streak is 0
   until today is ticked.
2. `Habits.targetPerWeek` is saved and edited but used by nothing.
3. One miss resets the streak.
4. The day is `DateTime.now()`'s calendar date, so it flips at midnight.
5. Every habit shows every day; no history page, no stats; edit only by long-press; done names struck through.
6. Every tick re-reads every completion ever (`watchHabitsWithCompletions`, `watchHabitsForDate` with one query per
   habit); no unique key on `(habit_id, date)` and the toggle is read-then-write.

### Research (sources in section 11)
1. Lally 2010: habits took 18–254 days to become automatic (about 66 typical); one missed day had little effect,
   many misses lowered the plateau.
2. The "what-the-hell" effect: after a slip people drop the goal; pointing at a broken streak loses more people.
3. Emergency reserves (Sharif and Shu 2021): a goal with a couple of spare days kept people going after a slip
   better than an easier goal (one small replication did not confirm it).
4. "When X, I will Y" plans: d = 0.65 over 94 tests (Gollwitzer and Sheeran 2006).
5. Few apps let the day end after midnight, and users ask for it; night-shift guides say count from waking to sleep.
6. Loop's strength score is a moving average (`score = prev × m + checkmark × (1 − m)`); Loop is GPLv3, so we write
   our own rule (section 4.5) and copy no code.

## 3. Decisions
| Decision | Who |
|---|---|
| Look A, the day list, for the Habits screen; the same rows on Today and Home | Ahmed, 2026-11-04 |
| Tapping a row opens the habit's page; the round button ticks; long-press edits; swipe left archives with Undo | Claude's call (round table finding 6: the same tap-for-details as tasks) |
| The habit day starts at 04:00; after a night shift it starts 3 h after the shift ends. Both in Settings | Claude's call |
| Spare days: new every-day habits get 1 a week, other kinds 0; he can pick 0, 1 or 2 | Claude's call (research point 3) |
| Gym ticks itself on any day with a logged workout, by the workout log's own rule, history included | Claude's call |
| Weeks follow the app's week-start setting (Sunday or Monday); the numbers in this file use Sunday weeks | Claude's call |
| Existing data: "H" stays archived; `targetPerWeek` 7 → every day, 1–6 → "N a week" | Claude's call |
| A habit's past days are judged by its current schedule (no schedule history) | Claude's call (simpler; a change of schedule re-scores the past) |
| The Habits block is offered for Home once, when his first habit is saved; never added silently | Claude's call |

## 4. The rules (pure Dart, `lib/features/habits/domain/`, written test-first)
### 4.1 The habit day (`habit_day.dart`)
- A moment belongs to the calendar date of (moment − day start). Day start defaults to 04:00, so 02:30 on Thursday
  counts for Wednesday.
- **Night shifts** (switch, on by default): for a shift whose end time is not after its start time (it crosses
  midnight), every moment on the next calendar day before *end time + 3 h* belongs to the shift's date, when that is
  later than the day start. A night 19:00 → 07:00 on Thursday keeps "Thursday" until Friday 10:00.
- No shift entered = a normal day.

### 4.2 When a habit is due (`schedule.dart`)
- **Every day** · **Chosen days** (a weekday mask) · **N a week** (1–6; due every day of the week until the week's
  count reaches N, then "done for the week") · **By shift** (any of: day off, day shift, night shift; read from
  `work_shifts` for the habit day; no entry = day off).
- A day before the habit was created, or not due, never counts.

### 4.3 What each day is
For a due day: **kept** (ticked, or a count that reached its goal, or a logged workout for a Gym-linked habit),
**partial** (a count above 0 but under its goal), **missed**, **rest** or **sick** (a planned break for one habit),
**away** (inside an Away range, all habits), **pending** (today, not kept yet). A tick on an away, rest or sick day
still counts as kept.

### 4.4 Streak (`habit_stats.dart`)
- Day-based habits: walk back from today over due days. Kept: +1. Pending today, rest, sick, away, not due: skip
  (neither counts nor breaks). Partial or missed: use a spare day if that week still has one left (the day doesn't
  count, the streak goes on); otherwise stop.
- N-a-week habits: the same walk over weeks; a week counts once its N is reached; the current week counts only once
  reached and never breaks the streak while it's running; a week entirely away is skipped.
- Shown as "🔥 6 days" or "🔥 3 weeks"; hidden when 0 (no "streak lost" anywhere).

### 4.5 Strength (`habit_stats.dart`)
- 0 % on the habit's first day, then for each finished due day: `s += (v − s) / 20`, v = 1 kept, 0 missed,
  `min(1, amount / goal)` for a count. Rest, sick, away and not-due days change nothing; a spare-covered miss still
  lowers it. N-a-week habits move once per finished week: `s += (v − s) / 6`, `v = min(1, count / N)`.
- Shown as a whole percent. Check against his log as a Gym habit at 2 a week: 76 % at the peak (the week of 27 Sep),
  45 % now (section 9's fixture).

### 4.6 Page numbers
This week (`1 of 2`), days or weeks kept (`9 of 18 weeks`), best run (`4 weeks, 6 Sep – 3 Oct`), streak, and a count
of kept days by shift kind.

## 5. Look A: the screens
### 5.1 The Habits screen (`/habits`)
- **Top:** "Habits" and a menu (Away…, Archived habits, Habit settings). Under it the date, a chip for the day's
  shift (Day off, Day shift 07:00–19:00, Night shift 19:00–07:00) and "2 of 6 done".
- **Week strip:** the 7 days of the current week; each a ring (share of that day's due habits kept), the date
  inside, a sun or moon for a day or night shift. Tapping a day shows that day's list: past days of this week can be
  fixed (tick, untick, rest, sick); future days are read-only. Today is highlighted.
- **Sections**, in this order, each shown only while something in it is left: **Wake-up**, **Any time**, **Daytime**,
  **Before sleep**. A habit sits in the section picked in its editor (Any time by default).
- **Row:** the habit's icon in its colour, the name, and one line made of the cue ("After dinner"), the streak
  ("🔥 6 days") and, for habits with spare days, "1 spare left"; for N-a-week habits "1 of 2 this week"; for a
  Gym-linked habit a small bolt on the icon. On the right a round tick button (44 dp). A count habit shows
  "5 of 8 glasses", a + button (long-press it to type an amount) and a thin progress line along the row's bottom.
- **Done today:** a kept row shows its tick, then after about 0.4 s folds into a collapsed "Done today · 2" line at
  the bottom; opening it shows the done rows (no strike-through), where a tap on the tick unticks.
- **Not due today · n:** a collapsed line under it for habits not due ("Days off only", "Done for the week").
- **Away banner:** "Away until Fri 8 Nov · End now" while an Away range covers today.
- **Empty state:** "Add your first habit" with starter chips (Water ×8, Stretch 5 min, Read 20 min, Walk 20 min, Gym
  from workouts); a chip fills the editor.
- **+ button** opens the editor.

### 5.2 A habit's page (`/habits/:id`)
As on the looks page: strength % big, chips (its schedule, "Ticks itself from workouts"), a strength line by week
(up to 26 weeks), four tiles (This week, kept, best run, streak), a grid of its days since it started (up to 26
weeks; shift days dotted), "When you do it" by shift kind (only when shift data exists), and Edit and Archive.
Tapping a past day in the grid opens a small sheet: Done, Rest, Sick, Clear. The menu adds Delete.

### 5.3 The editor (`/habits/add`, `/habits/edit`)
Name · icon and colour (about 24 icons, 8 colours) · kind: Tick or Count (goal, unit, step) · When: Every day, Chosen
days, N a week, By shift · Spare days 0/1/2 (hidden for N a week) · Part of day · Cue ("After I …", optional) ·
Reminder time (optional) · "Tick when I log a workout" (switch) · Delete in the menu when editing.

### 5.4 Breaks and settings
- The habit page menu: "Rest today", "Sick today". The Habits screen menu: "Away…" (a date range for all habits).
- **Settings › Habits:** "New day starts at" (04:00), "After a night shift, the day starts 3 h after it ends" (on),
  "Quiet during shifts" (on).

## 6. Other places that show habits
- **Today:** the habits section uses the Look A row and folds, due-today habits only.
- **Home:** the Habits block shows due-today rows not yet done plus "2 done". When his first habit is saved and Home
  has no Habits block, a one-time prompt offers "Show today's habits on Home?" (Add · Not now).
- **Planner:** each day lists the habits due that day with their state; the day dots count due habits only.
- **Widget:** "habits left" counts due-today habits not yet kept, by the habit day.
- **Live dashboard:** only due-today habits not yet kept; a tick from the notification uses the same rules.
- **Reminders:** one per habit, booked as single alarms for its next 7 due days (not a daily repeat), skipping times
  inside a shift when "Quiet during shifts" is on, re-booked at app start, after any habit, tick or shift change, and
  by the existing midnight refresh. New notification ids `1000000 + habitId × 8 + k` (k 0–6), clear of the task
  ranges (10000+, 40000+); the old daily id (= habit id) is cancelled once.
- **Archive and Recently deleted:** unchanged; history is kept on restore.
- **Backup:** exports the new columns and table; importing an older backup fills defaults for any missing habit key
  before reading it (the same kind of gap as the v1.18 old-backup bug under "Noticed" in `docs/_Current_Task.md`).
- **Coach tips and Codex:** habit texts updated to the new rules.

## 7. Data (schema 27)
- **`habits`** gains: `kind` ('tick' | 'count', default 'tick'), `goal` (int, 1), `unit` (text, null), `step`
  (int, 1), `icon` (text, a Material icon name), `color` (int), `schedule` ('daily' | 'weekdays' | 'per_week' |
  'shifts', default 'daily'), `weekday_mask` (int, 127), `per_week` (int, null), `shift_mask` (int: off 1, day 2,
  night 4; default 7), `spares_per_week` (int, 0; the editor proposes 1 for a new every-day habit), `section` ('wake' | 'any' | 'day' | 'sleep', default 'any'), `cue`
  (text, null), `sort_order` (int, 0), `auto_source` ('workout' or null). `target_per_week` stays (unused) so no table
  rebuild is needed.
- **`habit_completions`** gains: `value` (int, 1), `status` ('done' | 'rest' | 'sick', default 'done'), `note`
  (text, null), `created_at` (date-time, null). Migration deletes duplicate `(habit_id, date)` rows (keeping the
  lowest id), then adds a unique index on `(habit_id, date)`.
- **`habit_pauses`** (new): `id`, `start_date`, `end_date` (inclusive, 'yyyy-MM-dd'), `created_at`.
- Gym ticks are not stored: a Gym-linked habit's day is kept when a manual tick exists or a logged workout has that
  date, so deleting a workout removes its tick.
- **Settings** (SharedPreferences): `habit_day_start_minutes` (240), `habit_night_shift_rule` (true),
  `habit_quiet_during_shifts` (true).
- **Queries:** one query per screen for the habits and their completions of the last 400 days; the workout days come
  from a read-only query in the habits DAO (`customSelect`, reading `workout_sessions` and `workout_sets`), so the
  workout files are not touched.

## 8. Files
- **Habits (this chat's files):** `domain/` (new: `habit_day.dart`, `schedule.dart`, `habit_stats.dart`,
  `day_state.dart`); `data/tables/` (both tables changed, `habit_pauses_table.dart` new); `data/dao/habits_dao.dart`
  (rewritten queries); `data/repositories/habits_repository.dart`; `data/models/` (extended); `presentation/`:
  `habit_list_screen.dart` (Look A), `habit_page_screen.dart` (new), `habit_editor_screen.dart` (replaces
  `add_habit_screen.dart`), widgets (`habit_row.dart`, `habits_week_strip.dart`, `habit_section.dart`,
  `habits_fold.dart`, `habit_grid.dart`, `strength_chart.dart`, `icon_colour_picker.dart`, `starter_chips.dart`),
  providers.
- **Shared, announced to the Uplan chat before each edit:** `lib/core/database/app_database.dart` (schema 27 and its
  migration), `lib/core/router/app_router.dart` (`/habits/:id`), `lib/core/settings/` (three settings) and the
  settings screen, `lib/core/notifications/notification_service.dart`, `lib/core/widget/home_widget_service.dart`,
  `lib/core/notifications/live_dashboard_service.dart`, `lib/core/backup/backup_service.dart`,
  `lib/features/archive/domain/archive_service.dart`, `lib/features/today/presentation/screens/today_screen.dart`,
  `lib/features/home/presentation/widgets/habits_block.dart`, the planner's habit providers and day views, the coach
  and Codex texts. **Not touched:** anything under `lib/features/workout/`.

## 9. Testing
- **Rules, test-first:** the habit day (04:00; a night shift until 10:00; two nights in a row; no shift data; the
  switch off); due days for each schedule (by shift with and without entries; N a week before and after reaching N);
  streak (today pending; a spare used and none left; rest, sick, away and not-due gaps; weeks); strength (the formula,
  a partial count, a spare-covered miss lowers it, breaks don't); and a **fixture built from his weekly workout
  counts** (5, 1, 2, 1, 0, 2, 4, 1, 2, 0, 3, 2, 2, 2, 0, 0, 0, 1 for the 18 finished Sunday weeks from 28 Jun) placed
  on made-up days, because the repo is public and his exact gym dates stay out of it: as a Gym habit at 2 a week,
  9 of 18 weeks kept, best run 4 weeks ending the week of 27 Sep, strength 76 % at the peak and 45 % now.
- **Database:** 26 → 27 on a copy of his database (the `tool/migrate_copy_test.dart` way): every table keeps its
  rows, "H" survives archived, a planted duplicate tick is removed, the unique index exists; an old backup without the
  new keys imports.
- **Screens (widget tests):** a tick folds the row into "Done today"; + reaches the goal; an empty section hides; a
  row tap opens the page; a habit not due today sits under "Not due today".
- **For real:** the fast build on the emulator with a copy of his data plus demo habits; then his phone under the
  install rule, his data copied off first.

## 10. Demos (estimate only the next one)
1. **Demo 1, tick and see:** schema 27 and its migration, the rules (the 04:00 day, every day, chosen days, N a week,
   spares, streak, strength), the Look A Habits screen (week strip, sections, rows with counts, both folds), the
   editor (all fields except by-shift and the Gym link), Today and Home rows, backup defaults. Reminders keep
   today's daily alarm until demo 3. **Guess: 2.5–3.5 h of
   my work plus about 15 min of builds and tests; about 0.8–1.3 M tokens; no helpers.**
2. **Demo 2, the page and the breaks:** the habit page, fixing past days, Rest, Sick, Away, starter chips, the Home
   offer.
3. **Demo 3, shifts and the gym:** due by shift, the night-shift day, quiet and due-day reminders, Gym ticking itself
   with its history.
4. **Demo 4, the rest of the app:** Planner, widget, live dashboard, coach and Codex texts.

## 11. Sources (checked 2026-11-04)
[Lally summary](https://bps.org.uk/research-digest/how-form-habit) ·
[Sharif, BBC via CHIBE](https://chibe.upenn.edu/news/bbc-how-emergency-reserves-can-help-you-stick-to-your-goals/) ·
[Olson Zaltman](https://www.olsonzaltman.com/zfiles/freaky-streaks) ·
[Sharif and Shu 2021](https://anderson-review.ucla.edu/wp-content/uploads/2021/03/Sharif-Shu_EmergencyReserveFailure_OBHDP2019.pdf) ·
[Utrecht replication](https://studenttheses.uu.nl/handle/20.500.12932/44466) ·
[Mobbin, 859 streak designs](https://mobbin.com/blog/streaks-are-about-losing-a-study-of-859-streak-designs) ·
[Gollwitzer and Sheeran 2006](https://kops.uni-konstanz.de/entities/publication/2e749bfb-8533-437c-8203-7e788c910c5f) ·
[Habitify request](https://feedback.habitify.me/p/start-day-at) ·
[Day One request](https://forums.dayoneapp.com/forums/topic/setting-to-push-day-boundary-to-4am-to-keep-streaks-on-late-night-entries/) ·
[Night-shift guide](https://mindcrate.vercel.app/how-to-track-habits-if-you-work-night-shifts-or-rotating-schedules-d19ef2) ·
[Loop source](https://github.com/iSoron/uhabits) ·
[2026 app roundup](https://2sync.com/blog/best-habit-tracker-apps)

## Noticed (not fixing now)
- Trackers have never held a row either; the round table's "merge checklist trackers into habits" could become
  "retire Trackers". His call, later.
- Habits isn't one of the default bottom tabs (Home, Lists, Planner); the Home offer (5.1, 6) covers daily use.
- His work schedule has nothing after 24 Oct, so by-shift habits read every later day as a day off until it's filled
  in (the parked "rota photo to shifts" idea would help).

## Status
- 2026-11-04 19:05: research and three looks; draft. About 19:10: he picked Look A; by 19:15 this design was
  written for his OK.
  Correction: the draft and the looks page said 30 gym days, 10 of 18 weeks, a 77 % peak and 6 day-shift workouts;
  by the workout log's own rule (weight or reps filled in) it is 29, 9 of 18, 76 % and 5 (11 Jul had only an empty
  set). About 19:20: his OK ("Yes, plan demo 1"). 19:30: the plan for demo 1,
  `docs/superpowers/plans/2026-11-04-habits-demo-1.md`. 19:30: the Uplan chat OKed schema 27; his OK ("Yes, start
  demo 1").
- 2026-11-04 19:35–20:40: **demo 1 built and merged** (test-first on `tester/speed`, `51fb715..5ed813e`, merged as
  `98eb3d7`, pushed): schema 27 and its migration, the rules, the providers, Look A (row, week strip, sections and
  folds) on the Habits screen, Today and Home, the editor, older backups importing, and two fixes from the final
  self-review (the live notification's ✓ now saves the habit day; the Habits tip says the circle ticks). 479 tests pass,
  analyze clean. Tried for real on the Flip emulator's fast build with a copy of his newest data (2026-11-04-kilos):
  the app upgraded it to 27 on the device (integrity ok, all 24 tables kept their rows, "H" still archived); with 5
  made-up demo habits and one added through the editor, ticks folded under "Done today", + counted, streaks and
  spare days read right, light and dark matched the picked look, Today showed the same sections, a restart kept
  everything, no duplicate days, no Flutter errors. **Not on his phone yet.**
- Left for demo 4 (decided in the review): the live notification's done list and the widget's "habits left" still
  use the calendar day between 00:00 and 04:00 (they pair with the Kotlin side), the Planner's tap on a count habit
  saves 1, and the widget counts any amount of a count habit as done.
- **Next:** his phone install when he says "Phone plugged in" (his data copied off first; the install rule), his
  Manual Test Steps and opinion, then the plan for demo 2 (the habit page, fixing past days, Rest, Sick, Away,
  starter chips, the Home offer).
- **Manual Test Steps for Ahmed, after the install:** 1. Menu › Habits: "No habits yet" and "Add your first habit".
  2. Tap it, name "Water", tap Count, Goal per day 8, Unit "glasses", Save habit. 3. Tap + on Water three times: "3 of 8
  glasses" and the line under it grows. 4. Add "Read 20 min" (Tick, Every day, Before sleep, cue "After dinner"): its
  line reads "After dinner · 1 spare left". 5. Tap Read's circle: it fills, then folds under "Done today · 1"; tap that
  line to see it. 6. Open Today: the same rows. 7. Close Uplan fully and open it again: everything is still there.
