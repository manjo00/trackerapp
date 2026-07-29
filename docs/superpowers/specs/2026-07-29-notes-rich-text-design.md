# Notes Rich Text (Phase 1) — Design

**Date:** 2026-07-29
**Status:** APPROVED (direction confirmed by user).
**Origin:** `feedback/app.md` → "A NEW NOTE DESIGN CLOSER TO SAMSUNG'S / APPLE'S" (formatting: bold/color/size/H1–H3/highlight). User priorities: highlight first, then bold/italic/headings; "lighter set now, with plans of expansion"; also add a **divider** line to separate sections.

## Decision — block-level formatting (no inline markers)
Formatting applies to a **whole block** (the line the cursor is in), stored in
**dedicated columns** on `note_blocks`. This is deliberate:

- **No visible markers, no jank.** The resting editor stays as clean as it is
  now — the whole point the user fought for. Word-level markdown markers
  (`==x==`) were explicitly rejected.
- **Fits the architecture.** Formatting lives in columns, so `content` is
  untouched — the `@time`→task linker, JSON backup, note-grid snippet, and
  search all keep working with zero changes.
- **Highlighting a whole clinical line** (`Blood gas pH 7.10 critical`) is as
  useful as word-level for this user's rounds.

True **word-level** styling + text **color** + font **size** is **Phase 2**
(needs a heavyweight editor engine) — the "expansion" the user asked for.

## Data model — schema v17
Add to `note_blocks` (all default to "off", so existing blocks render as plain
body text — nothing to backfill):

| Column | Type | Meaning |
|---|---|---|
| `headingLevel` | INTEGER default 0 | 0 = body, 1/2/3 = H1/H2/H3 (text blocks only) |
| `highlighted` | BOOL default false | whole-line highlight background |
| `bold` | BOOL default false | whole-line bold |
| `italic` | BOOL default false | whole-line italic |

New block type: **`divider`** (added to `NoteBlockType`). `NoteBlockType.parse`
already falls back to `text` for unknown values, so older builds stay safe.
A divider has no content and no formatting — it renders a horizontal rule.

Backup: the four columns + the new type ride along automatically via
`allTables` export / `NoteBlock.fromJson` import (same as v16's
`autoArchiveCompleted`). No backup code change.

## Rendering
- **Text block:** builds its `TextStyle` from the flags —
  - font size by heading level: body 16, H1 26, H2 22, H3 19 (pure helper
    `noteHeadingFontSize(level)`);
  - weight: `FontWeight.w700` if heading or `bold`, else `w400`;
  - `FontStyle.italic` when `italic`.
  - When `highlighted`, the block is wrapped in a rounded `Container` with a
    translucent accent background (whole-line highlight).
- **Checkbox block:** same, minus heading (a heading checkbox is nonsensical) —
  so it honours `bold` / `italic` / `highlighted` only.
- **Divider block:** a padded `Divider` (thickness 1.5, `cs.outlineVariant`),
  not editable. Reordered / deleted via the existing **Edit lines** mode
  (`blockLabel` → "Divider"; the resting view shows just the line).

## Toolbar UX
The bottom bar becomes context-aware:
- **No line focused:** the current add-block bar — Text · Checkbox · Photo ·
  **Divider** (new).
- **A text/checkbox line focused:** a **formatting bar** — a heading control
  (Body / H1 / H2 / H3, e.g. a segmented control or cycle button; shown only
  for text blocks), plus **Bold**, **Italic**, **Highlight** toggles that
  reflect and flip the focused block's flags.

The editor tracks the focused block (id + flags) via an `onFocus(blockId)`
callback from the block widgets; toolbar actions call
`NotesDao.setBlockFormat(...)`. Because formatting is per-block, the toolbar
acts on the whole focused line — no text selection needed.

## Invariants (must not regress)
- `content` is never touched by formatting → `@time` linking, backup, search,
  note-grid snippet all unchanged.
- Auto-save, Enter-to-new-line (new lines inherit **body** style, unformatted),
  backspace-empty delete, Edit-lines reorder/delete, empty-note prune on exit.
- Photo crop, per-list auto-archive — untouched.

## Pure helpers (unit-tested)
- `noteHeadingFontSize(int level)` → double (16/26/22/19).
- `blockLabel` extended: `divider` → "Divider".
- `notePreview` unchanged but must **ignore divider blocks** (no content, not a
  photo) — add a guard + test so a divider never becomes a card snippet.

## Files
- Modify: `note_blocks_table.dart` (4 columns), `note_block_type.dart`
  (`divider` + parse), `app_database.dart` (schemaVersion 17 + migration),
  `notes_dao.dart` (`setBlockFormat`), block widgets (`text_block_view.dart`,
  `checkbox_block_view.dart` — style from flags + onFocus), a new
  `divider_block_view.dart`, `note_editor_screen.dart` (context-aware toolbar,
  focused-block tracking, add-divider, render divider), `block_label.dart`
  (+divider), `note_preview.dart` (skip divider).
- New pure: `note_text_style.dart` (`noteHeadingFontSize`).
- Tests: heading font-size helper, blockLabel divider, notePreview skips
  divider, DAO `setBlockFormat` round-trip.

## Out of scope (Phase 2)
Word-level inline styling, arbitrary text color, font-size picker, underline/
strikethrough, migrating inline to a real editor engine (flutter_quill /
super_editor / appflowy_editor).
