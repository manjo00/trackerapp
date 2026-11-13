# Morning and night du'a counters: design

**Date:** 2026-11-13 · **Chat:** duaa-counters, a side chat of the Uplan chat (branch `claude/duaa-counters-a7d503`)
· **Path:** demo first (no schema change, his own app, small blast radius). The Uplan chat merges it with the other
side chats; the Tester tries the merged build on the emulator before Ahmed gets the install offer.

## 1. What he asked for
"i want to add morning and night duaa trackers with clickable counters" (Ahmed, 2026-11-13). The plan he saw: two
habits, Morning and Night, each opening his list of du'as with a tap counter on each one; the habit ticks itself when
all are done; the text comes from him so it is exactly right.

## 2. Decisions
| Decision | Who |
|---|---|
| The lists are the Instagram post he sent (instagram.com/p/DQULTezDYgG, "أذكار الصباح والمساء", 15 pictures, 27 Oct 2025); Night = its evening (المساء) list | Ahmed, 2026-11-13 ("this post") |
| Look B, one du'a at a time, tap anywhere | Ahmed, 2026-11-13 ("B") |
| No moving on by itself: at the count, a strong buzz and a pop-up; extra taps do nothing until he closes it; closing opens the next du'a | Ahmed, 2026-11-13 ("am not gonna look at the screen so the next page wont count extra by mistake") |
| The post is pictures, so the text is the same du'as typed in Hisn al-Muslim (hisnmuslim.com/api/ar/27.json), cut by a script in the post's order, splits and counts; nothing typed by hand except the post's vowels on one word (وشِركِهِ, picture 10) and its heading الإستغفار (picture 14) | Claude's call; Ahmed checked the text against his post on the looks page: "It matches" (2026-11-13) |
| Pictures 13 and 15 (×100) carry no morning/evening label, so both lists have them (the book says the second is for the morning) | Claude's call, flagged to him |
| The pop-up comes after every du'a, ×1 included (one rule; a ×1 du'a costs one extra tap) | Claude's call, flagged to him |
| The lists are built into the app; changing a du'a is a code change | Claude's call (no schema change; in-app editing can come later) |

## 3. Approaches considered
1. **Built-in lists, counts kept for today only (picked).** The lists live in `adhkar_lists.dart`; each du'a habit is
   a count habit whose day value is the number of du'as finished. Today's per-du'a counts live in SharedPreferences
   (one key per habit, today only). No database change; the habits engine (partial, kept, streak, spare days,
   strength) works unchanged.
2. **Lists he can edit in the app.** A new table of du'as per habit and a list editor: schema 28 (the Uplan chat's and
   the Tester's OK), backup changes, about 1–1.5 h more. Not needed for a list that rarely changes.
3. **Per-du'a counts in `habit_completions.note`.** One row, in backups, but it takes over a column meant for a day
   note. Rejected for that.

## 4. How it works
- **The two habits** are added once, by the launch work in `app.dart` (a SharedPreferences flag, so one he deletes
  never comes back): "Morning du'as" (Wake-up, sun icon, amber) and "Night du'as" (Before sleep, moon icon, indigo).
  Both: count kind, goal = the list's length (21 and 19), unit "du'as", step 1, every day, 1 spare day a week (the
  editor's default for an every-day habit), `autoSource` 'adhkar:morning' / 'adhkar:night'. The launch work also keeps
  each goal equal to its list's length. The habit day still starts at 04:00, so night du'as said at 01:00 count for
  that night.
- **The counter** (`/habits/adhkar`, Look B): the du'a's short name and full Arabic text (right to left), a big ring
  with "2 / 3", "Tap anywhere to count". Each tap gives a light tick. At the count: a strong double buzz (the
  phone's vibrator through the new `uplan/haptics` channel, since the system's touch ticks are short and can be
  switched off) and the pop-up; its Next button wakes up after 0.8 s, so a reflex tap can't skip ahead. Closing it
  opens the next unfinished du'a; the last one says the list is done and closes the screen. Also: arrows to move,
  −1 to take back a tap, a list to jump to any du'a, "Start again" (with a confirm).
- **Saving:** every tap saves today's counts; when the number of finished du'as changes, the habit's day value is
  saved too (0 removes the day). Leaving halfway keeps the place until the habit day ends. If today was marked done
  somewhere else (the live notification), the counter opens with every du'a done.
- **The habit row:** for a du'a habit on today, the row's tap and its right-hand button open the counter. On a past
  day picked in the week strip (the habit-yesterday chat's work) the row keeps its normal + and typed amount, so he
  can mark a forgotten day without 337 taps.

## 5. Not in this demo
Editing the lists in the app, a text-size setting, audio, a Home block for the du'as (the habits design's demo 2
covers the Home offer), reminders beyond the habit editor's own.

## 6. Testing
Test-first: the lists (counts, totals, unique ids, and a hash of the text, so no change to it slips through
unnoticed); the counting rules; adding the habits once and syncing their goals; the counter screen (tap counts, the
pop-up blocks taps and its button waits, Next opens the next du'a, the last one finishes the habit, counts survive
leaving); the row opens the counter today and not on a past day. Analyze clean, the full suite once at the end. The
Kotlin buzz is compiled first by the Tester's merged build and felt first on Ahmed's phone.

## 7. Files
New: `lib/features/habits/domain/adhkar_lists.dart` (generated by `tool/adhkar/build_adhkar_lists.py`),
`domain/adhkar_progress.dart`, `data/adhkar_setup.dart`, `presentation/providers/adhkar_providers.dart`,
`presentation/screens/adhkar_screen.dart`, `presentation/adhkar_haptics.dart`,
`android/.../UplanHaptics.kt`, tests. Changed: `widgets/habit_row.dart` (the open-the-counter check, agreed with the
habit-yesterday chat), `lib/core/router/app_router.dart` (one route), `lib/app.dart` (one launch call),
`UplanEngineSetup.kt` (one line); the shared ones announced to the Tester.

## Status
- 2026-11-13: lists read from his post and built from the book's typed text (Morning 21 du'as, 337 taps; Night 19,
  236 taps); looks page https://claude.ai/artifact/4vn3JS5yYEQv9ed3SjrHM4 (private); he picked B with the buzz and
  the pop-up.
- 2026-11-13 evening: **built** on `claude/duaa-counters-a7d503`, on top of the habit-yesterday chat's `0561791`
  (its row shows past days; the du'a check is written against it: the counter opens only when `view.day == null`).
  37 new tests (lists and fingerprint 6, rules 8, saving and setup 10, counter screen 9, row 4; each file seen failing
  first, except the jump-list test, written after its code), analyze clean. The generated lists' fingerprint (`ff410dd2`) equals the looks page's data.
  **Not tried yet:** the emulator (the Tester, after the Uplan chat's merge), the Kotlin buzz (first compiled by that
  build, first felt on his phone).
- 2026-11-13: Ahmed checked both lists' text on the looks page against his post: "It matches". The text in the app is
  the same (fingerprint `ff410dd2`, pinned by `adhkar_lists_test.dart`).
- **Manual Test Steps for Ahmed, after the install:** 1. Open Uplan, then Menu › Habits: "Morning du'as" sits under
  Wake-up and "Night du'as" under Before sleep, each "0 of 21" / "0 of 19 du'as". 2. Tap Morning du'as: Ayat
  al-Kursi fills the screen with "0 / 1". 3. Tap anywhere: a strong double buzz and a "Done" pop-up; tap the screen a
  few more times, nothing counts. 4. After a moment tap "Next du'a": Surat al-Ikhlas, "0 / 3". 5. Count it without
  looking: the buzz tells you it's done. 6. Go back: the row says "2 of 21 du'as". 7. Close Uplan fully and open the
  counter again: it opens on Surat al-Falaq, where you stopped.

## Noticed (not fixing now)
- The Planner's tap on a count habit saves 1, and the home-screen widget counts any amount of a count habit as done
  (both left for the habits design's demo 4), so a du'a habit with one du'a done shows as done there.
- The text uses the phone's own Arabic font. A bundled font (Amiri or Noto Naskh Arabic) would draw the vowel marks
  the same on every phone; his call after he sees it.
