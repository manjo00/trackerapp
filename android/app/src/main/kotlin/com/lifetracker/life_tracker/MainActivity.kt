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
        /// invoke Dart while the app process is running. Only the app's own
        /// engine is kept here, never the quick-add sheet's window.
        var liveChannel: MethodChannel? = null
    }

    /// Transparent surface so the quick-add sheet's scrim reveals the home
    /// screen (for a widget "+" drawn before QuickAddActivity, see below).
    /// Opaque app screens paint over it, so they're unaffected.
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
        quickAddChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uplan/quick_add",
        )

        // The widgets' midnight refresh and the live dashboard's channel, set
        // up the same way in the quick-add sheet's own window.
        liveChannel = UplanEngineSetup.configure(this, flutterEngine)
    }

    /// The widgets' "+" opens QuickAddActivity, the sheet's own window, since
    /// 2026-11-03. A "+" drawn before that update still comes here
    /// (uplan://add_task) until the widgets redraw, which the app's next start
    /// does. Cold start: tell go_router to start on the quick-add sheet
    /// instead of Today.
    override fun getInitialRoute(): String? {
        if (intent?.data?.host == "add_task") return "/quick-add"
        return super.getInitialRoute()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showingQuickAdd = intent?.data?.host == "add_task"
        if (showingQuickAdd) keepKeyboardForQuickAdd()
    }

    /// The same old "+" with the app already running: route via the method
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
