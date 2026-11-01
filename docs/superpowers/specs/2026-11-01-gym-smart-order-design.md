# Gym smart order (and the weekly cardio sketch): design

**Date:** 2026-11-01 · **Status:** waiting for Ahmed's yes · **Path:** demo first (no database change, so nothing
can be lost); the progress dashboard gets its own full design later.

## What Ahmed wants (his words, condensed)
- His new split: a whole-body warm-up, then 1 working set per exercise, every other day. Goal: strength and muscle
  equally, "in casual manner not tryhard".
- He tires toward the end, so the app reorders the exercises each time from his last 2–3 workouts (his pick: the
  tired score, over a simple rotation and a fixed fair cycle).
- Mix the muscles up so he rests less ("chest - shoulders - triceps" back to back wastes rest time); next to each
  other only as a last resort.
- Triceps after the chest and shoulder presses, biceps after pulldowns and rows: reaching failure on a helper muscle
  early weakens the big lifts.
- A cardio day once a week, as a switch.

## What his history shows (the 2026-11-01 backup copy, read only, counts only)
- Mostly machines (Technogym), plus a Smith-machine incline press, a dumbbell overhead triceps extension and a barbell
  preacher curl. Barbell bench press not since 2026-07-23.
- Most logged: Lat Pulldown (15 workouts), Shoulder Press (14), Technogym Upper Back Row (13), Preacher Curl (12),
  Bench Press (12), Overhead Tricep Extension (11), Incline Chest Press (10), Techno Pectoral (9). Legs rarely: Leg
  Curl 4, Leg Extension 3, Leg Press never logged.
- Usual reps about 8 (10–12 on the pulldown and leg extension). He already puts arms last (the triceps extension was
  always last, the preacher curl late).
- No effort scores or warm-up sets ever logged.
- His custom machines list no helper muscles (Incline Chest Press: Chest only; Shoulder Press: Shoulders only; Upper
  Back Row: Back only). So the rules below use the family of the main muscle, never the helper lists.
- His saved list `my_workouts` / "Push" is already full body (10 exercises): Techno Pectoral, Shoulder Press, Incline
  Chest Press, Overhead Tricep Extension, Leg Press, Leg Extension, Lat Pulldown, Technogym Upper Back Row, Technogym
  Biceb Curl Machine, Preacher Curl.

## How the smart order works
**Families**, from the main muscle, using the app's own muscle groups (`muscle_groups.dart`):
- Push: Chest, Shoulders, Triceps · Pull: Back, Lats, Biceps, Forearms · Legs: Legs, Quads, Hamstrings, Glutes,
  Calves · Core: Core. Any other muscle is a family of its own and has no order rule.
- **Helpers:** Triceps come after every Chest and Shoulders exercise; Biceps and Forearms after every Back and Lats
  exercise; Core after every Legs, Back and Lats exercise (a tired core makes heavy lifts less steady; standard advice,
  added by Claude).

**The waiting list** (the rotation):
1. Read his last 3 workouts of this same planned workout, newest first, in the order he really did them: an
   exercise's place is its first filled set (set rows are made when an exercise is opened; empty rows don't count).
2. For each non-helper exercise, its *wait* = how many of those workouts in a row it went without an early slot (the
   first third of that workout's list). Longest wait first. Tie: the one done later in the newest workout goes first,
   and a skipped one counts as later than last. Still tied: the plan's order. An exercise found in none of the 3
   workouts gets the longest wait.
3. Helpers come after all non-helpers in the waiting list, ordered the same way among themselves.
4. No history at all (the first workout): the plan's order.

A plain "late goes first" score was rejected: the first and last exercises swap each time and the middle ones stay in
the middle forever. With the wait, if he follows the order, every non-helper exercise gets an early slot about once
every 2–3 workouts.

**The rules:**
- Helpers after their family's big exercises: a hard rule, never broken.
- Mix them up: two exercises of the same family never next to each other, unless no order can avoid it, and then as
  few times as possible.
- Among the orders that keep both rules, pick the one closest to the waiting list (the smallest total shift of the
  exercises from their place in it).
- The search checks every order (a subset search; 10–12 exercises take milliseconds), so an early choice never
  corners it.

**One possible result** for his saved list plus a leg curl: Techno Pectoral, Lat Pulldown, Leg Press, Incline Chest
Press, Upper Back Row, Leg Extension, Shoulder Press, Biceps Curl Machine, Leg Curl, Overhead Tricep Extension,
Preacher Curl. Push, pull and legs take turns, and the arms come after their presses and rows.

## What he sees
- A "Smart order" switch on the planned workout, in its editor (off by default).
- Starting it from any Start button: the list arrives in the smart order with up to two lines on top: "Leg Press and
  Row first: their turn for a fresh start." and "First up: Leg Press. One light set first." (the whole-body warm-up
  doesn't prepare the first heavy set, which now changes each time).
- He can still do any exercise in any order; the app learns from what he really did.
- If reading the history fails, the plan's order is used, and nothing crashes.

## How it's built (demo first)
- New pure rules file `lib/features/workout/domain/smart_order.dart` and its tests
  `test/features/workout/smart_order_test.dart`, test first.
- Small edits: `workout_dao.dart` (read the last 3 workouts of one planned workout), `workout_repository.dart`,
  `workout_providers.dart` (`ActiveWorkout.start` applies the order when the switch is on; all five Start buttons go
  through it), `program_session_editor_screen.dart` (the switch), `active_workout_screen.dart` (the two lines).
- The switch is saved in the app's settings (shared_preferences), like the Targets-mode switch: no database change.
  The app's backup leaves settings out, so after a reinstall he flips it on again.
- No new package.
- Checks: the rule tests (the rotation over 6 simulated workouts, helpers last, mixing, last-resort neighbours,
  skipped and new exercises, no history), the full test suite and the analyzer, then one real try (start the workout
  twice and see the order move), on the phone with his OK or on the Tester's emulator.
- The Tester chat shares this folder: it hears which files this touches before the build starts.

## Weekly cardio (next, after the smart order; a sketch to confirm with Ahmed)
- A "Weekly cardio" switch, off by default.
- When on, a small card, "Cardio this week: 20–30 min", shows on any day without a gym workout until he logs one that
  week. Any rest day, not a fixed weekday, because every-other-day gym days drift across the week (Mon, Wed, Fri, Sun,
  Tue, ...).
- Logging in two taps: the type (bike, incline walk, run, other) and the minutes. The database already has a minutes
  field (`workout_sets.durationSeconds`), but no screen uses it yet.
- The science: once a week barely touches strength or muscle gains; cycling and walking interfere less than running
  (Wilson et al. 2012; the 2022 review found the running effect only in slow-twitch fibres); do it on a rest day or
  after weights. Health guidelines (WHO) ask for 150+ minutes of moderate activity a week, which daily walking can
  cover (not checked today).

## Problems he might have missed (the brainstorm)
1. **His machines don't list helper muscles**, so a rule built on them would think the incline press doesn't use the
   triceps. Solved above: families from the main muscle.
2. **The legs lean to the front of the thigh:** his saved full-body list has the leg press and the leg extension but
   no leg curl (the back of the thigh), which sits in his Pull list. Suggest adding Leg Curl for balance (standard
   advice).
3. **The cost of his helper rule:** the arms always land in the second half, so the rotation moves chest, shoulders,
   back and legs. The arms still get work from every press and row.
4. **The numbers will depend on the slot:** once the order rotates, an exercise done late shows fewer reps, so the
   day-to-day numbers jump. The dashboard must allow for the slot (his own "tired penalty"), or it will call a tired
   day "getting weaker".
5. **The first exercise changes each time** and needs one light set first: the "First up" line.
6. **One set only works when it's hard enough and the weight creeps up:** stopping 1–2 reps before he can't do
   another is plenty; much easier than that and gains slow (from what Claude knows, not checked today). Later: a
   "today's target" hint (the same weight and one more rep, or the next weight step at the top of his range).
7. **History is tied to the exact exercise name:** a rename splits it, and "Technogym Biceb Curl Machine" (spelled
   with a b) has never been logged. The dashboard should offer to merge duplicates.
8. **Weekly sets per muscle** (this corrects the earlier guess of 3–4): with his saved list, chest, back, biceps and
   the front of the thigh get about 7 direct sets a week; shoulders, triceps and (with a leg curl) the back of the
   thigh about 3.5, plus help from the presses and rows (Claude's sum, not checked).
9. **Cardio day drift:** solved in the sketch above (any rest day).

## Ideas for later (not in this build)
- A shorter rest timer when the next exercise uses other muscles (the time his mixing rule saves).
- Pin an exercise early: only matters for heavy free-weight lifts, and he mostly uses machines.

## Sources
- Nunes et al. 2021, exercise order: strength grew most on the exercises done first; muscle growth was similar in
  either order. https://pubmed.ncbi.nlm.nih.gov/32077380/
- 2016, Journal of Sports Science and Medicine: triceps pushdowns before the bench press cut the bench press reps.
  https://www.jssm.org/jssm-15-111.xml-abst
- Wilson et al. 2012 (summarised in) and Schumann et al. 2022, cardio and lifting together:
  https://pmc.ncbi.nlm.nih.gov/articles/PMC9474354/
- Stronger by Science on one set per exercise: https://www.strongerbyscience.com/one-set-muscle/
