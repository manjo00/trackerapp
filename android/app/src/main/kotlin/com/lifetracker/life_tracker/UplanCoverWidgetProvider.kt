package com.lifetracker.life_tracker

/**
 * ROUTE-B EXPERIMENT (backlog #20, 2026-08-04).
 *
 * A cover-screen variant of the month widget. It renders exactly like the
 * home-screen one — the only thing being tested is whether declaring
 * `widgetCategory="keyguard"` (plus a cover-sized footprint) is enough to make
 * a THIRD-PARTY widget selectable on the Z Flip's Flex Window.
 *
 * Measured on SM-F741B / One UI 8.0.5: Samsung's own cover widgets report
 * widgetCategory 2 (keyguard) or 2048 (Samsung-private); ours reported 1
 * (home screen only), which is the suspected reason it never appears there.
 *
 * See docs/superpowers/specs/2026-08-04-flip-cover-screen-feasibility.md.
 */
class UplanCoverWidgetProvider : UplanMonthWidgetProvider()
