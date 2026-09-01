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

## 4. Monetisation (revised 2026-08-25 after user pushback)

> *"either we add more value behind the pay wall or something, its not enough
> to rely on donations and cloud payment, but i also want for the free version
> to offer a better experiance than other payed app"*

Those two goals only conflict if the paywall works by **taking things away**.

### The promise (put this on the store listing)
> **Nothing that works in Uplan today ever moves behind a paywall. Everything
> paid is something that did not exist before.**

It is the exact inverse of what people quit TickTick/Todoist over, and no
competitor can copy it without unwinding their own business. It is also
protection against our own future self: every one of these apps drifted because
moving one existing feature across the line is always the cheapest way to raise
the number.

### Three tiers, split by what the feature costs US
| Tier | Price | Contains | Why this pricing model |
|---|---|---|---|
| **Uplan** | Free forever | Everything shipped through v1.17 | — |
| **Uplan Pro** | **$29.99 one-time** | Themes/icons/widget skins · multiple Home dashboards · smart lists (saved filters) · Insights (habit/workout/shift history) · export PDF/CSV/ICS | Local: costs build time, then nothing. A one-time price is honest, and it is NOT the lifetime-vs-server-bill trap. |
| **Uplan Plus** | **$3.49/mo · $29.99/yr** | Everything in Pro + cloud sync, cloud backup history, photo sync; later web, shared lists, AI | Costs servers and per-use compute → must recur |
| *Supporter tip* | $4.99 one-time | A badge, nothing else | Catches people who need none of the above |

**Pro is the answer to the objection.** A sync-only paywall converts one slice
— people with 2+ devices. Most users have one phone and would never pay under
that model.

### Correction to earlier advice
Previously recommended **$17.99/yr to undercut TickTick**. That was wrong.
Undercutting is how you compete when your free tier takes hostages and the bill
breeds resentment — ours doesn't. With a complete free tier, a payer is a
willing power user, not a captive. Halving the price sacrifices half the
revenue for no strategic gain, while Plus still funds servers for every free
user. **Price at parity: $29.99/yr.** Enable Play regional pricing.

### Build order, if the goal is revenue
| Feature | Tier | Build | Why it converts |
|---|---|---|---|
| Themes & icons | Pro | S | Cheapest on the list; Habitica's entire sub is cosmetic |
| Insights | Pro | M | Months of habit/workout/shift history already stored and never shown back — value sitting unspent in the DB |
| Smart lists | Pro | M | What power users ask for and pay to stop rebuilding by hand |
| **Rota photo → shifts (OCR)** | Plus | L | **Sharpest differentiator.** Shift workers get printed/photographed rotas; nothing on the market turns that into a filled calendar. Needs OCR → earns its subscription honestly |
| Calendar sync | Plus | L | Most-requested integration in the category; a standing reason people won't switch |

**Ship Themes + Insights BEFORE cloud sync** — no server needed, so the app can
earn this year rather than whenever Supabase is done, and it tests whether
anyone pays at all before we commit to running infrastructure.

## 5. Revenue reality (honest arithmetic)

Play takes **15%** of the first $1M/yr. Freemium converts **2–5%**; with a free
tier this complete, plan for the **bottom** of that range — that is the real
cost of the strategy (more goodwill and installs, lower % paying).

| MAU | Payers @2% | Gross/yr @ $29.99 | After Play |
|---|---|---|---|
| 5,000 | 100 | $3,000 | ≈ $2,550 |
| 25,000 | 500 | $15,000 | ≈ $12,750 |
| 100,000 | 2,000 | $60,000 | ≈ $51,000 |

**The lever is users, not price.** $17.99 → $29.99 is +67%; 5k → 25k users is
+400%. That is precisely why a free tier beating paid rivals is a *revenue*
strategy, not charity.

**Said plainly:** at a realistic first-year solo scale with no marketing budget
this is server money, not an income. Only two things move that ceiling:
1. **Reach** — everything scales with installs. Honest and slow.
2. **Sell to workplaces** — shared rotas and shift swaps for a ward/restaurant/
   store, per seat, where $60/user/yr is unremarkable. We already have the rota
   engine nobody else has. Different product, different support burden — a fork
   in the road, not a feature.

### Blocking work before any of this goes live
- Privacy policy + Play data-safety form (cloud sync collects everything).
- **G4 stops being research and becomes blocking**: `USE_EXACT_ALARM` is
  restricted to alarm/calendar apps and we declare it today.
- A real signing keystore — builds are debug-signed.
- The G2 copy pass, so a first-time user never meets "ICU1".
