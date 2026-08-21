# Archive v2 — Recently Deleted + search inside the archive

**Date:** 2026-08-21 · **Target release:** v1.16.0 · **Schema:** v23

Backlog #28 ("Archive v1.1") plus two additions the user asked for on
2026-08-21: *"make sure to also add the ability to get stuff outside of the
archive"* and *"a search function that sees title and insides of an archived
thing"*, plus a **30-day Recently Deleted** bin ("like photos in the phone"),
decided with cloud sync and a Play Store release in mind.

---

## Goal

Nothing the user does in Uplan destroys data on the first tap. Every item has
three states, and every state has a way back out.

```
active  ──archive──▶  archived  ──delete──▶  recently deleted  ──30 days──▶  gone
   ▲                      │                        │
   └──────restore─────────┘                        │
   └──────────────restore (back where it was)──────┘
```

Covers the six archivable types: **tasks · lists · habits · trackers · notes ·
notebooks**. Workout and shift data are out of scope.

---

## Why soft delete is the right call for sync

A hard delete cannot be synced. Device B sees a row missing and has no way to
tell "deleted" from "never received" — so it re-uploads and the row comes back
from the dead. A `deletedAt` **tombstone** is just another column: it syncs
last-write-wins like everything else, and the row is only really removed once
every device has seen the tombstone.

So this design is a prerequisite for cloud sync, not a detour. (Purge in a
synced world needs one extra rule — only purge tombstones already pushed, and
keep them server-side longer than the local window — noted here, not built.)

---

## The invariant that keeps this safe

> **`deletedAt` is never set without `archivedAt`.**

Deleting a *live* item stamps **both** columns with the same timestamp.

This is what makes the change small. Every active query in the app already
filters `archivedAt IS NULL`, so a trashed item is invisible everywhere —
Today, Home, reminders, the widget, the live notification — **without editing a
single active query**. Only the six `watchArchived*` streams need
`& deletedAt.isNull()` added, so the Archived tab doesn't show trash.

It also encodes where an item came from, with no extra column:

| Timestamps | Was | Restore from trash puts it back to |
|---|---|---|
| `archivedAt == deletedAt` | live when deleted | **active** (clear both) |
| `archivedAt <  deletedAt` | already archived | **archived** (clear `deletedAt`) |

---

## Schema v23

Add nullable `deletedAt` (DATETIME) to: `tasks`, `task_lists`, `habits`,
`custom_trackers`, `notes`, `notebooks`. Six `m.addColumn()` calls; nothing to
backfill — NULL means "not deleted", which is true of every existing row.

Soft delete has a free bonus: a tracker's logs and a note's blocks are only
CASCADE-deleted at real purge time, so restoring brings the whole thing back
intact.

---

## Restore has to make the thing *visible*

Clearing a flag is not the same as getting something back. Restore therefore
repairs its own container:

- Restore a **note** whose notebook is archived → **restore the notebook too**
  (otherwise the note returns invisible).
- Restore a **task** whose list is archived → **restore the list too**.
- Restore a **notebook** → also restores the notes archived *with it*, matched
  by identical `archivedAt` (same stamp = archived in the same action).

Archiving a notebook takes its notes with it (user's choice, 2026-08-21) — so
archiving "Recipes" doesn't scatter 40 notes into Unfiled.

---

## Search inside the archive

One search field over **titles and contents**, across both tabs:

| Type | Title | Body that is also searched |
|---|---|---|
| Note | title | every text/checkbox/heading line in it |
| Notebook | name | the titles of its notes |
| Task | title | its note |
| List | name | the titles of the tasks in it |
| Habit | name | description |
| Tracker | name | description |

A result shows **the line that matched** underneath, so it's obvious why it
came up — that's the difference between a search and a filter.

Matching is a pure function over a flat `ArchivedItem` record
(`type · id · title · body · colorValue · archivedAt · deletedAt`), the same
shape as `searchCodex`, so it unit-tests without a database.

---

## Retention

**30 days**, counted from `deletedAt`. Each trash row shows the days left.
Purge runs on app launch (a plain query, `deletedAt < now - 30d` → real delete);
no background worker. "Empty trash now" is available in the tab's ⋮.

---

## UI

- `/archived` becomes two tabs: **Archived** · **Recently deleted**, with the
  search field above them.
- Habit and tracker tiles: swipe now **archives** with Undo (it deleted forever
  before). Delete stays reachable from the item's edit screen.
- Note editor ⋮ "Delete note" → **Archive note**; notebook ⋮ "Delete" →
  **Archive notebook**. Empty notes still auto-delete on exit — nothing to
  recover.

## Out of scope

Bulk select, per-type retention settings, restoring individual note blocks,
and the sync-aware purge rule.
