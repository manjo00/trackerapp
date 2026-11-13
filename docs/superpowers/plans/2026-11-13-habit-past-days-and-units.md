# Habits: past days from the week strip, and count units: implementation plan

> **For agentic workers:** built in this chat with superpowers:executing-plans (Ahmed's rule: demo first, no helpers
> without his yes). Steps use checkbox (`- [ ]`) syntax.

**Goal:** tick, untick or count a past day (this week and last week) from the Habits screen's week strip, and give
count habits quick units with goals up to 99,999.

**Architecture:** the rules already judge any day from the saved history, so this is presentation only: a day view
learns to stand for a picked day (`HabitDayView.onDay`), the actions take an optional day, the rows and folds read the
view's day, and the strip and the screen hold the picked day. Units are a preset list used by the editor.

**Tech Stack:** Flutter 3.44, Riverpod, Drift, intl.

**Spec:** `docs/superpowers/specs/2026-11-13-habit-past-days-and-units-design.md`

## Global Constraints
- No database change (schema stays 27); nothing outside `lib/features/habits/` and its tests.
- Limit for picking: today, this week's past days and last week's days (`weekStartOf(today) - 7` and later).
- Today screen and Home keep showing today; the facts line keeps today's numbers.
- Amount limit `kMaxHabitAmount = 99999` for the goal and a typed amount; whole numbers only.
- Unit presets (unit, goal, step): glasses 8/1, ml 2000/250, min 30/5, hours 8/1, pages 20/5, steps 8000/1000,
  km 5/1, times 10/1. A preset fills goal and step only while the goal field is empty.
- Copy: "Yesterday · Thu 12 Nov", "Back to today", "Done on Thu · n", "Not due on Thu · n", "Not that day",
  "Nothing was due on Thu", "1 to 99,999", "Type a number from 0 to 99,999", "Add 250 ml", "1,250 of 2,000 ml".

## Review Focus
1. The picked day after the habit day turns (04:00) or after a week passes: it must fall back to today, not show a
   day outside the limit (Task 5 test).
2. A habit created after the picked day: hidden, not listed as missed (Task 2 test via `beforeStart`).
3. Switching days must not carry the 0.4 s "just ticked" linger or an open fold over (Task 5: sections keyed by day).
4. A count habit unticked on a past day steps back one step on that day, not today (Task 2 test).
5. A "few times a week" habit on a past day without a tick (`open`) must be tickable (Task 3 test).

---

### Task 1: a day view for a picked day, and actions that take a day
**Files:** modify `lib/features/habits/presentation/models/habit_day_view.dart`,
`lib/features/habits/presentation/providers/habits_providers.dart`; tests
`test/features/habits/presentation/habits_providers_test.dart`, new `test/features/habits/presentation/habit_day_view_test.dart`;
helper `test/features/habits/presentation/habit_widget_helpers.dart` (fake records the day; `testView` gains
`entries`, `step`, `createdAt`).

**Produces:** `HabitDayView.day` (`String?`, null = today), getters `state` (`DayState`) and `value` (`int`),
`HabitDayView onDay(String day, {required String today, required bool weekStartsSunday})`;
`HabitActions.tick(int habitId, {String? day})`, `addAmount(int habitId, int amount, {String? day})`;
`setAmount` accepts 0..99,999.

- [ ] Failing tests: `onDay` gives kept / missed / partial with the day's amount / beforeStart; `onDay(today)` keeps
  today's state; a tick with `day:` saves that date and leaves today pending; `addAmount` with `day:` adds there;
  typed `'1000'` and `'99999'` are accepted, `'100000'` refused.
- [ ] Run them: they fail (no `onDay`, no `day:`, 1000 refused).
- [ ] Implement; run: pass.

### Task 2: rows read and act on the view's day; amounts with separators
**Files:** modify `lib/features/habits/presentation/widgets/habit_row.dart`; new
`lib/features/habits/presentation/models/habit_units.dart` (`kUnitPresets`, `kMaxHabitAmount`, `formatAmount`);
test `test/features/habits/presentation/habit_row_test.dart`.

- [ ] Failing tests: on a picked day the round button calls `tick 1 2026-11-03`; a done count on a picked day steps
  back on that day (`add 2 -1 2026-11-03`); a count row shows the picked day's "8 of 8 glasses"; "750 of 2,000 ml"
  and the + tooltip "Add 250 ml".
- [ ] Run: fail. Implement (`view.state`, `view.value`, `view.day`; the typed-amount dialog saves on `view.day`).
  Run: pass.

### Task 3: folds for a picked day
**Files:** modify `lib/features/habits/presentation/widgets/habit_sections.dart` (`dayLabel` parameter, null =
today); test `habit_sections_test.dart`.

- [ ] Failing tests: with `dayLabel: 'Tue'` a missed row and a `open` few-times-a-week row are listed, kept ones fold
  under "Done on Tue · 1", not-due under "Not due on Tue · 1" with "Not that day"; nothing due says "Nothing was due on
  Tue".
- [ ] Run: fail. Implement (open = pending, partial, missed, open). Run: pass.

### Task 4: the strip picks a day and pages to last week
**Files:** modify `lib/features/habits/presentation/widgets/habits_week_strip.dart` (`selected`, `onPick`,
`weekOffset`, `onWeek`; top-level `bool isPickableDay(String day, {required String today, required bool
weekStartsSunday})`); new test `test/features/habits/presentation/habits_week_strip_test.dart`.

- [ ] Failing tests: `isPickableDay` for today, yesterday, last week's first day (true), the day before it and
  tomorrow (false); tapping Tue 3 calls `onPick('2026-11-03')`, tapping Thu 5 does nothing; "Last week" calls
  `onWeek(-1)`; with `weekOffset: -1` the strip shows 25–31 Oct and tapping 31 picks `2026-10-31`.
- [ ] Run: fail. Implement (no `onPick` = display only, as Today's use and the old test). Run: pass.

### Task 5: the Habits screen holds the picked day
**Files:** modify `lib/features/habits/presentation/screens/habit_list_screen.dart`; test
`test/features/habits/habit_list_screen_test.dart`.

- [ ] Failing tests: tapping 3 shows "Yesterday · Tue 3 Nov" and "Back to today", the missed habit's tick calls
  `tick 3 2026-11-03`; Back to today shows "Wed 4 Nov" again; a picked day outside the limit shows today.
- [ ] Run: fail. Implement (`ConsumerStatefulWidget`, `_picked`, `_weekOffset`, sections keyed by the shown day).
  Run: pass.

### Task 6: unit chips and the 99,999 limit in the editor
**Files:** modify `lib/features/habits/presentation/screens/habit_editor_screen.dart`; test
`test/features/habits/habit_editor_screen_test.dart`.

- [ ] Failing tests: Count, tap "ml": saves goal 2000, unit "ml", step 250; a typed goal 3 then "times": goal 3,
  step 1; goal 10000 "steps" saves; 100000 shows "1 to 99,999".
- [ ] Run: fail. Implement (chips keyed `unit-<word>`, selected while the field holds the word). Run: pass.

### Task 7: check and commit
- [ ] `flutter analyze` clean; the full `flutter test` passes.
- [ ] One commit on `claude/habit-yesterday-234c83` with the design and this plan; no merge, no push of `master`.
