# Habits rebuild: research, the engine and three looks (DRAFT)

**Date:** 2026-11-04 · **Status:** draft, **not approved**. Ahmed's request (2026-11-04, through the Uplan chat): "i
want to rebuild the habit tracker research and come back to me with good design". Research done, three looks shown on
a private page: https://claude.ai/artifact/GAkkbPjK3PCQmd6S8hLNid. **Waiting for his pick of look (A recommended).** No
code written. · **Chat:** a side session started by the Uplan chat · **Path:** the full one (it changes the database):
his pick → this design rewritten as the approved spec → a plan → demos.

## 1. What I found

### His real use (read only, from a scratchpad copy of `D:\backups\uplan\2026-11-04-history\after\life_tracker.db`, schema 26)
- **Habits were never really used.** `sqlite_sequence` says one habit ever: "H", created and archived 2026-08-25
  20:34, never ticked. `habit_completions` and `custom_trackers` have never held a row. So this rebuild is about
  making habits worth opening, not fixing a routine he has. The migration still has to handle real rows correctly.
- **Gym:** 30 workout days with at least one logged set since 2026-06-29 (35 with any workout), about 1.6 a week.
- **Shifts:** 72 between 2026-06-02 and 2026-10-24: 41 day (07:00–19:00), 31 night (19:00–07:00), in months of day
  shifts (July, August) then nights (September, October). Nothing entered after 24 Oct.
- **Gym against shifts:** of the 28 workout days inside the schedule's range, 18 fell on days off, 6 on day shifts,
  4 on night-shift days. During the night block (4–24 Oct) three weeks had no workout.

### The current code (`lib/features/habits`, about 1,300 lines)
1. `HabitsRepository.calculateStreak` walks back from today and stops at the first gap, so **a streak is 0 until
   today is ticked**: every morning all streaks disappear (`StreakBadge` hides a 0).
2. `Habits.targetPerWeek` (1–7) is saved and edited but **used by nothing** (not the streak, not the screens).
3. One miss resets the streak to 0.
4. The date is `yyyy-MM-dd` of `DateTime.now()`, so **the day flips at midnight**, wrong for night shifts.
5. Every habit shows every day; no history page or stats; edit only by long-press (`habit_tile.dart`); done names
   are struck through and dimmed (`habit_tile.dart:83-87`, round table looks finding 9).
6. `watchHabitsWithCompletions` joins every completion ever; `watchHabitsForDate` watches the whole completions
   table then asks once per habit; no unique key on `(habit_id, date)` and the toggle is read-then-write (round
   table code findings 6 and 9).
- **Places that show habits** (all need the new rules): Today (`today_screen.dart`), the Home block
  (`habits_block.dart`), Planner (`planner_providers.dart`, `day_column.dart`, `day_detail_view.dart`), the widget's
  count (`home_widget_service.dart`), the live dashboard (`live_dashboard_service.dart`, `LiveCards.kt`), reminders
  (`notification_service.dart`), archive (`archive_service.dart`), backup (`backup_service.dart`), coach and Codex
  texts.

## 2. Research (checked 2026-11-04)
1. **Lally et al. 2010** (96 people, 82 finished, one daily behaviour for 84 days): automaticity took 18 to 254 days,
   about 66 typical; **one missed day had little effect, many misses lowered the plateau**. → Show the trend; never
   punish one miss.
2. **The "what-the-hell" effect:** after a slip people drop the goal, and apps that point at a broken streak lose
   more people (Sharif via BBC/Penn CHIBE; Olson Zaltman's summary).
3. **Emergency reserves** (Sharif and Shu, OBHDP 2021; JMR 2017): a goal with a couple of costed skips (gym 7 days
   with 2 emergency skips) kept people going after a slip better than an easier goal (5 days). A small Utrecht
   replication (11 people in the reserve group) did not confirm it. Mobbin (a secondary source) reports Duolingo got
   about 200,000 more daily returners by letting people hold two streak freezes.
4. **Implementation intentions** ("when X, I will Y"): d = 0.65 over 94 tests (Gollwitzer and Sheeran 2006); a 2024
   meta-analysis of 642 tests says the effect depends on the plan's format and the person's motivation.
5. **Day boundary:** few apps let the day end after midnight (one allows up to 06:00); Habitify and Day One users
   keep asking for it; a night-shift guide suggests counting from waking to sleep. Uplan has his shift data, so it
   can do better.
6. **Loop Habit Tracker's strength** (GPLv3: we write our own, never copy): `score = prev × m + checkmark × (1 − m)`,
   `m = 0.5^(√f / 13)`, f = repetitions per day (daily: m ≈ 0.948, a half-life of 13 days). Read from
   `uhabits-core/.../models/Score.kt` on its `master` branch.
7. **Landscape:** Loop (Android, clean, strength score), HabitKit (history grids), Streaks (round tiles, iOS),
   Habitify (time-of-day sections, analytics). Each look borrows one idea.

Sources: [Lally summary](https://bps.org.uk/research-digest/how-form-habit) ·
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

## 3. The engine (the same under every look; proposed)
1. **Kinds:** Tick, or Count with a daily goal and unit (8 glasses: tap adds one, long-press types a number).
2. **When it's due:** every day · chosen weekdays · N times a week · by shift (any of days off, day shifts, night
   shifts, read from `work_shifts`). A day it isn't due never counts as a miss, and it stays off Today and Home.
3. **The habit day:** starts at 04:00 (a setting), not midnight; after a night shift it starts 3 hours after the
   shift ends (07:00 → 10:00), so a 03:00 tick counts for the night's date.
4. **Spare days:** 0, 1 or 2 per week for day-based habits; a missed due day uses one automatically and the streak
   continues. N-a-week habits need none.
5. **Streak:** due days kept in a row (weeks for N-a-week habits). Today not done yet never breaks it.
6. **Strength (0–100 %),** our own moving average: per due day `s += (v − s) / 20` (v = 1 kept, 0 missed, for a
   count `min(1, amount / goal)`); per week for N-a-week habits `s += (v − s) / 6` with `v = min(1, count / N)`.
   A spare-covered miss still lowers strength; a planned break changes nothing. With his gym log at 2 a week: 77 % at
   the peak (week of 27 Sep), 45 % now; kept 10 of 18 finished weeks; best run 4 weeks (6 Sep – 3 Oct).
7. **Breaks:** Rest and Sick (a day, one habit or all) and Away (pause everything for a date range).
8. **Cue:** optional "After I …" text, shown under the name.
9. **Auto-tick:** a Gym habit linked to workouts: any day with a workout that has a logged set is ticked, history
   included.
10. **Reminders:** per habit, only on due days; "Quiet during shifts" (no habit reminder inside a shift's hours).
11. **No shame:** misses are grey, never red; no "streak lost" message; done habits fold away, no strike-through.
12. **Speed:** one windowed query per screen (about the last 400 days), a unique index on `(habit_id, date)`, a toggle
    as insert-or-delete in one transaction.

## 4. The looks (mockups on the page)
- **A. Day list (recommended):** sections by part of the day (Wake-up, Any time, Daytime, Before sleep, each shown
  only when something is left); a row = icon, name, a line with the cue, streak, "1 spare left" or "1 of 2 this week",
  and a round tick; count rows get a + and a thin progress bar; done rows fold under "Done today"; a week strip of
  day rings with shift icons on top. Fits the Home block and Today as it is.
- **B. Cards with history:** one card per habit with a 12-week grid, strength %, streak and a tick. About three
  per screen; Home would need a smaller version.
- **C. Ring tiles:** a 3-column grid of rings with the icon inside, today's big ring and a week of small rings on top.
  Short names only, no room for cues or spares.
- **In every look, each habit gets a page** (like the workout page): strength % big, chips (schedule, auto), a
  strength line by week, This week / Weeks kept / Best run / Streak, a grid since the start with shift dots, "When you
  train" by shift, Edit and Archive.

## 5. Data sketch (to firm up after his pick)
- Schema 27. `habits` gains: kind, goal, unit, icon, colour, schedule type, weekday mask, times per week, shift kinds,
  spares per week, cue, section, sort order, auto source. Migration: `targetPerWeek` 7 → every day, below 7 → "N a
  week".
- `habit_completions` gains: value (1 for a tick, the amount for a count), status (done, rest, sick), note, created
  at; a unique index on `(habit_id, date)` (remove duplicates first). Away ranges: a small new table.
- Settings: day start (04:00), the night-shift day rule (on), quiet during shifts (on).
- The rules as pure Dart in `lib/features/habits/domain/` (due days, the habit day of a moment, streak with spares
  and breaks, strength), test-first.
- Backup: export and import the new columns, and keep importing older backups that lack them (see the v1.18
  old-backup restore bug under "Noticed" in `docs/_Current_Task.md`).

## 6. Build order (guesses, to re-estimate after his pick)
0. This design rewritten for his OK: 20–30 min.
1. Demo 1, the engine and his look: schedules (every day, chosen days, N a week), spares, streak and strength, the
   04:00 day, Rest, Sick and Away, the new Habits screen, the habit page, the add sheet; Today and Home use the new
   rows. 2–3 h of work plus about 10 min of builds and tests.
2. Demo 2, shifts and the gym: due by shift, the night-shift day, quiet during shifts, Gym ticking itself. 1–2 h.
3. Demo 3, the rest of the app: Planner, the live notification, the widget count. 1–1.5 h.
Each demo: tried on the emulator with a copy of his data; on the phone only after his data is copied off.
**Parked:** habits to avoid ("no sugar"), a widget with tick buttons, folding Trackers into habits, Health Connect
auto-ticks (steps, sleep).

## 7. Assumed, to confirm with Ahmed
- He wants habits he'll tick daily, mostly from Home or Today.
- His day and night shifts should decide when habits are due.
- The same standard as the workout history: clean, fast, a page per habit.
- His gym log may feed a Gym habit.
- The five example habits on the page (Stretch, Water, Walk, Read, Phone away) are made up; he picks his own.

## Noticed (not fixing now)
- Trackers have never held a row either; the round table's "merge checklist trackers into habits" could become
  "retire Trackers". His call, later.
- Habits isn't one of the default bottom tabs (Home, Lists, Planner). For daily use it may want a tab or the Home
  block by default; a question for demo 1.
- His work schedule has nothing after 24 Oct, so shift-aware habits need it filled ahead (the parked "rota photo to
  shifts" idea would help).

## Status
- 2026-11-04 19:05: research done, the page published (private), this draft written; asked him which look
  (A recommended). **Next:** his answer, then this file becomes the approved spec, then a plan
  (`docs/superpowers/plans/`), then demo 1.
