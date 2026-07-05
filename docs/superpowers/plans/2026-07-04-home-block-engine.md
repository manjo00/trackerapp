# Home Block Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Customizable Home dashboard — ordered/removable blocks (existing four + Workout), long-press drag reorder, Edit Home screen, startup-tab setting — per spec `docs/superpowers/specs/2026-07-04-home-block-engine-design.md`.

**Architecture:** Layout = ordered list of `HomeBlockType` names in SharedPreferences (`home_blocks`), managed by `SettingsNotifier` exactly like `visible_tabs`. HomeScreen renders enabled blocks through a `ReorderableListView` (long-press drag on headers); EditHomeScreen gives full add/remove/reorder. The Workout block reuses the Workout-home suggested-session flow + an extracted week-attendance strip. Startup tab feeds `GoRouter(initialLocation:)` via a top-level variable set in `main()` before the lazy router global is first touched.

**Tech Stack:** Flutter 3.44 · Riverpod (manual StateNotifier settings) · SharedPreferences · go_router.

## Global Constraints

- No schema/DB changes in this slice (storage = preferences only).
- Default layout `[urgent, dueToday, captured, thisWeek, workout]`; unknown names dropped, duplicates collapsed, empty list allowed.
- De-dupe of tasks across blocks follows the USER'S block order (first block top-down claims the task).
- `flutter analyze` clean before every commit; conventional commits; tests for pure logic.

---

### Task 1 — Block model + settings plumbing (+ startup tab setting)

**Files:**
- Create: `lib/features/home/data/home_block_type.dart`
- Modify: `lib/core/settings/app_settings.dart` (add `homeBlocks`, `startupTab`)
- Modify: `lib/core/settings/settings_provider.dart` (keys `home_blocks`, `startup_tab`; load/parse; `setHomeBlocks`, `setStartupTab`)
- Test: `test/features/home/home_block_type_test.dart`

**Interfaces produced:**
- `enum HomeBlockType { urgent, dueToday, captured, thisWeek, workout }` with `String get label`, `IconData get icon`, and `static List<HomeBlockType> parse(List<String>? raw)` (drops unknowns, collapses duplicates preserving first occurrence, null/garbage-only → `defaults`), `static const List<HomeBlockType> defaults`.
- `AppSettings.homeBlocks: List<HomeBlockType>`, `AppSettings.startupTab: AppTab` (default `AppTab.home`).
- `SettingsNotifier.setHomeBlocks(List<HomeBlockType>)`, `SettingsNotifier.setStartupTab(AppTab)`.

- [ ] Step 1: failing test — parse: `['workout','urgent']` keeps order; `['bogus']`→defaults? NO: `['bogus']` → `[]`?? Spec: unknown names dropped; if raw is null → defaults; if raw non-null → parsed result (may be empty = all blocks removed). Duplicates `['urgent','urgent']` → `[urgent]`. Test all three + defaults content.
- [ ] Step 2: run → FAIL (missing file).
- [ ] Step 3: implement enum + parse; wire settings fields/keys (mirror `visibleTabs` load pattern; store via `.name`). startupTab load: match `AppTab.values` by name, fallback `AppTab.home`.
- [ ] Step 4: `flutter test test/features/home/` → PASS; analyze clean.
- [ ] Step 5: Commit `feat(home): block model + layout/startup-tab settings`.

### Task 2 — Week-strip extraction + Workout block widget

**Files:**
- Create: `lib/features/workout/presentation/widgets/week_attendance_strip.dart` — move `_WeekStrip` (workout_home_screen.dart:329-…) verbatim, rename `WeekAttendanceStrip({required ProgramModel program, required Set<int> loggedIds})`; also move the private `_loggedThisWeek(sessions, {required bool sundayStart})` helper here as public `loggedThisWeek(...)`.
- Modify: `lib/features/workout/presentation/screens/workout_home_screen.dart` — delete the private copies, import the new widget file.
- Create: `lib/features/home/presentation/widgets/workout_block.dart` — `WorkoutBlock extends ConsumerWidget`: watches `activeProgramProvider`/`todaysSuggestedSessionProvider`/`workoutSessionsProvider` (same providers Workout home uses — copy exact names from workout_home_screen.dart imports); renders header ("WORKOUT", fitness icon, secondary color, same `_HomeBlock` header style), a card with suggested-session name + FilledButton "Start"/"Resume" (Resume when `activeWorkoutProvider` has an in-progress session → `context.push('/workout/active')`; Start reuses the exact start logic from Workout home's Train button — extract that method into `lib/features/workout/presentation/workout_actions.dart` as `Future<void> startProgramSession(BuildContext context, WidgetRef ref, ProgramSessionModel session)` and call it from BOTH call sites), then `WeekAttendanceStrip`. When no active program: single "Open Workout →" tile → `context.go('/workout')`.

**Interfaces produced:** `WorkoutBlock()` const widget; `WeekAttendanceStrip`; `startProgramSession(...)`.

- [ ] Steps: extract strip + actions (verbatim moves, no behavior change) → analyze clean → build WorkoutBlock → analyze → Commit `refactor(workout): share week strip + start action; feat(home): workout block widget`.

### Task 3 — HomeScreen reorderable rendering + Edit Home screen

**Files:**
- Modify: `lib/features/home/presentation/screens/home_screen.dart` — render `settings.homeBlocks` order: build a `List<Widget>` of enabled block widgets (each keyed `ValueKey(type)`), body = `ReorderableListView(buildDefaultDragHandles: false, onReorder: …setHomeBlocks(reordered), children: …)`; each block's header wrapped in `ReorderableDelayedDragStartListener(index: i, child: header)`. Task de-dupe: iterate the user's order — urgent set → dueToday minus shown → captured minus shown (This week + Workout never consume ids). "All clear" only when every ENABLED task block is empty (workout block excluded from the check; if layout is empty show All-clear + hint "Add blocks with ✎"). Add a small ✎ IconButton row at the top (aligned right) → `Navigator.push(MaterialPageRoute(builder: (_) => const EditHomeScreen()))`.
- Create: `lib/features/home/presentation/screens/edit_home_screen.dart` — Scaffold(AppBar 'Edit Home'): `ReorderableListView` of enabled blocks (ListTile: drag_handle icon + block icon + label, trailing remove_circle_outline → setHomeBlocks(without)) + section header "ADD BLOCK" + tiles for `HomeBlockType.values` not enabled (leading add_circle_outline → setHomeBlocks(current + type)). Live writes, no save button.

- [ ] Steps: implement both → analyze → `flutter test` (all pass) → Commit `feat(home): reorderable blocks + Edit Home screen`.

### Task 4 — Startup tab

**Files:**
- Modify: `lib/core/router/app_router.dart` — top-level `String appInitialLocation = '/home';` and use it: `GoRouter(initialLocation: appInitialLocation, …)`; bare-`/` redirect returns `appInitialLocation`.
- Modify: `lib/main.dart` — after `prefs` resolves, before `runApp`: read `startup_tab` + `visible_tabs`; if startup name is in AppTab values AND (visible_tabs is null → default set contains it, else stored list contains it) set `appInitialLocation = '/<name>'` else first-visible fallback (`'/home'` when default set). Import app_router.
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart` — Navigation tabs section: "Open at launch" row (InputDecorator + DropdownButton<AppTab> over `settings.visibleTabs` sorted by index, value = `settings.startupTab` if visible else first visible) → `notifier.setStartupTab`.
- Test: extend `test/features/home/home_block_type_test.dart` is unrelated — instead add `test/core/startup_tab_test.dart`: pure function extracted to `lib/core/settings/startup_tab.dart`: `String startupLocation({String? storedTab, List<String>? storedVisibleTabs})` returning `'/x'`; cases: null→'/home'; stored 'workout' visible → '/workout'; stored 'workout' NOT visible → first visible; stored garbage → '/home'. main.dart + router use this function.

- [ ] Steps: failing test → implement `startup_tab.dart` → PASS → wire main/router/settings UI → analyze → Commit `feat(nav): startup tab setting`.

### Task 5 — Verify + ship

- [ ] `flutter analyze` + full `flutter test` → all green.
- [ ] Build release, install on the Flip 6, device pass: reorder via long-press; remove/add via Edit Home; workout block Start/Resume; startup tab honored after force-stop relaunch.
- [ ] CLAUDE.md: feature-table row (Home block engine v1 + startup tab); version `1.3.1+6 → 1.4.0+7`.
- [ ] Commit `feat(home): block engine v1 — docs + version` → push. Release v1.4.0 with the user.

## Self-review
- Spec coverage: catalog+defaults (T1), workout block (T2), reorder+edit both surfaces (T3), startup tab incl. fallback (T4), device pass + docs (T5). ✓
- No placeholders; interfaces named consistently (`setHomeBlocks`, `HomeBlockType.parse`, `appInitialLocation`, `startupLocation`). ✓
- Note: Task 1 Step 1 wording fixed inline — `['bogus']` parses to `[]` (all unknown dropped); only a NULL raw list yields defaults.
