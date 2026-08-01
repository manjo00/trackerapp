# Notes — Custom Drag Engine (out-anywhere + hold-to-enter) — Design

**Date:** 2026-08-01
**Status:** Design approved (nesting = full, matching headings)
**Area:** `lib/features/notes`
**Follows:** the "tame long notes" batch (A7/A1/A8 + outline indentation). This
replaces the arrange-mode reorder built on `ReorderableListView` with a custom
drag surface, and fixes the two things that list can't do: being **top-level
below a bed**, and **deliberately entering** a bed.

## Problem
Arrange mode is built on `ReorderableListView`, which is a flat list. Two limits:
1. **No explicit "out".** Indent is *derived from position*, so every block
   after a heading counts as inside it — you can't put a line at the top level
   below the last bed, or park one between beds.
2. **No "enter".** You can't hover a collapsed bed to open it and drop inside;
   and an open heading can't fold-as-you-drag.

## Decisions
1. **Explicit indent (schema v20).** Store each block's outline depth instead of
   deriving it. This is the foundation for "out anywhere" — a block at indent 0
   is top-level wherever it sits.
2. **Full nesting**, matching headings (site H1 › bed H2 › lines). Indent is an
   integer 0,1,2,…; heading font size (`headingLevel`) is independent of it.
3. **Out by default, in on purpose.** Dropping in any gap → top-level. To nest
   into a bed, **hold over its header ~0.5s** → it expands + highlights, then
   drop inside.
4. **Fold-on-grab.** Picking up a heading folds its bed to one tile for the drag
   and restores its prior open/closed state on release.
5. **Arrange mode only.** The normal editor is unchanged (still for typing); the
   custom surface is the ⇅ arrange view.

## Data model — schema v20
- `note_blocks.indent` — `INTEGER NOT NULL DEFAULT 0`. Outline depth; 0 =
  top-level.
- **Backfill on upgrade:** for each note, compute each block's current *derived*
  depth (a heading sits at its ancestors' depth; a non-heading sits under all
  open headings — the existing `blockDepths` rule) and write it to `indent`, so
  existing notes look identical after upgrade.
- From v20, `indent` is the single source of truth for **indentation** and
  **section membership**.

### Section membership (now indent-based, was headingLevel-based)
- A **container** is a heading block (text with `headingLevel != 0`).
- A heading at indent `d` owns the run of following blocks with indent `> d`,
  until the next block with indent `<= d`.
- `computeSectionFold` and the outline indent both read `indent` (heading font
  level no longer drives nesting — they're decoupled, which is what lets you
  drag a bed to any depth).

## Interaction (the custom surface)
- **Pick up:** long-press any tile. Grabbing a heading folds its bed to one tile
  for the drag (restores on drop).
- **Drop indicator:** a line shows the landing gap; the list **auto-scrolls**
  near the top/bottom edges while dragging.
- **Out (default):** release in any gap — between beds, below the last bed, above
  the first — and the item lands at **top level** (indent 0), or at the indent of
  the surrounding context.
- **In (deliberate):** hold the dragged item over a bed's header for **~0.5s** →
  a closed bed **expands** (≈200ms) and **highlights** (≈0.5s) so you can see
  inside; releasing there nests the item at that bed's indent + 1.
- Getting **out** of a bed is always easy (drop in a gap); getting **in** always
  requires the deliberate hover — so it's never ambiguous.

## Rendering
- Indent = `b.indent * kNoteIndentStep`, on the **leading side per line**
  (English left, Arabic right — existing `lineStartsRtl`).
- Delete badge (⊖) and the fold caret (▸/▾) stay as in the current arrange tile.

## Build in stages (each verified on device)
1. **Stored indent (v20).** Add the column, backfill from derived depth, switch
   indentation + `computeSectionFold` to read `indent`. **Invisible** — notes
   look identical and the current arrange list keeps working. *Verify: nothing
   changed; folds + reorder still work.*
2. **Custom drag surface.** Replace `ReorderableListView` in arrange mode with a
   `LongPressDraggable` + drop-indicator + autoscroll surface at **parity** with
   today's reorder (no new placement powers yet). *Verify: reorder feels the same
   or better.*
3. **Out-anywhere.** Dropping in a gap sets the item's `indent` from where it
   lands, so it can be top-level below the last bed / between beds. *Verify: pull
   a line out below the last bed → it stays out.*
4. **Hold-to-enter + fold-on-grab.** Hover-a-header-to-expand+highlight to nest
   inside; fold the grabbed heading during the drag. *Verify: the full feel.*

## Testing
- **Pure, unit-tested:** section membership from `indent` (fold ranges); the
  migration backfill (derived depth → indent) as a pure function; drop-target
  resolution (given the ordered blocks + a landing gap + optional entered-bed →
  new position + indent).
- **On device:** each stage's verify step above.

## Files
**Modify**
- `note_blocks_table.dart` (+`indent`), `app_database.dart` (v20 + backfill).
- `note_outline.dart` (depth now reads `indent`; keep `lineStartsRtl`).
- `section_fold.dart` (fold ranges from `indent`).
- `section_reorder.dart` (indent-aware; superseded by the drag surface in stage 2+).
- `note_editor_screen.dart` (arrange body → custom surface).

**New (stage 2+)**
- A drag-surface widget (`note_arrange_view.dart` or similar) + a pure
  drop-resolution helper + tests.

## Not doing
- Drag in the normal (typing) editor — arrange mode only.
- Reordering across different notes.
