# Home Block Engine — Design Spec

**Date:** 2026-07-04 · **Status:** approved by user (design presented in chat)
**Slice 2 of the task-management depth bundle.** Long-term context: the app is
heading for the Play Store, so polish and no-surprise UX are part of the bar.

## Context

Slice 1 shipped HomeScreen v1 with four hard-coded blocks (Urgent, Due today,
Captured, This week). The vision from the slice-1 spec: Home is a
customizable dashboard where a block IS a saved filter. This slice builds the
engine — ordered, user-editable blocks — with a catalog of five configless
block types. Label/list blocks (which need per-block config) come in a later
slice, as does the saved-filter browser in Lists.

## Locked decisions

1. **v1 catalog:** the four existing blocks + a **Workout block** (user's
   priority). Label block, list block, habits block deferred.
2. **Edit UX — both surfaces:** long-press a block header on Home to drag it
   into a new position (fast path), and a pencil icon opens an **Edit Home**
   screen with the full controls (reorder handles, remove, add).
3. **Storage: preferences, not DB** (Approach A). The v1 blocks carry no
   per-block config, so a schema-v12 table would be an empty shell; the
   prefs→DB migration later is a one-time five-line read. YAGNI.
4. **Bonus in this slice:** a **startup tab** setting — which tab the app
   opens on (default Home).

## Block model

```dart
enum HomeBlockType { urgent, dueToday, captured, thisWeek, workout }
```

- Layout = ordered list of *enabled* types. Stored in SharedPreferences as a
  string list (`home_blocks`, names via `.name`), managed by
  `SettingsNotifier` like `visible_tabs`.
- Default (and fallback for unparseable values):
  `[urgent, dueToday, captured, thisWeek, workout]` — existing users keep
  their current order and gain the workout block at the bottom.
- A type absent from the list = removed. The Edit screen's "Add block" offers
  exactly the missing types. Duplicates and unknown names are dropped on load.
- Empty list is allowed (Home shows only the All-clear state + FAB).

## Home screen changes

- Body becomes a `ReorderableListView` over the enabled blocks;
  `buildDefaultDragHandles: false`, each block header wrapped in a
  `ReorderableDelayedDragStartListener` (long-press starts the drag). Drop
  persists the new order immediately via the settings notifier.
- Existing `_HomeBlock` rendering and the de-dupe rule (a task appears only
  in the first block that claims it, top-down in the user's order) are kept.
  De-dupe therefore follows the *user's* order: if Captured is placed above
  Due today, a captured task due today shows under Captured.
- **Workout block:** compact card — today's suggested session name +
  Start/Resume button (reuses `todaysSuggestedSessionProvider` + ActiveWorkout
  flow) and the this-week attendance strip (reuses the `_WeekStrip` logic from
  Workout home, extracted into a shared widget rather than duplicated).
- AppBar area gains a small **✎ edit** affordance (Home has no own AppBar —
  the shell provides it; the pencil lives as the first element of the block
  list or a small icon row at the top of the body).
- "All clear 🎉" shows only when every *enabled task block* is empty; the
  Workout block still renders if enabled.

## Edit Home screen

`lib/features/home/presentation/screens/edit_home_screen.dart`, pushed as a
plain `MaterialPageRoute` (pattern: WidgetSettingsScreen).

- Reorderable list of enabled blocks: drag handle, block name + icon,
  trailing **remove** (−) button.
- "Add block" section listing disabled types with (+) buttons.
- Changes apply live through the settings notifier (no save button).

## Startup tab setting

- `AppSettings.startupTab` (String, an `AppTab` name; default `'home'`),
  persisted as `startup_tab`; setter `setStartupTab`.
- Settings → Navigation tabs section gains an "Open at launch" dropdown of
  the currently visible tabs.
- Router: `appRouter` is a lazily-initialized top-level global; `main()`
  already loads SharedPreferences before `runApp`. A top-level
  `String initialRoute` (set in `main()` from the pref, validated against
  the visible-tabs pref, fallback first visible tab → `/home`) feeds
  `GoRouter(initialLocation: …)` and the bare-`/` redirect.
- If the chosen tab is later hidden via Settings → Tabs, the picker resets
  visually (dropdown only lists visible tabs) and launch falls back safely.

## Testing

- Unit: layout parsing (unknown names dropped, duplicates collapsed, empty ok,
  default fallback), startup-tab fallback (hidden tab → first visible).
- Widget test: HomeScreen renders blocks in stored order (existing test
  patterns with mock prefs).
- Device pass: drag-reorder on Home, edit screen add/remove, workout block
  start button, startup tab honored on cold launch.

## Out of scope (recorded)

- Label / list / habits / pinned blocks (need per-block config → likely the
  prefs→DB storage upgrade lands with them).
- Saved-filter browser in Lists (same engine, later slice).
- Per-block settings (e.g. This-week day count), block collapse state.
- Play-Store readiness items tracked separately: real signing keystore,
  privacy policy, Play Console internal testing.
