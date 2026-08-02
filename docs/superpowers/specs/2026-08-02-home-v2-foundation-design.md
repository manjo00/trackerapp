# Home v2 — Block Foundation (DB) + Task Detail Card + Pinned Note — Design

**Date:** 2026-08-02
**Status:** Approved (user picked batch E+A+B from the Home-polish brainstorm)
**Area:** `lib/features/home`, `lib/features/tasks` (tile), `lib/features/notes`
(picker + inline render)

## Problem / goals
User theme: **"not enough control and options."** Three pieces this batch:
- **E — Foundation:** Home layout lives in prefs (`AppSettings.homeBlocks`, a
  bare ordered list of types). No block can carry settings, so nothing
  configurable can exist. Bonus defect: prefs aren't in the JSON backup, so the
  Home layout doesn't survive restore.
- **A — Task detail card (user idea):** `TaskTile` completes on **tap anywhere**
  (documented in the tile). Accidental completions; no way to *look* at a task;
  no path from a task back to its list or the note that spawned it.
- **B — Pinned note on Home (user idea):** the Notes block only shows notebook
  shortcuts. The user wants an actual **note's content** on Home (handover /
  scratch note), ticking checkboxes right there.

## Decisions
1. **Blocks move to the DB** — schema **v21**, table `home_blocks`:
   `id` PK · `type` TEXT (HomeBlockType name) · `orderIndex` INT ·
   `configJson` TEXT nullable (per-type settings; `{"noteId": 5}` for pinned
   note; future: `{"limit":5}`, `{"listId":3}` …). **No FKs** — a pinned note
   that's deleted renders a "choose another" placeholder instead of cascading
   the block away. Rides in backups (added to BackupService's explicit
   delete-order + insert list; position free, it has no FK deps).
2. **Seeding, not migration-magic:** the migration only creates the table.
   A provider-level `ensureSeeded(legacy)` runs once per app start before the
   rows stream is first read: if the table is empty, insert the user's current
   `settings.homeBlocks` (or defaults). Prefs value stays but becomes dead.
   (Prefs aren't readable inside a Drift migration; this is also unit-testable.)
3. **Tap = look, circle = done (A):** tile body tap opens a **TaskDetailSheet**
   (modal bottom sheet): check-circle + title, note, due date/time, priority,
   label chips, **list link** (task.listId → list name → `/lists/:id`) and
   **"From note …" link** (task.sourceNoteBlockId → block → note title →
   `/notes/:id`). Edit button → existing `/tasks/edit`. Long-press on the tile
   keeps opening edit directly. Applies app-wide (one shared tile).
4. **Pinned note block (B):** new `HomeBlockType.pinnedNote` ('Pinned note',
   push_pin icon). Renders the chosen note: title as the block header
   (override of the type label) + the first **6** visible blocks — text styled
   by its format flags, checkboxes **tappable** (persist + note↔task sync via
   `NoteTaskLinker.onBlockCheckedChanged`, same as the editor), photos as a
   small thumbnail, "+N more lines" when truncated. Tap anywhere else →
   `/notes/:id`. **Multiple pinned-note blocks allowed** (different notes);
   all other types stay single-instance in the add sheet.
   Picker: new `NotesDao.watchAllNotes()` (active, non-template, across all
   notebooks, newest-edited first) feeding a bottom-sheet chooser, used both
   when adding the block and from Edit Home ("Change note").
5. **Legacy parse stays safe:** `HomeBlockType.parse` already drops unknown
   names and dedupes — old prefs can never contain `pinnedNote`, and the DB
   path doesn't use `parse` for layout, so multiple pinned blocks are fine.

## What does NOT change
- The de-dupe rule (first block claims a task) and drag-header reorder UX.
- Task completion from the check circle, swipe-to-archive, long-press → edit.
- `AppSettings.homeBlocks` field (kept as the one-time seed source).

## Out of scope (next batch)
C control pack (item limits, This-week day count, collapse, hide-when-empty,
accents) · D new block types (list/label/habits/shift) · **responsive
multi-column Home (#27)** · quick-add per block.

## Build stages (each: tests + analyze; device verify at the end)
1. **Data:** v21 table + codegen; `HomeBlocksDao` (watch, insert-at-end,
   delete, reorder, updateConfig, ensureSeeded) + unit tests; backup wiring;
   `HomeBlockType.pinnedNote`.
2. **Screens on DB:** rows provider (seed-gated stream); HomeScreen renders
   rows (keys = row id, header override for pinned notes); EditHomeScreen on
   DAO (reorder/remove/add sheet + note picker, "Change note" on pinned rows).
3. **PinnedNoteBlock widget** + `watchAllNotes` + placeholder for a
   deleted/archived note.
4. **TaskDetailSheet + tile change** (+ `ListsDao` label lookup reuse;
   widget test: body tap opens the sheet and does NOT toggle; circle toggles).
5. Full suite, build, install, docs.

## Files
**New:** `features/home/data/home_blocks_dao.dart` ·
`features/home/presentation/widgets/pinned_note_block.dart` ·
`features/tasks/presentation/widgets/task_detail_sheet.dart` ·
`core/database/tables/home_blocks_table.dart` (or under features/home/data) ·
tests for DAO, parse, sheet/tile.
**Modify:** `app_database.dart` (v21) · `backup_service.dart` ·
`home_block_type.dart` · `home_screen.dart` · `edit_home_screen.dart` ·
`notes_dao.dart` (watchAllNotes) · `task_tile.dart`.
