# Notes — Future Ideas & Roadmap

Captured 2026-07-29 (post v1.11.1). Groups the user's requested ideas + a
brainstorm of adjacent ones. Each item: what it is · rough approach · size
(S ≈ a few hours, M ≈ a day, L ≈ multi-session). **Nothing here is built** —
each is a candidate for the usual brainstorm → spec → plan → build flow.

Context for whoever picks these up: notes are a **block model** (schema v18) —
`notes` (title, notebookId, updatedAt, archivedAt, isTemplate) → `note_blocks`
(type text/checkbox/photo/divider, content, checked, orderIndex, +v17 format
flags headingLevel/highlighted/bold/italic). Photos store a filename; the file
lives in `<appDocs>/note_images/`. The grid card (NoteGridCard) uses
`notePreview()` = first photo + first text snippet + photo count.

---

## A. User-requested (this session)

### A1. Minimize / collapse inline photos  ·  M
Photo-heavy clinical notes get very tall. Let a photo block **shrink to a small
thumbnail** (tap to expand full-width; tap again to shrink). Optionally a
per-note or global "compact photos" default.
- Approach: add a `collapsed` bool to `note_blocks` (schema bump) OR keep it
  view-only state (Set of collapsed block ids in the editor, not persisted).
  Persisted is nicer (remembers). PhotoBlockView renders a ~72px thumb when
  collapsed.
- Pairs well with **A2** and **D (gallery block)**.

### A2. Choose the grid-card cover photo (not just the first)  ·  S–M
Today the notebook grid card always shows the note's **first** photo. Let the
user **pick which photo is the cover** — e.g. a photo block ⋮ → "Set as cover",
or a star on the photo.
- Approach: add `notes.coverBlockId` (nullable FK → note_blocks, SET NULL) OR
  `notes.coverImageFilename`. `notePreview`/NoteGridCard prefer the cover, fall
  back to first photo. Small schema + a photo action + preview tweak.

### A3. Favourite templates  ·  S
Star a template so it floats to the top of the picker (and the notebook ＋
sheet), and could be a per-notebook default.
- Approach: `notes.isFavorite` bool (shared with A4). `watchTemplates()` orders
  favourites first. Star toggle in TemplatesScreen + editor ⋮.

### A4. Favourite / pin notes  ·  S–M
Star notes; show a **Favourites** section (or pin-to-top within a notebook).
- Approach: reuse `notes.isFavorite`. NotebookDetail shows starred notes first
  (or a pinned row); a Favourites tile on the overview. Star on the grid card +
  editor ⋮. (Pin-within-notebook vs a global Favourites view is a design Q.)

### A5. Sort notes  ·  S
Per-notebook sort: **Edited (default) · Created · Title A–Z · Manual**.
- Approach: `AppSettings`/prefs per-notebook sort, or a `notes.orderIndex` for
  manual. `watchNotes` takes a sort param. A ⋮ "Sort" menu in NotebookDetail.
  Manual sort needs drag-reorder of cards (relates to bulk/reorder).

### A6. Search inside notes  ·  M
Find notes by **title + block content**; ideally in-note find-and-highlight too.
- Approach: a search screen/bar; query joins `notes` + `note_blocks` on
  `content LIKE`. Drift FTS5 (`fts5`) virtual table for speed on large sets, or
  simple LIKE for MVP. Result → open note (optionally scroll to match).
  Templates excluded (or a separate scope). Consider a global Notes search vs
  per-notebook.

### A7. Collapse sections under a heading  ·  M
Tapping a **heading** collapses everything beneath it up to the next heading —
like Notion toggles. Huge for long rounds notes.
- Approach: pure helper `sectionRanges(blocks)` → maps each heading to the block
  range it owns (heading = `headingLevel != 0` text block; a section runs until
  the next heading of same-or-higher level). Editor keeps a Set of collapsed
  heading ids (persist via a `note_blocks.collapsed` bool for durability); the
  list skips rendering blocks inside a collapsed range and shows a "▸ n hidden"
  affordance on the heading. Unit-test `sectionRanges`.

### A8. Fast reordering inside a note  ·  M
The current reorder lives in a separate "Edit lines" mode. Make reordering
**quicker** — e.g. long-press a block in the normal editor to drag it, or a
persistent tiny grip that doesn't clutter.
- Approach: the conflict is long-press = text selection in a TextField. Options:
  (a) long-press the **left gutter** of a block to start a drag; (b) a "reorder"
  toggle that's one tap away and shows inline handles; (c) drag a **heading** to
  move its whole collapsed section (pairs with A7). Prototype (a) or (c).
  Reuse `reorderBlocks` / `insertBlocksAt`.

### A9. Side-by-side blocks (columns), not only stacked  ·  L
Let blocks sit **next to each other**, not just under each other — e.g. two bed
cards in a row, a photo beside its notes, or two checklists side by side. Big
layout upgrade for dense clinical notes.
- The block model is 1-D today (`orderIndex` only). Two shapes to consider:
  - **(a) Row container**: a `row`/`columns` container block holding N child
    blocks rendered in a `Row`, each child a mini vertical stack. Cleanest
    mental model; biggest change (nested blocks → the editor, reorder, copy,
    backup all learn about children).
  - **(b) Column index on blocks**: add `columnIndex` (+ a `rowGroup` id) to
    `note_blocks`; consecutive blocks sharing a rowGroup render in a `Row`,
    laid out by `columnIndex`. Less nesting, but ordering/reorder logic gets
    fiddly (2-D within a group).
  - MVP could cap it at **2 columns** and a "split this line into two columns"
    action, expanding later.
- Responsive: on a narrow phone, wide rows may need to **wrap/stack** (a Wrap or
  a breakpoint) so nothing overflows. Pairs with **D1 (photo gallery)** — a row
  of photos is a special case of this.
- Interaction: drag a block **onto the side** of another to pair them; drag out
  to unpair. Needs a clear affordance.
- Sizeable (schema + editor + rendering + reorder + backup + copy-for-templates
  all touched) — its own brainstorm → spec → plan when picked.

---

## B. Brainstormed — findability & organisation

- **B1. Move note to another notebook**  ·  S — editor/card ⋮ → notebook picker
  (`notes.notebookId` update). Common need; currently only delete-notebook
  reshuffles.
- **B2. Duplicate note**  ·  S — reuse the template copy path
  (`_copyCompanions`) to clone a note in place. One ⋮ action.
- **B3. Bulk select on the grid**  ·  M — long-press a card → selection mode →
  archive / move / delete / favourite many at once.
- **B4. Note tags / colours**  ·  M — lightweight labels for cross-notebook
  grouping (a `note_tags` table or reuse the tasks `labels`), filter the grid by
  tag. Overlaps with Favourites/pinning — decide the taxonomy.
- **B5. Swipe actions on note cards**  ·  S — swipe a grid card to archive/
  favourite (mirrors the tasks swipe-to-archive).
- **B6. Recently-deleted / restore**  ·  M — notes already have `archivedAt`;
  wire notes+notebooks into the existing **Archived** screen (was deferred in
  Notes Phase 2) so deletes are recoverable.

## C. Brainstormed — reading long notes

- **C1. Outline / jump-to-heading**  ·  M — a table-of-contents sheet built from
  the note's headings (reuses `sectionRanges`); tap to scroll. Pairs with A7.
- **C2. Sticky current heading**  ·  M — the active section heading pins under
  the AppBar as you scroll a long note.
- **C3. Collapse persistence + collapse-all/expand-all**  ·  S — once A7 exists,
  a ⋮ toggle to fold/unfold every section.

## D. Brainstormed — photos

- **D1. Multi-photo gallery block**  ·  L — group several photos into one
  horizontally-scrolling block (a `gallery` block type referencing N filenames,
  or a `groupId` on photo blocks) so 4 vent screens take one card's height, not
  four. Biggest lever for the "too tall" problem; pairs with A1.
- **D2. Photo captions**  ·  S — optional caption text under a photo (reuse the
  block's `content` for filename + a new `caption` column, or a paired text
  block).
- **D3. Photo edit v2**  ·  S — annotate/markup (draw on a wound photo); extends
  the existing crop (image_cropper) with a draw layer or a second package.

## E. Rich text Phase 2 (already deferred)

Word-level inline styling, arbitrary text **colour** + font **size**,
underline/strikethrough — needs a real editor engine (flutter_quill /
super_editor / appflowy_editor). The current block-level formatting was the
deliberate Phase-1 that avoided this rewrite. Big (L); revisit when block-level
proves insufficient.

## F. Templates Phase 2 (already noted)

Template **categories/folders**, **variables/placeholders** (auto-number beds,
`{date}` tokens), a per-notebook **default template**. Favourite templates (A3)
is the cheap first step.

---

## Suggested next pick (opinion)
If resuming notes work, the highest value-to-effort cluster for the user's
clinical use is **A7 (collapse under headings) + A8 (fast reorder) + A1/D1
(shrink/gallery photos)** — together they tame long, photo-heavy rounds notes.
**A6 (search)** is the other clear win once there are many notes. Favourites
(A3/A4) and cover-photo (A2) are cheap, satisfying quick wins.
