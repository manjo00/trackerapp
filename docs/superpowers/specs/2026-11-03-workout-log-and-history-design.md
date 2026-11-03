# Workout log: what was really done first, no empty workouts, and a history you can open

**Date:** 2026-11-03 · **Status:** approved by Ahmed ("Looks right", 2026-11-03); demo 1 (steps 1–4) built the same
evening, see "Status" at the end · **Chat:** the Uplan chat · **Path:** a short written design first, because it adds
one small database change (his data is copied off before any install, as always).

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
   again), and a workout gets a `finishedAt` time when it's finished. (Correction, 2026-11-03: the ✓ already survived
   leaving the workout screen, because the running workout stays in the app's memory; what is new is that it's
   saved.)
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

## Noticed (not fixing now)
- **A running workout lives only in the app's memory** (read in the code 2026-11-03, not tried on a device):
  `ActiveWorkout.build()` starts empty and nothing reloads an unfinished workout, so if Android closes Uplan in the
  middle of a workout, the workout screen can't continue it. Its logged sets stay, as an unnamed workout in history;
  its opened-but-empty rows stay too (history now hides a workout that has only those). Since v26 a workout without
  `finishedAt` is recognisable, which a later "continue your workout" feature could use.

## Status
- **Demo 1 (steps 1–4), built 2026-11-03 evening, test first:**
  - Schema 26: `workout_sets.completedAt` and `workout_sessions.finishedAt`, both nullable, added in `onUpgrade`
    (`lib/core/database/app_database.dart`). `test/core/database/workout_log_migration_test.dart` opens a real
    version-25 database (the schema from `test/core/database/fixtures/schema_v25.sql`, written by
    `tool/dump_schema_test.dart` before the bump) and checks that it lands on 26 with every row unchanged and the
    new columns empty; a fourth test checks that an older backup's rows still restore.
  - Ticks: `ActiveWorkout.toggleSetComplete` saves the time (or clears it) through
    `WorkoutRepository.setCompletedAt`, and `finishSession` stamps `finishedAt` (`set_ticks_test.dart`).
  - The smart order: `WorkoutDao.recentExerciseOrders` orders each workout by first tick, then the never-ticked
    exercises in the opened order (`recent_exercise_orders_test.dart`, three new tests).
  - Empty workouts: Discard removes a workout with nothing logged (`WorkoutRepository.deleteSessionIfEmpty`); the
    repository's `watchAllSessions` and `getAllSessions` leave out workouts with no logged set, which covers the
    history, Recent Sessions, the Home block and the week's count (`empty_workouts_test.dart`).
  - Step 2's "the ✓ read back" isn't needed: nothing reloads a running workout (see Noticed).
  - 383 tests pass (16 new; each new behaviour test failed first, the 3 guards passed at once); analyze clean.
  - **Tried for real on a copy of his database** (today's backup, `D:\backups\uplan\2026-11-03-reminders\check`,
    copied to the scratchpad; the original untouched): `tool/migrate_copy_test.dart` upgraded it 25 → 26; every one
    of its 24 tables kept its row count, the workout rows' old columns hash the same, the new columns are empty,
    integrity ok, no foreign-key problems. On that copy the history shows 41 of his 77 workouts (34 have no sets, 2
    only empty rows). Not tried on the emulator (the Tester's was in use) or the phone yet.
- **Next:** demo 1 on his phone before his next workout (his data copied first), so his next ticks are recorded;
  then demo 2 (step 5), with 2–3 looks of the history row and workout page first. Demo 2 counts logged sets only:
  20 empty set rows remain in his workouts that were never finished or discarded.
