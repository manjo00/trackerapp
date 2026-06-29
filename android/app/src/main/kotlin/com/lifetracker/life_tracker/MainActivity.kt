package com.lifetracker.life_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "uplan/widget"
    private var methodChannel: MethodChannel? = null

    /// Render with a transparent surface so the quick-add sheet's scrim can
    /// reveal the home screen behind it. Opaque app screens are unaffected
    /// (their Scaffolds paint over the transparent surface).
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
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
