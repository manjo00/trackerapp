# Archive System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Non-destructive archive for tasks, lists, trackers, habits — hidden from every active view, recoverable from a drawer Archived screen. Per spec `docs/superpowers/specs/2026-07-06-archive-system-design.md`.

**Architecture:** One nullable `archivedAt` column per archivable table (schema v13). Active queries add `WHERE archivedAt IS NULL`; a parallel set of `watchArchived*` queries feeds the Archived screen. Swipe = archive; delete-forever moves to the item menu.

**Tech Stack:** Flutter 3.44 · Drift 2.28 (`m.addColumn` only) · Riverpod · go_router drawer.

## Global Constraints

- schema v13 = four nullable `archivedAt` DATETIME columns only.
- Active-query audit is done by GREP per DAO, not from memory — every `select(` on an archivable table either filters `archivedAt IS NULL` or is intentionally exempt (archived watches, getAll for backup/reschedule where archived items must still reschedule? NO — archived items must NOT reschedule notifications; reschedule paths also filter).
- `flutter analyze` clean + build_runner after schema change + conventional commits.

---

### Task 1 — Schema v13 + active-query filters + tests

**Files:**
- Modify tables: `tasks_table.dart`, `task_lists_table.dart`, `custom_trackers_table.dart`, `habits_table.dart` (+`DateTimeColumn get archivedAt => dateTime().nullable()();`)
- Modify: `app_database.dart` (schemaVersion 13 + `if (from < 13){ addColumn ×4 }`)
- Modify DAOs — add `& tbl.archivedAt.isNull()` (or `..where`) to EVERY active watch:
  - `tasks_dao.dart`: watchAllTasks, watchTasksDueToday, watchOverdueTasks, watchTasksForDate, watchCapturedTasks, watchTasksForList, watchTasksInRange, watchTaskCountsByList (already?), getAllTasks (reschedule — filter so archived don't reschedule).
  - `lists_dao.dart`: watchLists; watchTaskCountsByList (tasks-side filter).
  - `trackers_dao.dart`: watchAllTrackers, getAllTrackers, and any today/checklist watches that start from trackers.
  - `habits_dao.dart`: watchAllHabits, getAllHabits, the joined habitsForDate query (line ~103), watchAllCompletions is completion-side (leave).
- Add per-DAO: `Stream<List<T>> watchArchived*()` (archivedAt not null, newest first) + `Future<void> setArchived(int id, DateTime? at)` + reuse existing hard-delete.
- Test: `test/features/archive/archive_schema_test.dart`

**Interfaces produced:** `TasksDao.watchArchivedTasks()/archiveTask(int)/unarchiveTask(int)`; same shape on lists/trackers/habits DAOs; `deleteForever` reuses existing delete methods.

- [ ] TDD: archiving a task hides it from watchAllTasks + shows in watchArchivedTasks; unarchive reverses; delete-forever removes; archiving a list keeps its tasks visible (listId intact, list gone from watchLists). → schema + filters + methods → build_runner → full `flutter test` PASS → Commit `feat: schema v13 — archivedAt + active-query filters`.

### Task 2 — Repository + provider layer

**Files:** each feature repo gains `archive(int)/unarchive(int)/deleteForever(int)` + `watchArchived()`; new `lib/features/archive/presentation/archive_providers.dart` exposing four archived-list StreamProviders. Rename existing tile "delete" repo calls used by swipe to call `archive` (keep `deleteForever` for the menu).

- [ ] Implement passthroughs → analyze → Commit `feat(archive): repository + providers`.

### Task 3 — Swipe=archive, menu=delete-forever on tiles

**Files:** `task_tile.dart` (Dismissible → archive + "Archived" snackbar with UNDO=unarchive; long-press menu already opens edit — add delete-forever there or a small ⋮), tracker/habit/list tiles similarly. List detail + Lists overview: list archive action in the ⋮ menu.

- [ ] Implement → analyze → device sanity → Commit `feat(archive): archive from tiles (swipe), delete-forever in menus`.

### Task 4 — Archived screen + drawer entry

**Files:** `lib/features/archive/presentation/screens/archived_screen.dart` (sections Tasks/Lists/Trackers/Habits, each row Restore + Delete-forever w/ confirm, empty notes); `app_drawer.dart` (Archived tile under Settings & info → `context.push('/archived')`); `app_router.dart` (`/archived` full-screen route).

- [ ] Implement → analyze + full tests → build + install → device pass (archive each type, restore, delete-forever, list-archive leaves tasks) → Commit `feat(archive): Archived screen + drawer entry`.

### Task 5 — Ripple audit + ship

- [ ] Grep-audit the four tables' `select(` again; confirm live-notification syncCards + home-widget counts exclude archived (they flow through the filtered DAOs — verify). BackupService round-trips archivedAt (generic — confirm fromJson).
- [ ] CLAUDE.md schema v13 + feature row; version `1.5.0+8 → 1.6.0+9`; full suite + analyze → commit → push → `gh release create v1.6.0` when user says ship.

## Self-review
- Spec coverage: schema (T1), filters exhaustively listed (T1), repo/providers (T2), archive UX (T3), Archived screen + drawer (T4), ripple audit + release (T5). ✓
- Consistency: `archive/unarchive/deleteForever/watchArchived*` naming uniform across all four features. ✓
