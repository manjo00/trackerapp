# Round table, seat 2: Looks (Uplan v1.18.0+27 at d3b3165, read 2026-11-01)

How I checked: the four overview sheets, 8 full-size screenshots, and the code (`app_theme.dart` in full, greps over all 216
hand-written Dart files). **Contrast numbers marked "measured" come from pixel samples of the screenshots** (darkest pixel of
the text against its fill; anti-aliasing means about plus or minus 0.2). Numbers marked "calc" come from code colours. Text
needs 4.5:1, icons 3:1. Nothing was built or run. Screenshot names are in `round-table\screens\`.

Reference points in the code: the theme (`lib/core/theme/app_theme.dart`, 108 lines) only styles cards, nav bar, app bar,
FAB and text fields; everything else (chips, segmented buttons, buttons, sheets, dialogs) is styled screen by screen.

### 1. Priority pills (High / Med / Low) are washed out
- What Ahmed notices: the small High / Med / Low pills on every task card are pale text on a pale pill. "Med" is almost
  unreadable. Measured: Med 1.45:1, Low 2.2:1, High 2.4:1. The priority buttons in the New task form are just as pale:
  Low 1.8:1, Med (selected) 1.6:1, High 2.0:1.
- Where: `lib/features/tasks/presentation/widgets/priority_badge.dart:15-27` (text colour = the priority colour, 11 sp);
  `lib/features/tasks/data/models/task_priority.dart:31-33` (slate 0xFF8E9AAF, amber 0xFFFFB347, red 0xFFE07070);
  `_PrioritySelector`, used at `lib/features/tasks/presentation/screens/add_task_screen.dart:603`.
  Screens: `flip-a16-light-home.png`, `flip-a16-light-today.png`, `flip-a16-light-list-work.png`,
  `flip-a16-light-task-add.png`, `fold-a16-light-home.png`.
- Fix: keep the colours as accents but give the text its own darker shade. **Choice for Ahmed (show 3 looks):**
  (A) same pale pill, darker text (amber about #7A4F00, red about #B3261E, slate about #4F5B70); (B) solid pill with white
  text, like the Workout chips; (C) calm: only High gets a pill, Med and Low show nothing (7 of 8 cards lose a pill).
  Use the same choice in the form's priority buttons.
- Cost: S
- Gain: High: on every task card and in the add form (measured).
- Risk: none (low: solid pills look heavier, which is why A or C exists)

### 2. Trackers shows two title bars
- What Ahmed notices: the Trackers tab says "Trackers" in the top bar and again in a second bar under it, wasting about 56 dp.
- Where: `lib/core/router/shell_scaffold.dart:116-120` (the shell already draws one app bar with the tab's name; its own
  comment at :24-25 says tab screens must not add one) against `lib/features/trackers/presentation/screens/trackers_screen.dart:37-38`
  (its own `AppBar(title: Text('Trackers'))`). Screens: `flip-a16-light-trackers.png` (see `sheet-flip-light.png`),
  `small-a13-light-font130-trackers.png`.
- Fix: delete the inner AppBar (check first whether it carries actions at :37-45 that need to move up to the shell).
- Cost: S (about 5 minutes)
- Gain: Low to medium, seen every visit (checked: both lines read; seen on the sheets).
- Risk: none

### 3. Home: cards sit twice as far from the edge, plus an empty row for a faint pencil
- What Ahmed notices: on Home the title starts 16 dp from the edge but the task cards start 32 dp in, so they are narrower
  than the same cards on All tasks or Habits. Under the title a whole 48 dp row holds only a faint grey pencil ("Edit
  Home", 3.0:1 measured), pushing the first task down.
- Where: `lib/features/home/presentation/screens/home_screen.dart:269-270` and `:303` (list padding 16) plus the theme's
  card margin 16 (`app_theme.dart:58`) around `TaskTile` (`home_screen.dart:382`); the same double inset in
  `lib/features/tasks/presentation/screens/list_detail_screen.dart:94-95,109`, while
  `lib/features/habits/presentation/screens/habit_list_screen.dart:59` has none (16 dp). Pencil row:
  `home_screen.dart:218-234` (18 dp icon at 47% opacity). Screens: `flip-a16-light-home.png`, `fold-a16-light-home.png`,
  `flip-a16-light-list-work.png` (against `flip-a16-light-habits.png`).
- Fix: drop the extra 16 dp horizontal list padding in those two screens so every card is 16 dp from the edge. Move "Edit
  Home" out of the content. **Choice:** (A) an icon in the app bar next to the account icon; (B) an entry in a "..." menu;
  (C) keep the row but make it a visible "Edit" text button on the "URGENT" line.
- Cost: S
- Gain: Medium: 16 dp more width on every card, about 48 dp more list on Home (checked in code and on screen).
- Risk: low (Home uses a reorderable list; the long-press drag area shifts by 16 dp)

### 4. The "done" circle on a task is a 24 dp target
- What Ahmed notices: ticking off a task means hitting a 24 dp circle. A slightly missed tap opens the task's detail sheet
  instead. (Habits are fine: the whole habit card toggles.)
- Where: `lib/features/tasks/presentation/widgets/task_tile.dart:64-85` (24 by 24 circle inside its own GestureDetector;
  the rest of the card opens `showTaskDetailSheet` at :56). Same pattern, not opened: `today_screen.dart:497` (22 dp) (guess).
  Screens: `flip-a16-light-home.png`, `flip-a16-light-list-work.png`.
- Fix: keep the look, wrap the circle in an invisible 48 by 48 hit area (opaque behaviour) and trim the neighbouring padding
  so nothing moves. Alternative or addition: swipe right to complete (see Ideas).
- Cost: S
- Gain: Medium: it is his most frequent tap (checked in code; the real miss rate is a guess).
- Risk: low (the bigger area overlaps the card's own tap; the circle must win)

### 5. Grey helper text is too faint almost everywhere
- What Ahmed notices: the grey second lines and labels are hard to read, especially in sun. Measured: card subtitle "Details
  in the shared folder" 2.4:1, list-name label 2.7:1, weekday letters in the planner 3.0:1, "No due date" 2.9:1, "Working /
  Free" tiles 3.6:1.
- Where: `onSurface.withAlpha(...)` is used 190 times in `lib/`; 159 of them are at 150 or lower (most common: 140 x39, 120
  x36, 150 x21, 160 x18). Examples: `habit_tile.dart:86`, `add_task_screen.dart:784,790`, `shift_month_calendar.dart:465`,
  `codex_screen.dart:91,165`, `home_screen.dart:226`. Material's own secondary-text colour `onSurfaceVariant` is used only 20
  times, and `app_theme.dart` defines no text roles. Screens: `flip-a16-light-home.png`, `small-a13-light-font130-planner.png`,
  `flip-a16-light-task-add.png`, `flip-a16-light-codex.png`.
- Fix: add one "secondary text" colour (and one weaker "hint" colour for decoration) next to the theme, then replace the
  120-150 spots with it. **Choice:** (A) everything secondary uses `onSurfaceVariant` (strongest, about 8:1, guess); (B) a
  middle grey at alpha about 175 (about 5:1, calc); (C) fix only the ten busiest screens first.
- Cost: M (mechanical, about 100 edits, then a screenshot pass in light and dark)
- Gain: High for readability on every screen (measured on 6 spots, counted in code).
- Risk: low (less "soft" look; check dark mode again)

### 6. Dark mode: the shift calendar glows and its legend vanishes
- What Ahmed notices: in dark mode the Work schedule's Day and Night cells are bright pastel tiles on a near-black page, and
  the legend words "Day" and "Night" are dark text on a dark page (2.2:1 and 1.5:1, measured: nearly invisible). The Planner's
  week strip shows the same bright discs.
- Where: `lib/features/shifts/presentation/shift_style.dart:17-24` (hard-coded light fills 0xFFDEEDEF / 0xFFD7DBEC with dark
  foregrounds, no brightness check) used by `shift_month_calendar.dart:174-181,276-297`, `day_column.dart` (5 uses),
  `home/presentation/widgets/shift_block.dart` (4), `shift_picker_sheet.dart` (2), `day_time_grid.dart` (1). Another
  hard-coded `Color(0xFFF4511E)` at `shift_month_calendar.dart:362`. Screens: `flip-a16-dark-shifts.png`,
  `flip-a16-dark-planner.png` (thumbnail on `sheet-flip-dark.png`; the planner is checked in code, not at full size).
- Fix: make the shift colours depend on the theme. **Choice:** (A) dark tints of the same hues in dark mode (deep teal and
  indigo fills, light text; recommended); (B) outline-only cells in dark; (C) keep bright tiles and fix only the legend.
- Cost: S to M (one file for the colours, then a look at five screens)
- Gain: Medium to high if he uses dark mode at night (how often is a guess); the legend bug is checked.
- Risk: low

### 7. Some text is tiny
- What Ahmed notices: the "+N" next to the dots under each day in the planner's week strip is a speck, the small red count
  badges and the labels inside calendar cells are very small, and many captions are 11 sp.
- Where: `lib/features/planner/presentation/widgets/day_column.dart:270` (5 sp), `:149,186` (9 sp);
  `shift_month_calendar.dart:356` (8.5 sp, a label inside a cell); 7 uses of 10 sp (`coach_overlay.dart:197`,
  `active_workout_screen.dart:490`, `muscle_targets_editor_screen.dart:162`, `exercise_accordion_card.dart:245`,
  `weekly_scoreboard_card.dart:141`); 20 of 11 sp (`note_grid_card.dart:102,112`, `priority_badge.dart:27` and others),
  plus `labelSmall` (11 sp) used 19 times. Screens: `small-a13-light-font130-planner.png`, `flip-a16-light-planner.png`,
  `flip-a16-light-notebook-personal.png` (captions).
- Fix: floor of 11 sp for labels and 12 sp for anything he needs to read. Replace the 5 sp "+N" with a clear "3+" at 11 sp or a
  small icon. **Choice:** (A) apply the floor everywhere; (B) fix only the week strip and calendar cells.
- Cost: S to M
- Gain: Medium (checked in code; at his 1.0 text size the 5 sp text is below readable)
- Risk: low (the week strip cells must grow a few dp; check at text size 1.3)

### 8. Light mode mixes warm cream with cold lavender
- What Ahmed notices: in light mode the page is cream and cards are beige, but text fields, chips and selected buttons pick up
  a cold lavender. The New task form shows lavender fields above beige date buttons. Dark mode has no such clash.
- Where: `app_theme.dart:30-39` overrides only four light surfaces; `surfaceContainerHigh` and `Highest` stay the seed's
  lavender, while dark overrides them at `:22-23`. The text-field fill uses `surfaceContainerHigh` (`:96`). Screens:
  `flip-a16-light-task-add.png`, `small-a13-light-font130-workout.png` (lavender program card).
- Fix: two lines in `light()`. **Choice:** (A) warm greys for High and Highest (matches dark, recommended); (B) keep lavender as
  the brand tint, but then make cards and date buttons lavender too.
- Cost: S
- Gain: Low to medium (a calmer look; guess how much he notices)
- Risk: low (many widgets use High; one pass over the screens)

### 9. Done habits are struck through and dimmed
- What Ahmed notices: with 5 of 8 habits done, the Habits screen looks crossed out. A done name is struck through and dimmed
  to about 3.3:1 (calc). In the Planner the strike line is drawn black through grey text, a harsher look than on Habits.
- Where: `lib/features/habits/presentation/widgets/habit_tile.dart:83-87` (line-through plus `withAlpha(130)`). Screens:
  `flip-a16-light-habits.png`, `flip-a16-light-planner.png`, `small-a13-light-font130-planner.png`.
- Fix: **Choice:** (A) no line: filled check circle plus lightly dimmed name (calm, recommended); (B) keep the line, darken
  the text (alpha 170 gives about 5:1, calc); (C) leave it.
- Cost: S
- Gain: Low to medium
- Risk: none

### 10. Buttons, chips, corners and section headers drift from screen to screen
- What Ahmed notices: similar things look different. The New task form has lavender filled fields, beige outlined date
  buttons and pale outlined priority buttons, all with different corners. The same Push / Pull / Legs chips look different in
  the program card and in "This Week", in saturated red, blue and green next to the soft lavender palette. Section headers
  are tiny uppercase letters on most screens (Home, Planner, Settings, Notes) but large bold words on Workout ("This Week",
  "My Workouts", "Recent Sessions").
- Where: `app_theme.dart:52-105` has no chip, segmented-button, button, bottom-sheet, dialog or snackbar theme; corner
  radii take 11 different values (2, 3, 4, 6, 8, 9, 10, 12, 14, 16, 20; the most used are 12 x22, 20 x21, 16 x14, 10 x12,
  14 x10) and icon sizes 14 different values; hand-styled in `add_task_screen.dart:719,770,776`; workout colours probably in
  `workout/presentation/widgets/weekly_scoreboard_card.dart` and `week_attendance_strip.dart` (guess). Screens:
  `flip-a16-light-task-add.png`, `small-a13-light-font130-workout.png`, `flip-a16-light-workout.png`.
- Fix: add chip, segmented-button, button, sheet and dialog themes with two corner sizes, then move the worst screens first
  (task form, Workout). **Choice for corners:** (A) soft: 12 for controls, 20 for cards and sheets (today's most common
  values, recommended); (B) squarer 8 / 12; (C) rounder 16 / 28. Same decision for headers: small caps or large bold.
- Cost: M to L (L if every screen is moved)
- Gain: Medium: calmer look, and every later screen starts consistent (checked counts; the visual effect is partly a guess).
- Risk: low to medium (touches many screens; needs a before and after screenshot pass)

### 11. Wide (unfolded Fold or tablet) screens just stretch
- What Ahmed notices: on a 707 dp wide screen the task title sits at the far left and the priority pill at the far right, the
  three bottom tabs are spread far apart, and the shift calendar's cells become 107 dp squares with tiny numbers, so the
  Working / Free tiles fall below the fold. **This does not affect his Z Flip 6** (its open screen is a tall phone, 411 x
  1006 dp); it matters only on a Fold or a tablet (guess: he does not run Uplan on the Tab S9 Ultra).
- Where: no maximum width anywhere: `MaxCrossAxisExtent` 0 uses, `LayoutBuilder` only at `home_screen.dart:263` and
  `day_time_grid.dart:51`; fixed column counts at `notebook_detail_screen.dart:94`, `shift_month_calendar.dart:218` (7 columns,
  square cells), `add_tracker_screen.dart:178`; bottom bar always at `shell_scaffold.dart:135`. Screens:
  `fold-a16-light-home.png`, `fold-a16-light-shifts.png`, `fold-a16-light-lists.png`, `fold-a16-light-notes.png`.
- Fix: **Choice:** (A) centre all content in a column of at most about 600 dp, one wrapper in the shell (S to M); (B) a side
  rail instead of the bottom bar plus list-and-detail panes above 840 dp (L); (C) skip while he has no wide device
  (recommended unless he plans Uplan on the tablet).
- Cost: S to M for A, L for B
- Gain: none on the Flip today (guess), high on a Fold
- Risk: low

## Checked and fine (so nobody spends time here)
- **Edge to edge (Android 15 and later):** no content hides under the status or navigation bar in the 65 screenshots; the nav
  bar's colour runs under the gesture bar on Android 16. One exception, probably a first-frame glitch: the status-bar clock
  and icons are white on cream in `fold-a16-light-home.png` (1.03:1 measured; the next-worst shot is `flip-a16-light-first-launch.png`
  at 2.1:1). The code never sets the status bar style (`SystemChrome` 0 uses; it relies on the AppBar default), so a cold start
  may flash white icons for a moment (guess; the chair can check on a real cold start).
- **The button hiding the last list item:** 21 lists have 72-140 dp bottom padding. Fine.
- **Small touch targets:** 15 `VisualDensity.compact` buttons and chips keep Flutter's 48 dp tap area (only one `shrinkWrap`,
  `task_detail_sheet.dart:167`). Only the task circle (finding 4) is a real small target.
- **Large text (1.3):** I opened planner, shifts and workout at 1.3 and found no cut-off text; the quick-add chip row scrolls sideways.
- **Missing tracker title in `flip-a16-light-tracker-routine.png`:** an artefact of opening the route cold. The name comes
  through `extra` (`tracker_detail_screen.dart:61-66`; passed at `trackers_screen.dart:65-72`). A deep link would show no name.
- **Maybe for seat 1:** the form's "Add" button is a `FilledButton` inside the scrolling form (`add_task_screen.dart:714`), so
  the keyboard hides it while typing (guess; not run).

## Ideas
1. **Swipe right to complete a task** (swipe left already archives). Faster than aiming at a 24 dp circle, and it solves finding 4 twice.
2. **Priority pill for High only**, or a thin coloured stripe on the card's left edge: calmer lists than 7 pills out of 8 cards.
3. **Collapse finished items under a "Done (5)" line** on Habits and lists instead of striking them through (pairs with finding 9).
4. **Put "Edit Home" in the app bar** (or a "..." menu) and show the date in the Home title, like the Today screen does.
5. **One style sheet in `app_theme.dart`** (text roles, status colours, two corner sizes, component themes) so new screens are consistent and dark-safe from the start.

## Top 5 (gain for the cost)
1. Priority pills and priority buttons: readable text (finding 1, S).
2. Remove Trackers' second title bar (finding 2, S, about 5 minutes).
3. Home and list cards: one 16 dp edge margin, and move the faint pencil (finding 3, S).
4. Make the task "done" circle a 48 dp target (finding 4, S).
5. One secondary-text colour instead of 159 faint greys (finding 5, M); right behind it, dark-mode shift colours and legend (finding 6, S to M).
