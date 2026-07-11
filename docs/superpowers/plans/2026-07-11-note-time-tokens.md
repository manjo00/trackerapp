# Note "@time" Task Tokens — Implementation Record

> **Status: DONE & VERIFIED.** This is a handoff/changelog for a feature that is
> already implemented, tested, and committed — not a to-do plan. It exists so a
> later session can understand exactly what changed and revert cleanly.

**Commit:** `66e2279` — *"feat: auto-create tasks from \"@time\" note lines (two-way linked)"*
**Branch:** `claude/costa-screen-recorder-issue-vh6yhx` (branched off `master`; `master` untouched)
**Date:** 2026-07-11
**Schema:** v14 → **v15**

## Goal
Typing a line that starts with a time token inside a note auto-creates a task
that stays two-way linked to that note line.

```
@1250pm             → task today at 12:50
@1250pm/17july      → task on 17 Jul at 12:50
@1450pm take bloods → task "take bloods" today at 14:50
```
The task is filed under a list auto-created per note (named after the note).

## Behaviour
- Save a note line with a token → task appears in the note's auto-list.
- Edit the token → task updates; remove the token → task deleted.
- Delete the line, or the whole note → task **and** its empty auto-list deleted
  (database ON DELETE CASCADE, no app code).
- Tick the note checkbox ⇄ complete the task (both directions).
- Title-less token (`@0900` alone) borrows the note's title, falling back to
  "Reminder" for an untitled note.

## Architecture
- **`TaskTokenParser`** (`lib/features/notes/domain/task_token_parser.dart`) —
  pure, unit-tested function: `"@time[/date] title"` → time / date / title.
  If the hour is ≥13 the am/pm is ignored (already 24-hour), so `@1450pm` = 14:50.
- **Schema v15** — two nullable FK columns, links stored **by identity**:
  - `tasks.sourceNoteBlockId` → `note_blocks(id)` ON DELETE CASCADE.
  - `task_lists.sourceNoteId` → `notes(id)` ON DELETE CASCADE.
- **`NoteTaskLinker`** (`lib/features/notes/domain/note_task_linker.dart`) —
  coordinator that reconciles a block ↔ its task and mirrors completion both
  ways. Lives in the notes feature so neither repository imports the other.

## Files changed
**New**
- `lib/features/notes/domain/task_token_parser.dart`
- `lib/features/notes/domain/note_task_linker.dart`
- `test/features/notes/task_token_parser_test.dart`
- `test/features/notes/note_task_linker_test.dart`
- `test/core/database/note_task_link_migration_test.dart`

**Edited**
- `lib/features/tasks/data/tables/tasks_table.dart` — `sourceNoteBlockId` column + import.
- `lib/features/tasks/data/tables/task_lists_table.dart` — `sourceNoteId` column + import.
- `lib/core/database/app_database.dart` — `schemaVersion` 15 + `if (from < 15)` migration.
- `lib/features/tasks/data/dao/tasks_dao.dart` — `getTask`, `getTaskForBlock`.
- `lib/features/tasks/data/dao/lists_dao.dart` — `getListForNote`.
- `lib/features/notes/data/dao/notes_dao.dart` — `getBlock`.
- `lib/features/notes/presentation/providers/notes_providers.dart` — `noteTaskLinkerProvider`.
- `lib/features/notes/presentation/widgets/text_block_view.dart` — reconcile on save.
- `lib/features/notes/presentation/widgets/checkbox_block_view.dart` — reconcile on save + mirror tick.
- `lib/features/tasks/presentation/providers/tasks_providers.dart` — mirror task→note on toggle.
- `lib/core/backup/backup_service.dart` — insert/delete order reworked for the new FKs
  (notes cluster now inserted before tasks; task cluster deleted before notes).
- `CLAUDE.md` — "Open Questions / To Revisit" note on task-deletion behaviour.

## Verification (already run, all green)
```
dart run build_runner build --delete-conflicting-outputs   # clean
flutter test                                               # 131/131 pass
flutter analyze lib/features/notes lib/features/tasks ...   # No issues found
```
> ⚠️ NOT yet checked on a real Android emulator (no device in the cloud session).
> That manual pass is the one remaining "Definition of Done" item.

## Open question (see CLAUDE.md)
The note is the **source of truth**: deleting the auto-created task directly from
the Tasks screen makes it **respawn** on the next save of that note line. Chosen
for simplicity; flagged in `CLAUDE.md` to revisit (e.g. strip the token or
tombstone the line instead).

## How to revert
`master` never changed, so the safe options are, easiest first:
1. **Don't merge** this branch — nothing to undo.
2. Undo just this change if already merged: `git revert 66e2279`, then
   `dart run build_runner build --delete-conflicting-outputs`.
3. Discard the branch entirely: `git branch -D claude/costa-screen-recorder-issue-vh6yhx`
   (and delete the remote branch on GitHub).

Reverting drops schema v15. Because both columns are nullable and additive, a DB
already migrated to v15 keeps working with reverted (v14) code — the extra
columns are simply ignored. No data migration is needed to go back.
