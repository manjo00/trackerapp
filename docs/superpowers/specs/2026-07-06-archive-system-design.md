# Archive System — Design Spec

**Date:** 2026-07-06 · **Status:** approved by user (decisions locked in chat)

## Context

From feedback/app.md: "archive system for lists and individual tasks,
trackers, habits" — hide clutter without deleting, recoverable later. The app
is heading to the Play Store, so a non-destructive archive is table stakes.

## Locked decisions

1. **Scope: everything** — tasks, task lists, trackers, habits (v1).
2. **Storage:** a nullable `archivedAt` DATETIME column per archivable table
   (schema v13). NULL = active; non-null = archived (and when it was). No
   separate tables, no status enum — one column, every "watch active" query
   adds `WHERE archivedAt IS NULL`.
3. **UI:** one **Archived** entry in the app drawer → an `ArchivedScreen`
   with a section per type (Tasks · Lists · Trackers · Habits). Each row has
   **Restore** (archivedAt → NULL) and **Delete forever** (hard delete,
   confirm dialog). Empty types show a quiet note.
4. **Archiving action:** the existing swipe/long-press delete on each item's
   tile becomes **Archive** (swipe) with delete-forever demoted to the item's
   menu/long-press. Archiving a **list** archives the list row only; its tasks
   stay (they'll show "no list"/Captured) — restoring the list re-homes them.
   (Cascade-archiving a list's tasks is out of scope; noted for later.)

## Data model (schema v12 → v13)

`m.addColumn` (nullable, no backfill needed — existing rows = active):
- `tasks.archivedAt`
- `task_lists.archivedAt`
- `custom_trackers.archivedAt`
- `habits.archivedAt`

## Query ripple (the bulk of the work — must be exhaustive)

Every stream/query that lists **active** items filters `archivedAt IS NULL`.
Known surfaces to audit and patch (grep `select(` per DAO):
- **Tasks:** watchAllTasks, watchTasksDueToday, watchOverdueTasks,
  watchTasksForDate, watchCapturedTasks, watchTasksForList,
  watchTasksInRange, watchTaskCountsByList, getAllTasks (reschedule).
  Home blocks + Planner + Lists + live-notification `syncCards` + home widget
  all flow through these — verify each.
- **Lists:** watchLists, watchTaskCountsByList (already tasks-side).
- **Trackers:** every watch in trackers_dao (list, today checklist,
  with-progress).
- **Habits:** watchAllHabits / habitsWithStatus / habitsForDate,
  rescheduleAll, home-widget habit counts, live-notification habit cards.
- **BackupService:** export unaffected (dumps all rows incl. archivedAt);
  restore already generic — the new column round-trips via toJson/fromJson.

## Archived screen

`lib/features/archive/presentation/screens/archived_screen.dart` +
`archive_providers.dart` (four `watchArchived*` streams). Drawer tile under
Settings & info. Restore/delete via repository methods
`archive(id)/unarchive(id)/deleteForever(id)` per feature repo.

## Testing

Unit (in-memory Drift): archiving hides from the active watch + shows in the
archived watch; unarchive reverses; delete-forever removes entirely; a
list's tasks survive the list being archived.

## Out of scope (recorded)

Cascade-archive (archive a list → archive its tasks); auto-archive completed
tasks after N days; bulk restore; archive for workout sessions/programs.

## Definition of done

schema v13 via addColumn · build_runner · every active query filtered (audited
by grep, not memory) · Archived screen + drawer entry · swipe=archive,
menu=delete-forever · unit tests + full suite · device pass · CLAUDE.md
schema v13 + feature row · version bump · release when user says ship.
