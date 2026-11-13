# Habits: tick a past day from the week strip, and count units (design)

**Date:** 2026-11-13 · **Chat:** the habit-yesterday side chat of the Uplan chat · **Branch:**
`claude/habit-yesterday-234c83` (merged by the Uplan chat, tested by the Tester on the emulator) · **Path:** demo first,
small to medium, no database change.

## Why (Ahmed, 2026-11-13)
- "the ability to check yesterdays habet if i did the thing but forgot to check it so it doesn't consume a spare day"
- After picking the look: "1 and add a different units like ml for water and other stuff"

## What the code showed (checked 2026-11-13)
- The rules already count a late tick: `dayState` reads the saved days, so a tick saved today for yesterday makes
  yesterday kept, the spare day comes back and the streak holds. Only the Habits screen had no way to reach
  yesterday: the week strip was display-only in demo 1 (`habits_week_strip.dart`).
- The Planner can already tick a past day for tick habits (its day view toggles any date), but a tap on a count
  habit there saves 1, not the goal (left for demo 4).
- The Unit field is free text, but the goal stops at 999 and a typed amount at 999, so 2,000 ml or 10,000 steps can't
  be saved.

## Approaches
1. **Tap a day in the week strip** (picked by Ahmed, "1", from the looks page
   https://claude.ai/artifact/CxRqa9jTr6v3LvYiECkCWF). The habits design (2026-11-04, section 5.1) already planned
   this for fixing past days, so demo 2 builds on it instead of replacing it.
2. A "Yesterday" fold under today's list: only yesterday, one more line on the screen, and redundant once the strip
   can fix past days.

## Design
### Past days (Ahmed's pick)
- The strip's past days and today can be tapped; days after today can't. **‹** shows last week and **›** this week,
  so yesterday is reachable on the first day of a week too. **Limit: this week and last week** (Claude's call: covers
  "yesterday" every day of the week; older days wait for demo 2's habit page).
- The list shows the picked day. The top line reads "Yesterday · Thu 12 Nov" (or "Tue 10 Nov") with a
  **Back to today** button. Rows show that day's tick or amount and their round button, + and typed amount act on
  that day. The folds read "Done on Thu · n" and "Not due on Thu · n"; a day with nothing due says so.
- The facts line keeps today's numbers (the streak, spare days left this week, this week's count), so ticking
  yesterday shows the spare day coming back; a count habit's "750 of 2,000 ml" shows the picked day's amount.
- Leaving goes back to today: another tab, a screen on top (such as the editor) or the app going to the background
  (the Habits tab stays alive behind other tabs, so a picked day would otherwise still show hours later). So does a
  picked day that falls out of the limit when the day turns. Today and Home stay on today.

### Two old bugs fixed on the way (found by the new tests)
- Long-pressing a count habit's + never opened the amount box: the button's tooltip took the long-press. The +
  now has its own long-press.
- Closing the amount box used its text controller after it was thrown away (an error in debug builds); the box is now
  its own widget that cleans up after it closes.

### Count units (Claude's calls, said to Ahmed before building)
- Quick unit chips under the Count fields: glasses, ml, min, hours, pages, steps, km, times. The Unit field stays for
  anything else; a chip shows selected while the field holds its word.
- While the goal is still empty, a chip also fills a goal and a step (each + adds the step): glasses 8 and 1, ml 2,000
  and 250, min 30 and 5, hours 8 and 1, pages 20 and 5, steps 8,000 and 1,000, km 5 and 1, times 10 and 1. A goal
  already typed is never overwritten.
- The goal and a typed amount go up to 99,999 (was 999). Whole numbers only: no litres or 2.5 km, which would need a
  database change.
- Big numbers get separators ("1,250 of 2,000 ml"), and the +'s label names the unit ("Add 250 ml").

## Not in this change
Rest and Sick days, a habit's own page (demo 2); the Planner's tap on a count habit (demo 4); a coach tip about
tapping the strip; anything outside `lib/features/habits/`.

## Testing
Test-first, each new test seen failing on the old code: the actions write the given day; a row on a picked day shows
and ticks that day; the folds' labels; the strip picks past days only and pages to last week; Back to today; the
editor's unit chips, its fill rule and the 99,999 limits; separators. Then analyze and the full suite. The emulator
try comes with the Tester after the merge.
