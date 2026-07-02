package com.lifetracker.life_tracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log

/**
 * The workout rest-timer notification (id 50002) — separate from the
 * dashboard because promoted "Live Update" notifications must be plain
 * (no custom RemoteViews, no colorized) to qualify.
 *
 * On Android 16 (API 36) it's posted as a Live Update:
 * ProgressStyle + requestPromotedOngoing → status-bar chip,
 * Samsung Now Bar, and the Flip's cover screen. Older devices get a
 * normal ongoing notification. Either way the countdown text ticks
 * natively via the chronometer — no per-second re-posting.
 */
object RestLiveUpdate {

    const val NOTIFICATION_ID = 50002
    const val CHANNEL_ID = "live_rest_timer"

    private const val RC_ADD15 = 51005
    private const val RC_SKIP = 51006

    fun post(context: Context, endAtMillis: Long, totalSeconds: Int) {
        ensureChannel(context)

        val remainingSec =
            ((endAtMillis - System.currentTimeMillis()) / 1000)
                .coerceIn(0, totalSeconds.toLong()).toInt()

        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Rest")
            .setContentText("Next set when the countdown ends")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            // Chronometer counting DOWN to `when` — ticks natively.
            .setWhen(endAtMillis)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .addAction(action(context, "+15s", LiveActionReceiver.ACTION_REST_ADD15, RC_ADD15))
            .addAction(action(context, "Skip", LiveActionReceiver.ACTION_REST_SKIP, RC_SKIP))

        if (Build.VERSION.SDK_INT >= 36) {
            // Live Update: progress bar spanning the full rest, chip text.
            builder.setStyle(
                Notification.ProgressStyle()
                    .setProgressSegments(
                        listOf(Notification.ProgressStyle.Segment(totalSeconds)))
                    .setProgress(totalSeconds - remainingSec),
            )
            builder.setShortCriticalText(mmss(remainingSec))
            // Ask the OS to promote this to a Live Update (status chip /
            // Now Bar). This SDK revision exposes the flag rather than the
            // later requestPromotedOngoing() wrapper — same effect.
            builder.setFlag(Notification.FLAG_PROMOTED_ONGOING, true)

            val nm = context.getSystemService(NotificationManager::class.java)
            Log.i("RestLiveUpdate",
                "canPostPromotedNotifications=${nm.canPostPromotedNotifications()}")
        }

        context.getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, builder.build())
    }

    fun cancel(context: Context) {
        context.getSystemService(NotificationManager::class.java)
            .cancel(NOTIFICATION_ID)
    }

    private fun action(
        context: Context,
        label: String,
        intentAction: String,
        requestCode: Int,
    ): Notification.Action {
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, LiveActionReceiver::class.java).setAction(intentAction),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Action.Builder(
            Icon.createWithResource(context, R.mipmap.ic_launcher),
            label,
            pending,
        ).build()
    }

    private fun mmss(totalSec: Int): String {
        val m = totalSec / 60
        val s = totalSec % 60
        return "%d:%02d".format(m, s)
    }

    private fun ensureChannel(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Rest timer",
                // DEFAULT importance qualifies for promotion (MIN/LOW may
                // not); silent — the rest-complete sound is a separate
                // notification (id 998) from the Dart side.
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Live rest countdown during workouts"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            manager.createNotificationChannel(channel)
        }
    }
}
