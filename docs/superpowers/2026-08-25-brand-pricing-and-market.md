# Brand, pricing and market study

**Date:** 2026-08-25 · Asked for after v1.17.0, when the question turned from
"does it work" to "can strangers pay for it".
Readable version: published as an Artifact (*Uplan Goes Public*).

---

## 1. The name

| | Finding |
|---|---|
| **Uplan** | **Already on Google Play** — `app.uplan.android`, an event-organising marketplace (uplan.ge, Georgia). Different category; Play does not require unique names, so coexistence is possible. Cost is **search collision**, not legality. |
| **Unote** | Crowded: `uNote`, `Unotes`, `uNotes`, `UniNote` all exist. Worse, **UpNote** is an established note app — "Uplan → Unote" lands one letter from it *in its own category*. |
| **"U" prefix as a family** | Weak. One letter carries no distinctiveness, is trivial to copy, impossible to defend, and is already worn out here. |
| **Trademark** | **NOT VERIFIED.** App-store availability says nothing about registered marks. Needs a real search of the registries we'd operate in (USPTO / EUIPO / Saudi SAIP) before any paid marketing. |

**Decision taken:** keep **Uplan** for this app (built, shipped, in the Codex;
conflict is in another category). **Do not build a "U" family** — make the
family a *publisher/studio* name and give each app its own real name.

## 2. Backlog, excluding cloud sync

- **Big rocks:** iOS · subtasks · recurring tasks (habit→task merge) · stylus
  notes module · performance pass.
- **Queued (user's order):** quick-wins bundle → G2 de-clinicalise → G4 alarm
  research.
- **Notes polish (A–F):** ~16 items, mostly small; A9 side-by-side blocks and
  E word-level rich text are the large ones.
- **Parked/minor:** Z Flip cover screen (Route A) · tracker templates · gym
  program auto-import · Assistant shortcuts · G3 coach polish.

**Observation that matters for pricing:** nothing on that list is a *gap a new
user would hit*. Uplan is already more complete than most paid apps in the
category — we are not waiting on features to be worth money.

## 3. Market evidence

| App | Price | Free tier | Complaint |
|---|---|---|---|
| Todoist | $5/mo (≈$60/yr) | 5 projects | Cap reads as a forced upgrade; price rose Dec 2025 |
| TickTick | $35.99/yr, $3.99/mo | 9 lists, 99 tasks/list, 5 habits | **Calendar view paywalled** — the most resented pattern in the category |
| Structured | $9.99/yr, **$29.99 lifetime** | Core day planner | Lifetime is possible *because its costs are local* |
| Habitica | $47.99/yr | **Everything** (sub is cosmetic) | Almost no pricing complaints — nothing needed is behind it |

**Sentiment themes** (second-hand — reddit.com is blocked to our crawler, so
this comes from aggregators quoting it):
1. Paywalled **views** feel punitive in a way paywalled capacity does not.
2. **Complexity creep** — quoted user: *"spending more time in the app than
   actually doing tasks."*
3. **Sync failures** are the top functional complaint — and the thing people
   most willingly pay for when it works.
4. These apps are **quit, not switched**. Retention is the game.

Benchmarks: freemium converts **2–5%** (5–10% good); hard paywalls convert far
better short-term but shrink the funnel badly.

## 4. Monetisation

**The principle — charge for what costs money to run, never for what runs on
the phone.** Honest, explainable in one sentence, and it cannot drift, because
it is a cost decision rather than a marketing one.

- **Free, permanently:** everything shipped today — tasks/lists/labels, notes +
  photos + templates, habits, trackers, workouts, shift rota, widget, live
  notification, archive + 30-day bin, JSON backup, Codex, guided tour.
- **Uplan Plus — $2.49/mo · $17.99/yr** (deliberately ~half TickTick): cloud
  sync, cloud backup with history, photo sync (the one thing JSON backup can't
  carry), later web access + shared lists. Regional pricing on.
- **Supporter tip ~$4.99 one-time**, unlocks nothing but a badge — a way to pay
  for the majority who will never need sync.

### Two open decisions (flagged to the user, not decided for them)
1. **No lifetime plan for sync.** Lifetime converts brilliantly and users love
   it, but a one-off price against a permanent server bill is a cost carried
   forever with no further revenue. Structured can do it because its costs are
   local; ours would not be. Any one-time option must cover local-only extras.
2. **Revenue doesn't start until sync ships**, and only converts multi-device
   users — a small slice. The alternatives are worse: paywalling local features
   is the exact trap people quit over, and paid-upfront kills growth.
   Recommendation: accept the slow start, ship the tip jar early, treat Plus as
   funding the servers rather than funding the developer.

### Blocking work before any of this goes live
- Privacy policy + Play data-safety form (cloud sync collects everything).
- **G4 stops being research and becomes blocking**: `USE_EXACT_ALARM` is
  restricted to alarm/calendar apps and we declare it today.
- A real signing keystore — builds are debug-signed.
- The G2 copy pass, so a first-time user never meets "ICU1".
