# Decisions Log

Dated decisions, who made them and why. Don't reopen one without new evidence.

Started on 2026-10-27 from decisions already written in the designs and the status notes; each entry names
its source. Where the source doesn't say who decided, the entry says so instead of guessing.

---

- **2026-07-28 · Notes editor: "a complete open note", no per-line chrome** (Ahmed). Build it clean and open, then iterate on the device. Source: `specs/2026-07-29-notes-editor-redesign-design.md`.
- **2026-07-29 · Rich text starts at whole-line formatting** (who isn't written). Headings, highlight, bold and italic per line now; word-level styling, colour and size wait, because they need a new editor engine. Source: `NOTES-ROADMAP.md` section E.
- **2026-07-29 · Templates: create both ways, use both ways, insert after the current line** (Ahmed). Also fix the format bar hiding behind the keyboard. Source: `specs/2026-07-29-notes-templates-design.md`.
- **2026-08-01 · Drag engine nesting is full, matching headings** (design approved; who isn't written). Source: `specs/2026-08-01-notes-drag-engine-design.md`.
- **2026-08-02 · Home v2 = batches E + A + B from the Home-polish brainstorm** (Ahmed). Source: `specs/2026-08-02-home-v2-foundation-design.md`.
- **2026-08-04 · Z Flip cover screen: the widget route is ruled out, the compact layout is parked** (parked by Ahmed). Samsung curates the cover-screen widget catalogue. Source: `specs/2026-08-04-flip-cover-screen-feasibility.md`, `NOTES-ROADMAP.md` G1.
- **2026-08-25 · Keep the name Uplan; no "U" family of apps** (recorded as "Decision taken"; who isn't written). Give a future publisher or studio its own name instead. Source: `2026-08-25-brand-pricing-and-market.md` section 1.
- **2026-08-25 · Three paid tiers split by what a feature costs to run, not by rationing** (revised after Ahmed pushed back). Source: brand study section 4.
- **2026-09-29 · Note card actions open by holding the card, not by swiping** (Ahmed). Swiping in a 2-column grid fights the neighbouring card. Source: `STATUS-2026-07-28.md`, 2026-09-29.
- **2026-09-29 · One global sort setting for notes, not one per notebook** (Claude's call, from Ahmed's ask for sorting by name, starred and date). Source: STATUS, 2026-09-29.
- **2026-09-29 · Starring a note doesn't count as an edit**, so it doesn't jump to the top (Claude's call). Source: STATUS, 2026-09-29.
- **2026-09-29 · General, non-clinical examples in user-facing text** (Working Style #11). Clinical shorthand stays only where it explains a behaviour, e.g. why "bed 7" is never read as a date. Source: STATUS G2, `NOTES-ROADMAP.md` G2.
- **2026-09-30 · Drop `USE_EXACT_ALARM`; ask for `SCHEDULE_EXACT_ALARM`, with an inexact fallback** (implemented; who decided isn't written). Play restricts `USE_EXACT_ALARM` to alarm-clock and calendar apps. Source: STATUS G4, commits b4cabcd and ff9e928.
- **Standing rule · Never change Smart App Control from a session** (recorded 2026-09-29). It is Ahmed's security choice, and turning it off can't be undone without resetting Windows. Source: STATUS, 2026-09-29.
- **2026-10-31 · Build tools go in `D:\dev`, outside AppData** (Claude's call, after Ahmed's OK to install them). D: survives a C: wipe, and a chat's writes under AppData stay inside the Claude app's private copy. Source: `docs/_Task_History.md`, 2026-10-31.
- **2026-10-31 · Stay on Flutter 3.44.9 for now** (Claude's call). The app was made on 3.44.0 and its pinned packages never moved; on 3.47.9 its code generators (analyzer 7.6.0) crash, so 3.44.9 builds v1.18.0 exactly as it was made. Upgrading Flutter and the generators is its own task. Source: `docs/_Task_History.md`, 2026-10-31.
