package com.lifetracker.life_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper

/**
 * Handles taps on the rest-timer notification's +15s / Skip buttons by
 * calling back into the Dart [RestTimer] over the uplan/live channel.
 *
 * The timer only exists while the app process is alive (it's an in-app
 * Timer), so the channel is always available when these buttons matter;
 * if the process died the notification is stale and the tap is a no-op.
 */
class LiveActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_REST_ADD15 = "com.lifetracker.life_tracker.live.REST_ADD15"
        const val ACTION_REST_SKIP = "com.lifetracker.life_tracker.live.REST_SKIP"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val method = when (intent.action) {
            ACTION_REST_ADD15 -> "restAdd15"
            ACTION_REST_SKIP -> "restSkip"
            else -> return
        }
        // Channel calls must run on the main thread.
        Handler(Looper.getMainLooper()).post {
            MainActivity.liveChannel?.invokeMethod(method, null)
        }
    }
}
