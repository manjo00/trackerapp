# Uplan round table: the seats' briefs (Tester chat, 2026-11-01)

You are one seat at a round-table review of **Uplan**, Ahmed's own Flutter Android app: habits, tasks (lists,
reminders, a quick-add sheet), notes (notebooks, checklists, photos), workouts and programs, work shifts, a planner,
custom trackers, a "codex" of tips, coach tips, three home-screen widgets and a live dashboard notification. He uses it
every day on a Samsung Galaxy Z Flip 6 (1080 × 2640 screen, One UI 8 = Android 16). He is **not a programmer**: write
every problem as what he would notice ("the notes list stutters when you scroll past photos"), never as jargon alone.

The Tester chat (Opus) chairs. Its own seat covers speed at start-up and the widget's "+" quick add. It merges all seats
into one ranked list for Ahmed, checks the top findings, and may send you a short second round.

## Rules for every seat
- **Read only.** Never edit, create or delete anything in the repo `D:\projects\trackerapp`. Don't run flutter, dart,
  gradle, adb, installers, or git commands that change anything (`git log` / `git show` are fine). No web access.
- **Never open** `android/key.properties`, or anything under `D:\keys` or `D:\backups` (secrets, Ahmed's personal data).
- **Save tokens.** Start from the code map `graphify-out/GRAPH_REPORT.md` (read its headings first), or ask it from the
  repo root: `python -m graphify query "<question>"`, `python -m graphify explain "<name>"`. Grep before opening a
  file; read big files in slices. Skip generated `*.g.dart` and `*.freezed.dart`. Budget: about 150k tokens of
  reading; near 200k, stop and write up what you have.
- **Be honest.** Mark each finding *checked* (you read the code that does it) or *guess*. Real `file:line` only.
- **Already covered by the chair** (don't spend time here): the widget "+" quick-add path and app start-up
  (`lib/main.dart`, `lib/app.dart`, `MainActivity.kt`, `quick_add_task_screen.dart`,
  `NotificationService.rescheduleAll`, `HomeWidgetService.sync`, the see-through window in `res/values*/styles.xml`).
  Known there: every "+" tap restarts the app behind a see-through window; start-up re-books every reminder while
  the sheet opens; saving waits for a full widget refresh; the whole app renders through Flutter's slower
  see-through (texture) mode.
- **Out of scope** (`CLAUDE.md`): iOS, web, desktop, cloud sync, AI features, theming beyond light/dark Material 3.
  Ideas already in `docs/_Master_Plan.md` under "Parked" may be named only as "parked: <name>".

## What to write
A Markdown file in this folder's `round-table\` subfolder, named after your seat (`product.md`, `looks.md` or
`code.md`): full path
`C:\Users\kille\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_48e18ebc-7554-47c5-9e1a-ac62e7be4fcb\round-table\<seat>.md`.
Up to 15 findings, best first, each in this shape:

```
### <n>. <short title>
- What Ahmed notices: <behaviour, plain words>
- Where: <file:line, …>  (looks seat: also the screenshot file names)
- Fix: <concrete, 1–3 sentences>
- Cost: S (up to 30 min of AI work, a test included) / M (30–90 min) / L (more)
- Gain: <what gets better, roughly how much> (checked / guess)
- Risk: none / low / <what could break or be lost>
```

Then `## Ideas`: at most 5 new features or simplifications that would make his daily use faster or calmer.
Then `## Top 5`: one line each, ranked by gain for the cost.

**Your final reply to the chair:** at most 200 words: the file's path and your Top 5 lines. Then stay available: the
chair may send you the merged list for a second round (agree, disagree, what's missing; at most 150 words).

## Screenshots (seats 1 and 2)
In `round-table\screens\`, listed in `screens\INDEX.md`: each file's device, Android version, light or dark, text
size, and the screen it shows. The emulators hold made-up demo data, never Ahmed's own. Viewing one costs about 1.5k
tokens: choose at most 25 from the index.

---

## Seat 1: Product and flows
Walk through the day as Ahmed lives it: open the app (Today / home), check off habits, add tasks in the app and from
the widget, plan the week (planner, shifts), write a note with a photo and a checklist, run a workout (program →
session → sets → rest timer), log a custom tracker, find something old (search, archive, Recently deleted), change a
setting. For each flow look for: how many taps it takes, what is hidden or confusing, dead ends, missing feedback (undo,
confirmation, "saved"), patterns that differ between features (delete vs archive, sorting, date formats, how editing
starts), settings that should simply be defaults, first-run and empty states, reminders and widgets as a user sees them.
Read: the screenshots; `lib/core/router/app_router.dart` (every screen and how they connect); the screens in
`lib/features/*/presentation/screens/`; `docs/_Master_Plan.md` (built, open, parked); `feedback/app.md` (his own notes).

## Seat 2: Looks
From the screenshots (three screen sizes, two Android versions, light and dark, normal and large text): text cut off or
overflowing, crowded or uneven spacing, misaligned items, a weak hierarchy (everything the same size and weight), poor
contrast (text under about 4.5:1), touch targets under 48 dp, buttons, chips, icons and corner radii that differ from
screen to screen, dark-mode spots with hard-coded colours, stretched or empty layouts on the wide foldable screen, and
content under the status or navigation bar (Android 15 and later draw apps edge to edge). Back each finding with code:
`lib/core/theme/app_theme.dart`, the shared widgets, and greps for hard-coded colours (`Color(0x`, `Colors.`), fixed
sizes and `fontSize:` values. Name the screenshot files that show each problem. Visual fixes get shown to Ahmed as
2–3 options before anything is built, so say where a choice exists.

## Seat 3: Code
Find code that makes the app slow, janky, battery-hungry or fragile, plus untidy code that will cause bugs.
- **Rebuilds:** `ref.watch` of whole lists where `.select` or a smaller provider would do; providers that recompute
  everything on any change; heavy work inside `build()` (sorting, filtering, parsing, date maths over every item);
  `setState` high up in big screens.
- **Database** (Drift: `lib/core/database/`, `lib/features/*/data/`): a query per row in a loop (N+1); whole tables
  loaded and filtered in Dart; missing indexes on columns used in WHERE / ORDER BY / joins (see the table files and
  the migrations in `app_database.dart`); `watch()` streams that re-run big queries on any write; `getAll…` on hot paths.
- **Photos:** his phone holds about 309 note photos, 457 MB (about 1.5 MB each). Look for full-size decoding (no
  `cacheWidth` / `ResizeImage`) in grids, lists and note views, missing thumbnails, memory spikes.
- **Lists:** non-lazy `Column` / `ListView(children:)` over long data, `shrinkWrap` inside scroll views, missing keys.
- **Leaks and battery:** timers, streams, controllers and animation controllers never disposed; periodic work.
- **Fragile or untidy:** errors swallowed so failures go unseen, duplicated logic that can drift apart, dead code,
  unused packages in `pubspec.yaml`.
- **The other home-screen widgets' native code** (not the "+" path): `android/app/src/main/kotlin/com/lifetracker/
  life_tracker/*RemoteViewsFactory.kt`, `MidnightRefreshReceiver.kt`, `LiveDashboardService.kt`: heavy work on the
  main thread, JSON parsed again for every row, updates more often than needed.
