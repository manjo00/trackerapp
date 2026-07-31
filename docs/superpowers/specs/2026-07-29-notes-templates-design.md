# Notes Templates + Insert-Anywhere — Design

**Date:** 2026-07-29
**Status:** APPROVED (user confirmed create=both, use=both, insert=after-current-line; + fix the format bar hiding behind the keyboard).
**Origin:** User request — pre-made note structures for fast repeated notes (e.g. assigned to ICU 1 with 3 beds → one template yields a note pre-split into 3 bed rounds), plus the ability to choose where a new block lands instead of always appending.

## Decision — templates are flagged notes
A template is just a **note with `isTemplate = true`**. It is hidden from
normal notebooks and lives in a **Templates** area, but opens in the *same*
block editor — so building a template uses all the existing formatting,
headings, checkboxes, dividers, photos. "Using" a template **copies its blocks**
into a target note. No parallel data model or editor.

## Keyboard-accessory toolbar (fixes the hidden-format-bar bug + enables insert-after-current)
Today the toolbar lives in `Scaffold.bottomNavigationBar`; on device the format
row can sit under the keyboard. **Fix:** render the toolbar as the bottom of the
editor **body** — an `Expanded` scroll area above a bottom toolbar — with
`resizeToAvoidBottomInset: true`. The toolbar then sits **directly on top of the
keyboard** and descends with it; note content scrolls in the space above.

The toolbar is **two stacked rows** (whole thing wrapped in `TextFieldTapRegion`
so tapping never unfocuses the line):
- **Format row** — shown only while a text/checkbox line is focused: heading
  cycle (Body/H1/H2/H3, text only) + Bold / Italic / Highlight toggles
  (reflect the line's flags). *(Unchanged controls — just relocated + always
  above the keyboard.)*
- **Add row** — always shown: Text · Checkbox · Photo · Divider · **Templates**
  (insert-template). These now **insert after the focused line** (or at the end
  when nothing is focused), and focus the new text/checkbox block.

## Insert-after-current
`_addBlock(type)` inserts after `_focusedBlockId` (via the existing
`insertBlockAfter`, extended to carry formatting defaults) when a block is
focused, else appends at the end; then focuses the new block. Divider inserts
after too (no focus change). Cursor on "Bed 1" → tap Checkbox → checkbox appears
right under Bed 1.

## Data model — schema v18
- `notes.isTemplate` BOOL default false. Templates carry `notebookId = NULL`.
- **Exclude templates** from active note views: `watchNotes(notebookId)` and
  `watchLastNoteEditByNotebook` add `isTemplate = false`. New
  `watchTemplates()` returns templates, newest-edited first.
- Backup: the new column rides along via `allTables`/`fromJson` (no code change).

## Operations (NotesRepository, photo-aware)
- `saveAsTemplate(noteId, now) → templateId` — new template note; copies the
  source note's **title + every block** (type, content, checked, and the v17
  formatting flags), with **photo files duplicated** so template and source
  never share a file.
- `newNoteFromTemplate(templateId, {notebookId, now}) → noteId` — new normal
  note in `notebookId`; same copy (photos duplicated). Opens in the editor.
- `insertTemplateInto(templateId, targetNoteId, afterOrderIndex, now)` — copies
  the template's blocks into an existing note after a position (shifting later
  blocks down), photos duplicated.
- Shared `_copyBlocks(from, to, atOrderIndex)` builds `NoteBlocksCompanion`s
  (duplicating photo files first) and calls a batch DAO insert.

### DAO
- `createNote(... , bool isTemplate = false)`.
- `watchTemplates()`.
- `insertBlocksAt(noteId, atOrderIndex, List<NoteBlocksCompanion>)` — one
  transaction: shift existing blocks `>= atOrderIndex` by N, insert the batch.
- `insertBlockAfter` extended to accept the formatting flags (defaults preserve
  today's behaviour: body/unformatted).

### ImageStorageService
- `duplicate(String filename) → String newFilename` — copies the backing file
  to a fresh filename (returns it); used when copying photo blocks.

## UI
- **Notes overview:** a **Templates** tile (📄, under Unfiled) → `/notes/templates`.
- **TemplatesScreen:** lists templates (title + preview), **New template** FAB
  (creates an `isTemplate` note, opens editor), tap → edit in the normal editor,
  ⋮ → rename / delete.
- **Notebook detail + Unfiled `＋`:** if any templates exist, the FAB opens a
  sheet — **Blank note** or a template (→ `newNoteFromTemplate` into this
  notebook, open). No templates → creates a blank note directly (today's
  behaviour).
- **Editor ⋮:** **Save as template** (→ `saveAsTemplate`, snackbar "Saved to
  Templates"); **Insert template** (picker → `insertTemplateInto` after the
  focused line / at end).
- **Add row Templates button** = the same Insert-template picker.

## Invariants
- `content` untouched by any of this; `@time` linking, backup, snippet, search
  unaffected. Templates never appear in notebooks, Home recent-notebooks, or the
  grid. Empty-note prune + auto-delete still apply (a blank template with no
  title/blocks self-deletes on exit — don't leave one empty).

## Pure helpers (unit-tested)
- Copy correctness is tested at the DAO/repo level (blocks + formatting +
  order + template exclusion), not via a pure helper — the logic is DB-shaped.
- Reuse existing tests; add: templates excluded from `watchNotes`; copy
  preserves formatting + order; `insertBlocksAt` shifts correctly.

## Out of scope (later)
Template categories/folders, variables/placeholders (e.g. auto-number beds),
sharing templates, per-notebook default template, a template gallery.
