# Workout log: what was really done first, no empty workouts, and a history you can open

**Date:** 2026-11-03 · **Status:** waiting for Ahmed's yes · **Chat:** the Uplan chat · **Path:** a short written
design first, because it adds one small database change (his data is copied off before any install, as always).

## What Ahmed asked (2026-11-03, his words)
- "does the app log when exercises are done and checked? ... the gym was a little busy i had to do them a little out
  of the smart tool order, my question is does the app know what i did first? ... if no then it should, if yes, it
  should take that into consideration and scoring."
- "also excluded workout still show in history it shouldn't."
- "history of workouts should have details about total sets, volume, and anything interesting and can be pressed for
  more details on exactly all sets and their data. this helps also with the snapchat idea."

## What the app does today (checked in the code and in his 2026-11-03 backup copy, read only)
- Opening an exercise makes its set rows, and the order of those rows is the only record of the order. The ✓ on a
  set lives only in the workout screen's memory (`ActiveWorkoutState.completedSetIds`, "runtime-only"): nothing about
  it is saved.
- So the smart order learns the order he *opened* the exercises in (each exercise's first filled set). That is right
  when he opens each exercise as he starts it, and wrong when he opens one early just to look.
- Today's Push (workout #77, 19 sets) is recorded as: Leg Press, Shoulder Press, Technogym Upper Back Row, Lat
  Pulldown, Incline Chest Press, Techno Pectoral, Overhead Tricep Extension, Preacher Curl, Leg Extension, Leg Curl.
- Discard keeps the workout as an unnamed entry (only its empty sets are removed). His history holds 46 unnamed
  workouts, 30 of them with no sets at all (five from 1 Nov, #72–#76). They show in the history lists, and the week's
  count (`sessionsThisWeek`) counts every workout in the week, empty or not.
- A past workout's row shows its name, date, exercise chips, 🏆 and "N sets"; tapping it does nothing. The full
  summary (time, kg lifted, records, top sets) exists only in the sheet shown right after Finish
  (`workout_summary_screen.dart`), and the workout's length isn't saved anywhere.

## The change
1. **Ticks are saved with their time.** A set gets a `completedAt` time when its ✓ is tapped (cleared when tapped
   again), and a workout gets a `finishedAt` time when it's finished. Ticks then also survive leaving and reopening
   the workout screen.
2. **The smart order learns from what was finished first.** An exercise's place is the time of its first ticked set.
   Exercises with no ticked set, and every workout from before this change, keep the opened order, after the ticked
   ones.
3. **Empty workouts leave history.** Discard on a workout with nothing logged removes it. History, Recent Sessions
   and the week's count skip workouts with no logged sets, so the 30 old empty ones vanish from view; nothing is
   deleted from the database. A discarded workout that has logged sets stays, because those sets are real training
   (his call if he wants otherwise).
4. **A history you can open.**
   - Each row: the date, the name, total sets, total kg lifted (each set's weight × reps, added up; warm-up sets left
     out), the workout's length when known, and its new records (🏆 and how many).
   - Tapping a row opens a workout page: the same numbers on top, a few highlights (more or less kg than the last
     time of the same workout, the new records, the heaviest set), then every exercise in the order done, with every
     set: weight × reps, record, warm-up, and the time it was ticked.
   - These are the numbers a later Snapchat sticker would show.

## The database change (schema 25 → 26)
Two empty-by-default (nullable) columns are added: `workout_sets.completedAt` and `workout_sessions.finishedAt`.
Nothing is removed or rewritten, and old rows keep them empty. A migration test opens a version-25 database with data
in it and checks that every row survives and the new columns are empty. Old backups still restore as far as these
two columns go (a missing value means empty). Before the install on his phone, his data is copied off first
(signing-key plan, Task 4), as every install does.

## Steps (test first)
1. The migration and its test.
2. Saving and clearing a set's tick time; the ✓ state read back from it.
3. The smart order's history read by tick time, with the opened-order fallback.
4. Empty workouts: removed on Discard, skipped by history and the week's count.
5. The history row's numbers and the workout page.
6. All tests, the code checker, a fast (profile) build with the fingerprint check; a try on the emulator (one at a
   time, shared with the Tester): a workout ticked out of order, then the next smart order, a discard, the workout
   page; then on his phone with his OK, screens only (starting a workout there adds a real entry).

Built in two demos: first steps 1–4 (the log, the smart order, the empty workouts), then step 5 (the history).
Size (a guess): about 1.5–2.5 hours of Claude's work in all, then about 15 minutes of tests and builds; about 350k
tokens; no helpers. Past twice that, stop and ask.

## Not in this change
- The gym clean-up (`docs/superpowers/specs/2026-11-01-gym-cleanup-design.md`, on hold).
- The Snapchat sticker (it will reuse the workout page's numbers).
