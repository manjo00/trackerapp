package com.lifetracker.life_tracker

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// What every Uplan window sets up on its Flutter engine: the app itself
/// (MainActivity) and the widgets' quick-add sheet (QuickAddActivity).
object UplanEngineSetup {
    /// Re-books the widgets' date-rollover refresh, so a dropped alarm (force
    /// stop, reboot, OS cleanup) heals itself, and answers what Dart asks on
    /// "uplan/live": the live dashboard, the rest timer's Live Update and the
    /// battery checks. Returns that channel.
    fun configure(activity: Activity, engine: FlutterEngine): MethodChannel {
        MidnightRefreshReceiver.schedule(activity)
        MidnightRefreshReceiver.clearStaleSelection(activity)

        // Live dashboard: Flutter drives the foreground service through here.
        return MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "uplan/live",
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startDashboard", "refreshDashboard" -> {
                        LiveDashboardService.start(activity)
                        result.success(true)
                    }
                    "stopDashboard" -> {
                        LiveDashboardService.stop(activity)
                        result.success(true)
                    }
                    // Rest-timer Live Update (Now Bar) — id 50002.
                    "startRest" -> {
                        val endAt = call.argument<Number>("endAtMillis")
                        val total = call.argument<Number>("totalSeconds")
                        if (endAt != null && total != null) {
                            RestLiveUpdate.post(
                                activity, endAt.toLong(), total.toInt())
                        }
                        result.success(true)
                    }
                    "cancelRest" -> {
                        RestLiveUpdate.cancel(activity)
                        result.success(true)
                    }
                    // Has the OS granted Live Updates promotion (Now Bar)?
                    "canPromote" -> {
                        val can = if (android.os.Build.VERSION.SDK_INT >= 36) {
                            activity.getSystemService(android.app.NotificationManager::class.java)
                                .canPostPromotedNotifications()
                        } else {
                            false
                        }
                        result.success(can)
                    }
                    // Diagnostics: is the app exempt from battery optimization?
                    // (Aggressive OEMs — OnePlus/One UI — kill background work
                    // for non-exempt apps, breaking reminders + the dashboard.)
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = activity.getSystemService(android.os.PowerManager::class.java)
                        result.success(pm.isIgnoringBatteryOptimizations(activity.packageName))
                    }
                    // Shows the system "let this app run in background" dialog.
                    "requestIgnoreBatteryOptimizations" -> {
                        val intent = Intent(
                            android.provider.Settings
                                .ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                        ).setData(android.net.Uri.parse("package:${activity.packageName}"))
                        activity.startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
}
