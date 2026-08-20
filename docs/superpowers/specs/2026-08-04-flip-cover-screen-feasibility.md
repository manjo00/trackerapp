# Z Flip cover screen — feasibility check (backlog #20)

**Date:** 2026-08-04 · **Device:** SM-F741B (Z Flip 6), Android 16 / SDK 36,
One UI **8.0.5**. All findings below are from `adb dumpsys` on that device, not
from documentation.

## Verdict: GO — and better than expected

The Now-Bar investigation (2026-07-03) found promoted notifications were
firmware-gated for third-party apps. **That does not apply here.** Two
independent routes are open, and one is already half-enabled.

## The cover screen, factually
- It is **displayId 1**: `748 × 720 px`, density **340dpi (×2.125)** →
  **≈352 × 339 dp**. Phone-width, but less than half a phone's height.
- Cutout bottom-right: `Rect(379,654 - 748,720)`, i.e. a **~31dp bottom inset**
  on the right (camera bump). Corners rounded r=49px.
- Flags: `canHostTasks=true`, `FLAG_SHOULD_SHOW_SYSTEM_DECORATIONS`,
  `FLAG_CAN_SHOW_WITH_INSECURE_KEYGUARD`. It is a real, activity-hosting
  display — not a restricted surface.
- `feature:com.samsung.feature.flex_window` present.

## Route A — run Uplan itself on the cover screen (works TODAY)
Good Lock + **MultiStar** are installed, and Uplan is **already in the
allowlist**:
`multistar_cover_widget_backup_list` / `coverWidgetList` both contain
`com.lifetracker.life_tracker`.

So the app can already be launched on the Flex Window. What is missing is not
permission — it is a **layout that suits 352 × 339 dp**. Today Uplan renders a
tall-phone UI there: AppBar (56) + bottom nav (~80) + FAB leaves ~200dp of
content, and Home's responsive breakpoints (≥720dp) never trigger.

**Work required:** a cover-screen-aware compact mode — detect the short
viewport and render a purpose-built glance (today's shift, next 2–3 tasks,
one-tap complete, quick-add) instead of the full chrome. No new Android API,
no Samsung approval.

## Route B — a genuine cover-screen WIDGET (promising, needs one experiment)
The Flex Window widget host filters by `widgetCategory`. Measured on device:

| Provider | widgetCategory |
|---|---|
| Samsung Calendar `DayCoverWidgetProvider` | **2** (keyguard) |
| SystemUI `CoverLauncherLargeWidgetProvider` | **2048** (Samsung-only flag) |
| **Uplan `UplanMonthWidgetProvider`** | **1** (home screen only) |

That is very likely the whole reason our widget cannot be placed there — it
declares itself home-screen-only.

Crucially, a **third-party** app is already doing this successfully:
`apps.ijp.coverwidgets` (Cover Widgets, Play Store) registers
`CoverWidgetSlotN` providers, and `apps.ijp.coveros` is an installed cover
launcher. So third parties are not categorically excluded.

### The experiment that settles it (cheap)
Add a **cover variant** of the existing month widget:
- new provider class + widget XML with `android:widgetCategory="keyguard"`
  (and try the raw `2048`), sized for ~352 × 339 dp,
- reuse the existing RemoteViews/data pipeline (no new data work),
- install, then check whether it appears in the Flip's cover-screen widget
  picker.

Outcome is binary and takes one build. If it appears → we ship a real cover
widget. If not → Route A still delivers the feature.

## Recommendation
Run the Route B experiment first (one build, definitive), because a true
widget is the better product — glanceable with the phone shut, no MultiStar
dependency for other users. Fall back to Route A, which is guaranteed to work
and is independently useful on the Tab S9.

## Not viable
A stock Android cover-screen widget API does not exist; anything here is
Samsung-specific and will not port to other phones.
