# Notes — "Tame Long Notes" (Collapse Sections + Contained Photos) — Design

**Date:** 2026-08-01
**Status:** Design approved (photo decision revised — see Decisions)
**Area:** `lib/features/notes`
**Roadmap items:** A7 (collapse sections under a heading) + A1 (contain tall
photos), from `docs/superpowers/NOTES-ROADMAP.md`. A8 (fast in-note reorder) is
the **next** batch, not this one.

## Problem
Clinical rounds notes are long and photo-heavy (a notebook per site, a note per
bed, each bed with vent-screen photos). Two things make them unwieldy to scroll:
(1) you can't fold away beds you're not currently looking at, and (2) a single
full-width photo can dominate an entire screen. This batch adds two levers that
together "tame" a long note: **fold sections under headings** (A7) and **stop
any one photo from hijacking the scroll** (A1).

## Decisions (from brainstorming)
1. **Collapsed state is remembered across opens** (persisted), not view-only —
   user chose "Remember it". A folded bed stays folded next shift.
2. **Photos: no toggle.** The user first picked a per-note "Compact photos"
   switch, then asked for the smoothest/cleanest, Apple-style, minimal-choice
   move. **Revised decision:** photos render at a consistent **bounded height**
   by default (tap → fullscreen); there is no compact switch and no mode.
   Rationale: the smoothest option is a great default with zero configuration
   (Apple Notes has no "compact photos" setting). This also drops a schema
   column and a menu item. Tradeoff: it's not per-photo control — that (and
   side-by-side photos) is the deferred **D1 gallery**, an *addition* later, not
   a setting now.

## Scope
- **In:** A7 collapse (persisted) + Collapse-all / Expand-all; A1 contained
  photo height.
- **Out (deferred):** A8 fast in-note reorder (next batch), D1 multi-photo
  gallery / side-by-side, per-photo size control, notes-in-Archived.

## Data model — schema v19 (one migration step)
- `note_blocks.collapsed` — `BOOL NOT NULL DEFAULT false`. Meaningful **only on
  heading text blocks** (`headingLevel != 0`); `true` = that section is folded.
  Non-heading blocks ignore it — exactly as `checked` is only for checkboxes and
  `headingLevel` only for text. Default `false` → **no backfill**, existing
  notes open fully expanded.
- Migration: a single `if (from < 19) { m.addColumn(noteBlocks, noteBlocks.collapsed); }`.
- **No `notes.compactPhotos`** — photo containment is pure rendering, no state.
- **Backup:** the new column rides along automatically (export via `allTables`,
  import via `fromJson`), the same way v17/v18 columns did — no BackupService
  change.
- **Grid preview / `notePreview`:** untouched.

## A7 — Collapse sections under a heading

### Section rule (pure, unit-tested)
A new pure helper `computeSectionFold(List<NoteBlock> blocks) -> SectionFold`:
- A **heading** = a `text` block with `headingLevel` in 1..3.
- A **collapsed, currently-visible** heading hides every block below it **until
  the next heading whose level ≤ its own level** (or the end of the note). So
  folding an H1 hides nested H2s and their content; folding a lone H2 hides just
  its run.
- `SectionFold` returns:
  - `Set<int> hiddenIds` — block ids the editor must not render.
  - `Map<int,int> hiddenCountByHeadingId` — for each collapsed **visible**
    heading, how many blocks are folded under it (for the "· N hidden" label).
- **Nesting:** an outer collapse hides inner headings too; the inner heading's
  remembered `collapsed` state re-applies when the outer one expands (it's all
  derived from the block list every build, so it's automatic).
- **Algorithm** (single pass, stack of open collapsed headings `(id, level)`):
  for each block, when it is a heading, pop stack entries with `level >= this
  heading's level` (their section ended). The block is hidden iff the stack is
  non-empty. Then, if the block is a heading that is `collapsed` **and** not
  itself hidden, push `(id, level)`. Counts: for each collapsed visible heading,
  count the blocks from just after it until the next heading with `level ≤` its
  own (or end).

### UI (normal editor)
- A heading block renders as a row: **`▾ / ▸` caret** · the editable heading
  `TextField` (unchanged `TextBlockView`) · a muted **"· N hidden"** shown only
  when folded and `N > 0`.
- Tapping the **caret** toggles `collapsed`; tapping the heading **text** still
  edits it (a caret avoids the tap-to-edit vs tap-to-fold conflict, since the
  heading is an editable field).
- Blocks whose id ∈ `hiddenIds` are simply not built in the `ListView`.
- **⋮ menu:** "Collapse all" / "Expand all" — sets every heading in the note
  collapsed / expanded in one transaction (great for a 6-bed note).
- **"Edit lines" (reorder) mode ignores folding** — it always shows every block
  (you can't reorder what's hidden).

### DAO
- `setBlockCollapsed(int id, bool collapsed)` — partial update (`Value` pattern
  like `setBlockFormat`).
- `setAllHeadingsCollapsed(int noteId, bool collapsed)` — one transaction over
  the note's heading text blocks (`headingLevel != 0`).

## A1 — Contained photo height
- `PhotoBlockView` wraps the image in `ConstrainedBox(maxHeight:
  kNotePhotoMaxHeight)` with `BoxFit.contain` (no crop), centered, rounded; tap
  → existing `PhotoViewScreen` (fullscreen). The "Image unavailable" placeholder
  and the crop/remove overlay buttons are unchanged.
- `kNotePhotoMaxHeight` = a named const (~220) in the widget, tunable on device.
- No toggle, no persistence, no schema.
- A portrait clinical photo shows fully at a bounded height (centered, letterbox
  gaps at the sides); a landscape photo is full-width and shorter. Full detail
  is always one tap away via fullscreen.

## Edge cases
- **Empty section** (heading with nothing under it): caret still toggles; the "N
  hidden" label is hidden when `N == 0`.
- **Delete a heading / demote it to Body** (`headingLevel → 0`): it stops acting
  as a heading; its `collapsed` flag is ignored and any blocks it was hiding
  reappear (fold is recomputed from the live list each build).
- **Reorder while folded:** not possible — folding is off in Edit-lines mode.
- **Restore on a fresh device:** `collapsed` rides along in backup; missing
  photo files fall back to the existing placeholder.

## Testing
- **Unit — `computeSectionFold`:** flat (two headings, fold the first); nested
  H1>H2 (fold H1 hides the H2 + its content; fold only the H2 hides just its
  run); trailing section to end-of-note; a note with no headings (empty hidden
  set); multiple collapsed headings; `hiddenCountByHeadingId` correctness.
- **DAO round-trip:** `setBlockCollapsed` persists; `setAllHeadingsCollapsed`
  flips only heading blocks, leaving body/checkbox/photo/divider untouched.
- **Manual (device):** a real multi-bed rounds note — fold/unfold a bed,
  Collapse-all / Expand-all, reopen the note (state remembered), photos bounded
  and tap→fullscreen.

## Files
**New**
- `lib/features/notes/domain/section_fold.dart` — `SectionFold` +
  `computeSectionFold`.
- `test/features/notes/section_fold_test.dart`.

**Modify**
- `lib/features/notes/data/tables/note_blocks_table.dart` — `collapsed` column.
- `lib/core/database/app_database.dart` — `schemaVersion = 19` + migration.
- `lib/features/notes/data/dao/notes_dao.dart` — `setBlockCollapsed`,
  `setAllHeadingsCollapsed`.
- `test/features/notes/notes_dao_test.dart` (or the existing notes DAO test) —
  collapse round-trip.
- `lib/features/notes/presentation/screens/note_editor_screen.dart` — compute
  fold, caret on headings, skip hidden blocks, ⋮ Collapse/Expand all.
- `lib/features/notes/presentation/widgets/photo_block_view.dart` — bounded
  height.

## Not doing (this batch)
A8 fast in-note reorder (next), D1 multi-photo gallery / side-by-side,
per-photo size control, notes-in-Archived.
