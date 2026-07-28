# Notes Photo-Grid Redesign — Phase 1 Design

**Date:** 2026-07-28
**Status:** Design APPROVED (direction confirmed by user); spec pending final review, then writing-plans → build.
**Origin:** `feedback/app.md` → "A NEW NOTE DESIGN CLOSER TO SAMSUNG'S OR APPLE'S NOTES APPS".

## Why
The current notebook-detail note list is a flat stack of dark-gray cards on a
near-black background: monochrome, cramped, a run-on truncated text preview, and
— worst for the user (a hospital worker doing photo-heavy rounds) — **photos are
hidden behind a count** ("🖼 3"). Their notes *are* photos + a short line
(vent screens, secretions, wounds). Seen on-device 2026-07-28 (notebook
"Ticu 27 july": Bed 9 / Bed 15 / Bed 10 / Bed 14, each with 1–4 photos, none
visible).

## Direction (confirmed)
**Samsung-style 2-column photo grid.** Grid-first, Phase 1 = the note list only.
Pure UI — **no schema/data change**; same notebooks/notes/blocks underneath.

## Phase 1 scope — the note grid
Replaces the vertical `NoteTile` list in **notebook detail AND Unfiled** (same
`_NoteRow`/`NoteTile` path in `lib/features/notes/presentation/`).

**Layout:** a 2-column `GridView` of portrait cards (~3:4). FAB + nav unchanged.

**Card anatomy (top→bottom):**
- **Photo header** (~top 60% of the card): the note's **first photo block**,
  `BoxFit.cover`, rounded top corners.
  - **No photo →** a solid cover tinted with the **notebook's colour** + a big
    faint icon (or the title's first letter).
  - Missing file → same colored-cover fallback (never a broken image).
- **Body** (padded): **title** (bold, 1 line, ellipsis) · **snippet** (1 line,
  muted — first non-photo block text) · footer (tiny: relative date + "🖼 N").

**Feel:** card surface a step lighter than the background (real contrast),
16px rounded, subtle elevation, 12px gaps. Tap → editor (unchanged).

**Scope decisions (defaulted, user OK):**
1. **Grid-only** (no list/grid toggle) — photo-heavy content, grid always wins;
   a toggle can be a later phase.
2. **Uniform card heights** (not staggered/masonry) — simpler; masonry later.
3. Applies to **both** notebook detail and Unfiled.

## Data
Each card already watches `noteBlocksProvider(noteId)` (in `_NoteRow`) to build
the snippet + photo count. Extend that to also grab the **first photo block's
filename**, resolved to a path via `imageStorageServiceProvider.resolvePath`,
rendered as an `Image.file` thumbnail. A pure helper
`notePreview(List<NoteBlock>)` → `(firstPhotoFilename?, snippet, photoCount)`
is the unit-testable core; the rest is visual (device-verified against the
"Ticu 27 july" screenshot).

## Files (anticipated)
- Modify `lib/features/notes/presentation/widgets/note_tile.dart` → a
  `NoteGridCard` (or rework NoteTile into a grid card).
- Modify `lib/features/notes/presentation/screens/notebook_detail_screen.dart`
  → `GridView` instead of `ListView`; `_NoteRow` supplies the first-photo
  filename too.
- New pure helper + test for `notePreview`.

## Phase 2 (deferred, not this spec)
Polish the Notes overview (notebook covers) + the editor (bigger title, calmer
spacing, paper feel). Optional list/grid toggle. Masonry heights.

## Out of scope
No schema change, no new dependency, no photo editing (that's a separate
backlog item — image_cropper).
