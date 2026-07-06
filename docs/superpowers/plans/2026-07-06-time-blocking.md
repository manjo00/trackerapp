# Time Blocking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optional task time ranges (`durationMinutes`, schema v12) + an enhanced Planner day view with a List ⇄ Grid switch, ⋮ filters/default-view menu, and a 24-hour grid — per spec `docs/superpowers/specs/2026-07-06-time-blocking-design.md`.

**Architecture:** One nullable column on tasks; end time always computed (`dueTime + duration`) so rescheduling moves the whole block. Pure helpers (`time_block_utils.dart` for range math, `day_grid_layout.dart` for grid geometry/overlap columns) carry the tested logic; `DayDetailView` grows a header (switch + ⋮) and delegates to the existing list or the new `DayTimeGrid`. Default view persists via `AppSettings.plannerDayView`; filters are per-visit state.

**Tech Stack:** Flutter 3.44 · Drift 2.28 (`m.addColumn` only) · Riverpod · shared_preferences.

## Global Constraints

- Schema v12 = exactly one change: nullable `tasks.durationMinutes` int.
- End-time validation: end must be strictly after start, same day; invalid picks rejected with a snackbar, never silently stored.
- Filters reset each visit; only the default view (list/grid) persists.
- Shift shading uses ShiftType defaults 07:00–19:00 (day) / 19:00–07:00 (night, split across midnight).
- `flutter analyze` clean before every commit; build_runner after schema/model changes; conventional commits.

---

### Task 1 — Schema v12 + range math + model plumbing

**Files:**
- Create: `lib/core/utils/time_block_utils.dart`
- Modify: `lib/features/tasks/data/tables/tasks_table.dart` (add `durationMinutes`)
- Modify: `lib/core/database/app_database.dart` (schemaVersion 12 + `if (from < 12) addColumn` + doc line)
- Modify: `lib/features/tasks/data/models/task_model.dart` (+`int? durationMinutes`)
- Modify: `lib/features/tasks/data/repositories/tasks_repository.dart` (`_fromRow`, `addTask` param, `updateTask` write)
- Modify: `lib/features/tasks/presentation/providers/tasks_providers.dart` (`AddTask.add` param passthrough)
- Test: `test/core/time_block_utils_test.dart`

**Interfaces produced:**
- `int? minutesOfDay(String? hhmm)` — "14:30" → 870; null/garbage → null.
- `String? endTimeOf(String? dueTime, int? durationMinutes)` — "14:00",90 → "15:30"; null inputs → null; clamps at 23:59 never wraps.
- `int? durationBetween(String start, String end)` — "14:00","15:30" → 90; end ≤ start → null (invalid).
- `String formatRange(String start, int durationMinutes)` — "14:00–15:30".
- `TaskModel.durationMinutes`.

- [ ] TDD: failing tests for the four functions (incl. end ≤ start → null, "24h wrap" clamp, garbage input) → implement → PASS.
- [ ] Table + migration + model + repository/provider plumbing → build_runner → full `flutter test` PASS → Commit `feat(tasks): schema v12 — optional durationMinutes (time ranges)`.

### Task 2 — Editor: optional End time tile

**Files:**
- Modify: `lib/features/tasks/presentation/screens/add_task_screen.dart`

**Behavior:** state `int? _durationMinutes` (edit mode: from task). Below the due-time `_DateTimeTile`, ONLY when `_dueTime != null`, render another `_DateTimeTile` (icon `Icons.hourglass_bottom_rounded`): label = `formatRange(startStr, _durationMinutes!) + ' · Xh Ym'` when set, else 'No end time'; tap → `showTimePicker` (initial = start + 1h) → `durationBetween` — null result ⇒ snackbar 'End time must be after the start time', state unchanged; clear button → null. Clearing the due time also clears the duration. `_save()` passes `durationMinutes` through `add()`/`copyWith`.

- [ ] Implement → analyze → device sanity (set 14:00 end 15:30, reopen task shows range; try end 13:00 → rejected) → Commit `feat(tasks): optional end time in editor`.

### Task 3 — Grid geometry (pure) + tests

**Files:**
- Create: `lib/features/planner/presentation/day_grid_layout.dart`
- Test: `test/features/planner/day_grid_layout_test.dart`

**Interfaces produced:**
- `class DayGridItem { final TaskModel task; final int startMin; final int durationMin; final int column; final int columns; }`
- `List<DayGridItem> layoutDayItems(List<TaskModel> tasks)` — keeps only `dueTime != null`; `durationMin = task.durationMinutes ?? 30`; sorted by start; overlap clusters get side-by-side columns capped at 3 (`column = indexInCluster % 3`, `columns = min(clusterSize, 3)`).
- `(List<TaskModel> timed, List<TaskModel> untimed) splitTimed(List<TaskModel>)` — timed sorted by start; untimed sorted priority desc then createdAt.

- [ ] TDD: no overlaps → all columns=1 · two overlapping → columns 2, columns差 · three → 3 · four overlapping → fourth reuses column 0 with columns=3 · touching ranges (10:00–11:00 + 11:00–12:00) do NOT overlap · splitTimed ordering. → implement → PASS → Commit `feat(planner): day grid layout math`.

### Task 4 — Enhanced day view: switch, ⋮ menu, hour grid

**Files:**
- Modify: `lib/core/settings/app_settings.dart` + `settings_provider.dart` (`plannerDayView` 'list'|'grid', key `planner_day_view`, `setPlannerDayView`)
- Modify: `lib/features/planner/presentation/widgets/day_detail_view.dart` — becomes `ConsumerStatefulWidget`; local state: `_grid` (init from settings), `_hideCompleted=false`, `_filterListId`, `_filterLabelId`; header row (right-aligned): list/grid `IconButton` toggle + `PopupMenuButton` (Hide completed ✓, Filter by list… → dialog of lists + Captured + All, Filter by label… → dialog of labels + All, 'Default view: List/Grid' → setPlannerDayView). Filters apply to BOTH views (list filter via `task.listId`, label via one-shot `watchLabelIdsForTask`-free approach: watch `taskLabels` per task is heavy — instead filter by label using `labelIdsForTaskProvider` is per-task; simpler: query-free approach — when a label filter is active, watch `labelsProvider`-side pairs via a new lightweight provider `taskIdsForLabelProvider(labelId)` = StreamProvider.family over `ListsDao`: `Stream<Set<int>>` from a new DAO method `watchTaskIdsForLabel(int labelId)` (select taskLabels where labelId, map to set). Add that method + provider in this task.
  - List view = existing sections; timed/untimed via `splitTimed`; TaskTile due chip now shows the time range (below).
  - Grid view = new widget.
- Modify: `lib/features/tasks/presentation/widgets/task_tile.dart` — `_DueDateChip` also renders time: `'Today · 14:00–15:30'` when dueTime set (range via `formatRange` when duration set, else bare time).
- Create: `lib/features/planner/presentation/widgets/day_time_grid.dart` — `DayTimeGrid({required String dateStr, required List<TaskModel> tasks, required WorkShiftModel? shift})`: SingleChildScrollView(controller initial offset = now-anchored for today, else first item/07:00) → SizedBox(height: 24*64) → Stack: hour gridlines + labels · shift shading containers (day 07–19; night 19–24 AND 00–07) · slabs from `layoutDayItems` (top = startMin/60*64, height = max(durationMin,30)/60*64, width split by column/columns, priority colour bg, white text, tap → `context.push('/tasks/edit', extra: task)`) · red current-time line (today only). Long-press empty area → derive hour from local dy → `context.push('/tasks/add', extra: AddTaskArgs(initialDate: dateStr, initialTime: 'HH:00'))`.
- Modify: `add_task_screen.dart` + `app_router.dart` — `AddTaskArgs` gains `String? initialTime`; create-mode init `_dueTime` from it.
- Above the grid: `ExpansionTile('Anytime · N')` with untimed tasks (urgency-sorted TaskTiles), habits section stays only in list view (grid is tasks-only; habits remain reachable by switching to list).

- [ ] Implement settings + DAO/provider + widgets → analyze + full tests → build + install on Flip 6 → device pass (switch views, default-view persists, filters, range slab, overlap, long-press create at hour, shift shading, current-time line) → Commit `feat(planner): enhanced day view — list/grid switch, filters, 24h time grid`.

### Task 5 — Docs + ship

- [ ] CLAUDE.md: schema v12 note (tasks.durationMinutes), feature-table row, backlog cleanup; version `1.4.0+7 → 1.5.0+8`.
- [ ] Full suite + analyze → commit `feat(planner): time blocking v1 — docs + version` → push → `gh release create v1.5.0` with APK + notes when the user says ship.

## Self-review
- Spec coverage: schema/duration (T1), editor tile + validation (T2), grid math + tests (T3), day view switch/⋮/filters/grid/anytime/shift/now-line/long-press (T4), docs+release (T5). ✓
- Type consistency: `formatRange`, `layoutDayItems`, `splitTimed`, `plannerDayView`, `AddTaskArgs.initialTime` used consistently. ✓
- One garbled fragment fixed inline: Task 3 test list "columns差" → "both get columns=2, distinct column indexes".
