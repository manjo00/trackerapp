package com.lifetracker.life_tracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.widget.RemoteViews

/**
 * Foreground service that owns the persistent "Live dashboard" notification.
 *
 * A foreground service is the only way to show a notification the user can't
 * swipe away — Android requires the service to hold one, and in exchange the
 * process is protected from being killed. The notification body is a custom
 * RemoteViews layout (same tech as the home-screen widget).
 *
 * Data flows one way: Flutter writes a snapshot into HomeWidgetPreferences
 * (the same store the widgets read) and pings ACTION_REFRESH; this service
 * only ever *reads* prefs and re-renders. It never touches the database.
 */
class LiveDashboardService : Service() {

    companion object {
        const val ACTION_START = "com.lifetracker.life_tracker.live.START"
        const val ACTION_STOP = "com.lifetracker.life_tracker.live.STOP"
        const val ACTION_REFRESH = "com.lifetracker.life_tracker.live.REFRESH"

        /** Notification id — documented in notification_service.dart's ID map. */
        const val NOTIFICATION_ID = 50001

        const val CHANNEL_ID = "live_dashboard"

        /** PendingIntent request codes (unique per action across the app). */
        private const val RC_OPEN_APP = 51007
        private const val RC_REPOST = 51009

        /** Same prefs file home_widget writes through HomeWidget.saveWidgetData. */
        private const val PREFS = "HomeWidgetPreferences"

        /** Starts (or refreshes) the dashboard from any context. */
        fun start(context: Context) {
            val intent = Intent(context, LiveDashboardService::class.java)
                .setAction(ACTION_START)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            // Stopping the service also removes its foreground notification.
            // No-op if it isn't running.
            context.stopService(Intent(context, LiveDashboardService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // START and REFRESH share the same path: (re)post the notification
        // from the latest prefs snapshot. Also covers the null-intent case
        // (START_STICKY restart after the OS killed us).
        ensureChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        // If One UI kills us anyway, ask the OS to restart the service.
        return START_STICKY
    }

    private fun ensureChannel() {
        val manager = getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Live dashboard",
                // LOW = visible in the shade but silent — no sound, no
                // heads-up popup. MIN would risk One UI hiding it entirely.
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Persistent glanceable dashboard"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        val date = prefs.getString("today_date", "") ?: ""
        val shift = prefs.getString("today_shift", "") ?: ""
        val counts = prefs.getString("today_counts", "Open Uplan to sync") ?: ""

        val views = RemoteViews(packageName, R.layout.live_card).apply {
            setTextViewText(R.id.live_title, counts)
            setTextViewText(
                R.id.live_sub,
                if (shift.isEmpty()) date else "$shift  ·  $date",
            )
        }

        // Tapping the card body opens the app.
        val openApp = PendingIntent.getActivity(
            this,
            RC_OPEN_APP,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        // Android 14+ lets users swipe away FGS notifications (the service
        // keeps running, only the card hides). "Always on" is this feature's
        // whole point, so on dismissal we immediately re-post.
        val repost = PendingIntent.getService(
            this,
            RC_REPOST,
            Intent(this, LiveDashboardService::class.java)
                .setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            // Never buzz/flash again when the content refreshes.
            .setOnlyAlertOnce(true)
            .setCustomContentView(views)
            // Wraps our custom view in the standard notification frame
            // (app name header, correct light/dark background).
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setContentIntent(openApp)
            .setDeleteIntent(repost)
            .build()
    }
}
