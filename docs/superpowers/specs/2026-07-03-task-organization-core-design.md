# Task Organization Core — Design Spec

**Date:** 2026-07-03 · **Status:** approved by user (sections 1–2 verbally; this doc is the review copy)
**Slice 1 of the task-management depth bundle** (later slices: Home block engine
= saved filters, deadlines, time blocks, automatic backups).

## Context

Uplan's tasks are a flat pool with dates and priorities. The user wants
Todoist-grade organization: containers holding tasks grouped into sections,
cross-cutting labels, and — replacing the Inbox concept — a **Home** dashboard
as the app's landing view. Decisions were made in a brainstorming session on
2026-07-03; this spec captures slice 1 only.

## Locked decisions

1. **Slice 1 scope:** lists + sections + labels + tab restructure + Home v1
   (fixed layout). Saved filters / customizable Home blocks = slice 2.
2. **Naming:** the container is called **"List"** as a placeholder the user
   may replace. All UI copy reads it from `kListNoun` / `kListNounPlural`
   (single point of change). Code identifiers use `list`/`TaskList`.
3. **No Inbox anywhere.** Not a row, not a tab. A task with `listId == null`
   is "**Captured**" and surfaces in Home's Captured block. (Approach A:
   "Inbox is the absence of a list" — no magic rows, trivial migration,
   undeletable by construction.)
4. **Default tabs: Home · Lists · Planner.** Home is the landing tab and
   absorbs Today's role; the Today screen remains, moved to the drawer and
   togglable back via Settings→Tabs. Old flat Tasks screen is replaced by the
   Lists tab ("All tasks" built-in view covers it).
5. Labels apply to **tasks only** in v1 (extensible later).

## Data model (schema v10 → v11)

New tables (Drift `m.createTable`, never raw SQL):

| Table | Columns | Notes |
|---|---|---|
| `task_lists` | id PK, name (1–80), colorValue int, orderIndex int, createdAt | user containers |
| `list_sections` | id PK, listId FK→task_lists **CASCADE**, name (1–80), orderIndex | deleting a list deletes its sections |
| `labels` | id PK, name (1–40), colorValue int, orderIndex | |
| `task_labels` | taskId FK→tasks **CASCADE**, labelId FK→labels **CASCADE** | junction; PK (taskId, labelId) |

`tasks` gains (`m.addColumn`):
- `listId` int nullable FK→task_lists **SET NULL**
- `sectionId` int nullable FK→list_sections **SET NULL**

Deletion semantics (all enforced by FK actions, no app code needed):
- Delete list → its sections die, its tasks fall back to Captured
  (listId NULL; sectionId also nulled via section cascade→SET NULL on tasks).
- Delete section → tasks stay in the list, section header disappears.
- Delete label → tag removed from all tasks.

Migration for existing users: nothing to do — existing tasks have NULL
listId ⇒ all land in Captured. FKs already ON (beforeOpen pragma).

**Invariant:** a task's `sectionId` must belong to its `listId`; enforced in
the repository (changing a task's list clears its section unless a new
section in the target list is picked).

## Navigation & routing

- `AppTab` enum: `inbox` → **`home`** (icon: home), `tasks` → **`lists`**
  (icon: folder/list). Branch order preserved (indexes stable).
- Defaults: `{home, lists, planner}`. Settings migration **v3**
  (`_currentSettingsVersion = 3`): stored tab names `inbox`→`home`,
  `tasks`→`lists`; if stored set was the old default trio, reset to new
  defaults; Today remains available via Settings→Tabs + drawer.
- Router: `/inbox` branch becomes `/home` (HomeScreen), `/tasks` becomes
  `/lists` (ListsOverviewScreen) with sub-route `/lists/:id` (ListDetailScreen).
  Full-screen add/edit task routes gain optional `listId`/`sectionId` params.

## Screens

**HomeScreen (v1 — fixed layout, no customization UI yet):**
1. *Urgent* — overdue OR (priority==high AND due within 2 days), red accent.
2. *Due today* — today's incomplete tasks (all lists).
3. *Captured* — `listId == null`, incomplete; quick-add lands here.
4. *This week* — compact 7-day strip (date + count + first task names).
Blocks with no content collapse to nothing; "All clear 🎉" empty state.
Reuses existing `TaskTile`.

**ListsOverviewScreen:** built-in "All tasks" row (flat, incomplete-first —
replaces old Tasks screen), then user lists as rows/cards (color dot, name,
incomplete count), reorder via long-press later (orderIndex now), "+ New
list" (name + color picker, reuse widget-settings color pattern).

**ListDetailScreen:** AppBar = list name (rename/recolor/delete via menu —
delete confirms "tasks return to Captured"). Body: unsectioned tasks first,
then each section as a header (rename/delete via long-press menu) with its
tasks. "+ Add section" at bottom. FAB "+ task" pre-assigns listId (and
sectionId when tapped from a section header's "+").

**Task editor (add/edit):** new "List" picker row (default: none/Captured;
pre-filled when opened from a list) → when a list is chosen, optional
Section dropdown; **Labels** chip row (multi-select, inline "+ new label"
with name+color). Chips show label colors.

**Quick-add sheet:** compact list chip (default Captured) — one tap to file
at capture time; labels not in quick-add v1 (YAGNI).

**TaskTile:** shows list name in the subtitle line (muted) when the tile is
rendered outside its own list; label chips shown in ListDetail + editor only
(keeps Home/Planner tiles clean).

## Ripple effects (must update in the same slice)

- `inboxTasksProvider`/DAO `watchInboxTasks` (dueDate-based) → replaced by
  `capturedTasksProvider` (`listId IS NULL AND !isCompleted`).
- **Live notification**: card type `inbox` now means Captured (query change
  in `LiveDashboardService.syncCards` + `live_background_callback.dart`
  complete-action unchanged — same tasks table).
- **Home-screen widget**: `today_counts` unchanged; agenda unchanged.
- **BackupService**: exports all tables via `db.allTables` — picks up the
  four new tables automatically; verify FK-safe restore order includes
  task_lists/list_sections/labels before tasks/task_labels.
- Drawer: "Tasks — All your tasks" entry becomes "`kListNounPlural`".

## Testing (per CLAUDE.md: tests alongside non-trivial logic)

Unit tests (in-memory Drift):
1. Migration v10→v11 keeps existing tasks, all Captured.
2. Delete list → tasks' listId/sectionId NULL, sections gone.
3. Delete section → task stays in list, sectionId NULL.
4. task_labels CASCADE on task delete and label delete.
5. Repository guard: moving task to another list clears stale sectionId.
6. Captured query excludes tasks with a list, includes dated captured tasks.

## Definition of done

flutter analyze clean · build_runner run · tests pass · manually verified on
the Flip 6 (🧪 steps at end of implementation) · settings migration verified
(old tab prefs → new) · conventional commits per phase · CLAUDE.md updated
(schema v11, nav structure, feature table).

## Out of scope (later slices — recorded so they're not lost)

- **Slice 2 — Home block engine = saved filters:** block catalog (label
  block, list block, week view, pinned task/list, habits block, workout
  block, "all tasks"), add/remove/reorder, per-block config. One engine
  powers Home blocks AND a saved-filter browser in Lists.
- **Deadlines** (separate from do-date, Todoist-style) — small tasks column.
- **Time blocks** in Planner.
- **Automatic backups** (scheduled JSON export, keep last N).
- **Integrations (Zapier/Notion)** — blocked on cloud sync: Supabase
  webhooks → Zapier; Zapier → Supabase REST → device via sync. Direct
  Notion API sync possible via Supabase Edge Function later.
- **AI features** — blocked on cloud sync for the key-safe path (app →
  Supabase Edge Function → Claude API): NL quick-add parsing, task
  breakdown, weekly summaries, workout progression. On-device (Gemini
  Nano) revisit later.
