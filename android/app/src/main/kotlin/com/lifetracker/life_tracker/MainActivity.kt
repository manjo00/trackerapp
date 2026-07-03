package com.lifetracker.life_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "uplan/widget"
    private var methodChannel: MethodChannel? = null

    companion object {
        /// Live-dashboard channel handle. Static so native components that
        /// outlive this activity (e.g. notification action receivers) can
        /// invoke Dart while the app process is running.
        var liveChannel: MethodChannel? = null
    }

    /// Transparent surface so the quick-add sheet's scrim reveals the home
    /// screen. Opaque app screens paint over it, so they're unaffected.
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )

        // Live dashboard: Flutter drives the foreground service through here.
        liveChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uplan/live",
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startDashboard", "refreshDashboard" -> {
                        LiveDashboardService.start(this@MainActivity)
                        result.success(true)
                    }
                    "stopDashboard" -> {
                        LiveDashboardService.stop(this@MainActivity)
                        result.success(true)
                    }
                    // Rest-timer Live Update (Now Bar) — id 50002.
                    "startRest" -> {
                        val endAt = call.argument<Number>("endAtMillis")
                        val total = call.argument<Number>("totalSeconds")
                        if (endAt != null && total != null) {
                            RestLiveUpdate.post(
                                this@MainActivity, endAt.toLong(), total.toInt())
                        }
                        result.success(true)
                    }
                    "cancelRest" -> {
                        RestLiveUpdate.cancel(this@MainActivity)
                        result.success(true)
                    }
                    // Has the OS granted Live Updates promotion (Now Bar)?
                    "canPromote" -> {
                        val can = if (android.os.Build.VERSION.SDK_INT >= 36) {
                            getSystemService(android.app.NotificationManager::class.java)
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
                        val pm = getSystemService(android.os.PowerManager::class.java)
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    // Shows the system "let this app run in background" dialog.
                    "requestIgnoreBatteryOptimizations" -> {
                        val intent = Intent(
                            android.provider.Settings
                                .ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                        ).setData(android.net.Uri.parse("package:$packageName"))
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /// Cold start: if the widget "+" launched us (uplan://add_task), tell
    /// go_router to start on the quick-add sheet instead of Today.
    override fun getInitialRoute(): String? {
        if (intent?.data?.host == "add_task") return "/quick-add"
        return super.getInitialRoute()
    }

    /// Warm start: the app was already running, so route via the method
    /// channel (getInitialRoute only runs on a fresh engine).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.data?.host == "add_task") {
            methodChannel?.invokeMethod("openQuickAdd", null)
        }
    }
}
