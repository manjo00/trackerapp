package com.lifetracker.life_tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.time.LocalDate
import java.time.ZoneId

/**
 * Redraws the home-screen widgets when the date rolls over.
 *
 * ## Why an alarm and not a broadcast
 * The obvious answer, a manifest receiver for `ACTION_DATE_CHANGED`, does not
 * work: that action is NOT on Android's implicit-broadcast exemption list, so
 * since Android 8 a manifest-declared receiver never sees it. (TIME_SET,
 * TIMEZONE_CHANGED and BOOT_COMPLETED *are* exempt, and we do listen for those
 * — they cover travel, a manual clock change and a reboot.) The other candidate,
 * `updatePeriodMillis`, has a 30-minute floor and wakes the device each time:
 * 48 wakeups a day to do the work of one.
 *
 * ## Why an INEXACT alarm is enough
 * [AlarmManager.setAndAllowWhileIdle] fires in the next Doze maintenance
 * window, so it can land some minutes after midnight. That is fine, because the
 * widgets no longer depend on being redrawn at the right moment — [WidgetDates]
 * resolves "today" while drawing, so every redraw is already correct for the
 * day it happens on. This alarm only exists to make one happen on a screen
 * nobody has touched. Staying inexact also keeps us clear of Google Play's
 * restriction of exact alarms to alarm-clock and calendar apps.
 */
class MidnightRefreshReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_REFRESH = "com.lifetracker.life_tracker.MIDNIGHT_REFRESH"
        private const val REQUEST_CODE = 51010 // see notification_service.dart
        private const val PREFS = "HomeWidgetPreferences"

        /**
         * Books the next rollover redraw. Safe to call repeatedly — the same
         * PendingIntent is reused, so a second call replaces the first rather
         * than stacking up alarms.
         */
        fun schedule(context: Context) {
            val alarms =
                context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    ?: return
            // A minute past midnight: far enough past the boundary that a
            // slightly early wakeup still reads the new date.
            val triggerAt = LocalDate.now()
                .plusDays(1)
                .atStartOfDay(ZoneId.systemDefault())
                .plusMinutes(1)
                .toInstant()
                .toEpochMilli()
            try {
                alarms.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent(context))
            } catch (_: Exception) {
                // A widget refresh must never be able to crash the app.
            }
        }

        private fun pendingIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                Intent(context, MidnightRefreshReceiver::class.java)
                    .setAction(ACTION_REFRESH),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        /** Asks every Uplan widget on the home screen to draw itself again. */
        fun refreshAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val providers = listOf(
                UplanWidgetProvider::class.java,
                UplanAgendaWidgetProvider::class.java,
                UplanMonthWidgetProvider::class.java,
            )
            for (provider in providers) {
                val ids = try {
                    manager.getAppWidgetIds(ComponentName(context, provider))
                } catch (_: Exception) {
                    continue
                }
                if (ids.isEmpty()) continue // nothing of this kind on screen
                // Each provider's own onUpdate re-invalidates its collection
                // views, so an APPWIDGET_UPDATE is all this has to send.
                context.sendBroadcast(
                    Intent(context, provider)
                        .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                )
            }
        }

        /**
         * Drops a day the user tapped once it is in the past, so the task list
         * falls back to today instead of staying parked on an old date.
         */
        fun clearStaleSelection(context: Context) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val selected = prefs.getString("selected_date", null) ?: return
            val days = WidgetDates.daysFromToday(selected)
            if (days == null || days < 0L) {
                prefs.edit().remove("selected_date").apply()
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        // TIME_SET / TIMEZONE_CHANGED mean the alarm we booked is now for the
        // wrong instant, so re-book as well as redraw.
        clearStaleSelection(context)
        refreshAllWidgets(context)
        // The live dashboard notification carries the same date header, and it
        // can sit on screen for days, so it gets redrawn too.
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getBoolean("live_enabled", false)) {
            LiveDashboardService.start(context)
        }
        schedule(context)
    }
}
