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
  - 383 tests pass, 16 of them new: 12 failed first and then passed; 4 guard behaviour that already held (3 passed
    at once; the old-backup one was written after the change, as it needs the new columns). The commit and history
    line say "3 guards"; this line corrects that. Analyze clean.
  - A fast (profile) build from `212f4e3` was made and checked (Uplan's key, debuggable), then replaced: the Tester
    merged its quick-add window into `master` (`b7c92c8`), and the phone gets one fast build from that commit, which
    carries both. Whichever chat Ahmed tells "Phone plugged in" does that one install, his data copied off first;
    afterwards his copied-off database should say schema 26 with the same 77 workouts and 308 sets as today's backup.
  - **Tried for real on a copy of his database** (today's backup, `D:\backups\uplan\2026-11-03-reminders\check`,
    copied to the scratchpad; the original untouched): `tool/migrate_copy_test.dart` upgraded it 25 → 26; every one
    of its 24 tables kept its row count, the workout rows' old columns hash the same, the new columns are empty,
    integrity ok, no foreign-key problems. On that copy the history shows 41 of his 77 workouts (34 have no sets, 2
    only empty rows). Not tried on the emulator (the Tester's was in use) or the phone yet.
- **On his phone since 2026-11-04 17:04** (Ahmed: "Phone plugged in"; the Tester did the one install of `b7c92c8`,
  which also carries its quick-add window; his folder copied first to `D:\backups\uplan\2026-11-04-own-window\`).
  Checked by the Uplan chat on scratchpad copies of that folder's `check\` (before) and `after\` databases: the
  before copy is byte for byte yesterday's backup; after the first start, schema 25 → 26, all 24 tables kept their
  row counts (77 workouts, 308 sets, 35 tasks, 126 notes), the workout rows' old columns hash the same, the new
  columns are empty, integrity ok, no foreign-key problems. On that copy the history shows 41 of 77 workouts, and the
  week's count from Sunday 1 Nov goes 6 → 1 (from Monday it stays 1). The screens on his phone: his eyes only.
- **Next:** his next workout (about 5 Nov) records the first ticks; the one after it is the first smart order that
  learns from them. Then demo 2 (step 5), with 2–3 looks of the history row and workout page first. Demo 2 counts
  logged sets only: 20 empty set rows remain in his workouts that were never finished or discarded.
- **Demo 2 (step 5), built 2026-11-04, look B** (three looks shown as a sketch with his real Push of 3 Nov: A clean
  list, B big number, C the order done; Ahmed: "Look B"):
  - The Workout tab's history row (`lib/features/workout/presentation/widgets/workout_history_tile.dart`, used by
    `workout_home_screen.dart`, whose old row and chips are gone): the kilos lifted big ("5.7 t", "850 kg" under a
    tonne), "Push · Tue, 3 Nov", "19 sets · 4 records", and "11% more than last time" (green) or "8% less than last
    time" (grey). A tap opens `/workout/history/:id`.
  - The workout page (`lib/features/workout/presentation/screens/workout_session_screen.dart`): "5,713 kg" as the
    headline, "lifted · Tue, 3 Nov · started 12:49" plus the length once Finish saved it, a "+578 kg vs last Push"
    chip, the sets and records, then every exercise in the order done (first tick, else opened order), its first
    tick time, each set as a chip (records with a trophy, warm-ups marked W) and its best set's change since last
    time ("+2.5 kg", "+2 reps", "+5 kg, 3 fewer reps" in grey, "new").
  - The rules, pure and tested, in `lib/features/workout/domain/workout_summary.dart`: kilos lifted leave out
    warm-ups and half-filled sets; records count exercises, not sets; an exercise's best set is the heaviest, then
    the most reps; the order-done rule moved here from the DAO (the smart order uses the same function). **"Last
    time" is the most recent workout of the same plan that shares at least 3 in 4 of its exercises** (Claude's call,
    after the emulator showed "308% more than last time" for 31 Oct against a 4-set half-done workout of 27 Sep).
  - The models carry `completedAt` and `finishedAt` now.
  - Not in it: a set's own tick time (the page shows each exercise's first tick, enough for the order).
  - Checked: 28 new tests (each failed first on an empty stub or the old code, except 3 guards: no comparison
    for a plan's first workout in the row and on the page, and no length for a workout left open), 416 pass,
    analyze clean. **Tried on the Flip emulator** (2026-11-04 18:00–18:10) with a fast build of this code and a copy
    of his 4 Nov database: the Workout tab's rows (5.7 t, 11% more than last time; Pull 1 Oct 6% less, grey) and the
    pages of 3 Nov (every exercise in the order opened, its changes at the right edge) and 31 Oct (no comparison)
    look right. The first try showed two faults, both now fixed with a test that failed first: "308% more than last
    time" on 31 Oct (against a 4-set half-done workout) and change labels floating mid-row. To install this build,
    the emulator's own Uplan (signed by the Tester's builds, with made-up data) was saved to the scratchpad
    (`emulator_uplan_before.tar`, 29 files) and replaced. Not on his phone yet.
- **Noticed, not fixing now:** `workout_list_screen.dart` (another history list with the week's count) is built
  nowhere in the app, so `sessionsThisWeek` shows nowhere either; the Workout tab is `workout_home_screen.dart`.
  It could be removed in the gym clean-up.
