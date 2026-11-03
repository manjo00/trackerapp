package com.lifetracker.life_tracker

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "uplan/widget"
    private var methodChannel: MethodChannel? = null

    /// Tells the quick-add sheet when Android gives this window focus.
    private var quickAddChannel: MethodChannel? = null
    private var showingQuickAdd = false

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

        // Re-book the widgets' date-rollover refresh on every launch, so a
        // dropped alarm (force stop, reboot, OS cleanup) heals itself.
        MidnightRefreshReceiver.schedule(this)
        MidnightRefreshReceiver.clearStaleSelection(this)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
        quickAddChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uplan/quick_add",
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showingQuickAdd = intent?.data?.host == "add_task"
        if (showingQuickAdd) keepKeyboardForQuickAdd()
    }

    /// Warm start: the app was already running, so route via the method
    /// channel (getInitialRoute only runs on a fresh engine).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        showingQuickAdd = intent.data?.host == "add_task"
        if (showingQuickAdd) {
            keepKeyboardForQuickAdd()
            methodChannel?.invokeMethod("openQuickAdd", null)
        }
    }

    /// Android accepts keyboard requests only once this window has focus, and
    /// on a fast phone the sheet's text field asks before that. Flutter can't
    /// tell the sheet: its engine starts each window believing it has focus,
    /// so its "resumed" comes too early. Pass Android's own signal on.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && showingQuickAdd) {
            quickAddChannel?.invokeMethod("windowFocused", null)
        }
    }

    /// Flutter's view doesn't count as a text box for Android, so whenever
    /// this window comes back to the front Android hides the keyboard, and
    /// that hide lands just after the quick-add sheet asks for it. Leave the
    /// keyboard alone instead, so the sheet's first ask usually wins (if the
    /// keyboard was up just before, Android still hides it, and the sheet
    /// asks again). The activity ends when the sheet closes, so the rest of
    /// the app keeps the default.
    private fun keepKeyboardForQuickAdd() {
        window.setSoftInputMode(
            WindowManager.LayoutParams.SOFT_INPUT_STATE_UNCHANGED or
                WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE,
        )
    }
}
