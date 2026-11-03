package com.lifetracker.life_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// The widgets' "+": the quick-add sheet in a window of its own.
///
/// It runs in a task of its own (AndroidManifest.xml: taskAffinity "",
/// singleTask, excludeFromRecents), so the "+" never brings the app's open
/// window forward: no app screen flashes behind the sheet, the app keeps the
/// screen it was on, and Uplan's icon opens the app, never the sheet. It has
/// its own Flutter engine (and database connection). Sending or dismissing
/// the sheet ends this activity and its engine; the app, if open, is left
/// alone. A "+" while a sheet sits in the background (left with Home) brings
/// that sheet back as it was.
class QuickAddActivity : FlutterActivity() {
    /// Tells the sheet when Android gives this window focus.
    private var quickAddChannel: MethodChannel? = null

    /// See-through, so the sheet's scrim shows the home screen behind it.
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    /// Always the sheet, whatever the intent carries.
    override fun getInitialRoute(): String = "/quick-add"

    /// The "+" intent's uplan://add_task is no route: with deep links on, a
    /// second "+" (onNewIntent) would push it into go_router.
    override fun shouldHandleDeeplinking(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        quickAddChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "uplan/quick_add",
        )
        // Not kept in MainActivity.liveChannel: the rest timer's notification
        // buttons talk to the app's engine, not to this one.
        UplanEngineSetup.configure(this, flutterEngine)
    }

    /// Android accepts keyboard requests only once this window has focus, and
    /// on a fast phone the sheet's text field asks before that. Flutter can't
    /// tell the sheet: its engine starts each window believing it has focus,
    /// so its "resumed" comes too early. Pass Android's own signal on.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) quickAddChannel?.invokeMethod("windowFocused", null)
    }
}
