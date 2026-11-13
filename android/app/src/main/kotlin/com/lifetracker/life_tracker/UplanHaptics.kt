package com.lifetracker.life_tracker

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// "uplan/haptics": a strong buzz from the phone's vibrator. The du'a counter
/// uses it when a du'a's count is reached, so Ahmed feels it while counting
/// without looking. Flutter's own haptics are short touch ticks that the
/// phone's touch-feedback setting can switch off; this one always comes
/// through. VIBRATE is a normal permission (no prompt) and already reaches the
/// merged manifest through flutter_local_notifications.
object UplanHaptics {
    fun register(context: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "uplan/haptics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "buzz" -> {
                        val timings = call.argument<List<Number>>("timings")
                            ?.map { it.toLong() }
                            ?.toLongArray()
                            ?: longArrayOf(0L, 350L)
                        buzz(context, timings)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Plays [timings] (off, on, off, on … in milliseconds) once.
    private fun buzz(context: Context, timings: LongArray) {
        val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= 31) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        if (vibrator == null || !vibrator.hasVibrator()) return
        vibrator.vibrate(VibrationEffect.createWaveform(timings, -1))
    }
}
