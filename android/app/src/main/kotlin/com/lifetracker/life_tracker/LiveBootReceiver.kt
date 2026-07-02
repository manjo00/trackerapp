package com.lifetracker.life_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-starts the Live dashboard after a reboot (if the user has it enabled)
 * so the notification is there without having to open the app first.
 * RECEIVE_BOOT_COMPLETED is already declared for the alarm rescheduler.
 */
class LiveBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        if (prefs.getBoolean("live_enabled", false)) {
            LiveDashboardService.start(context)
        }
    }
}
