package com.lifetracker.life_tracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.IBinder
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONArray

/**
 * Foreground service that owns the persistent "Live dashboard" notification.
 *
 * A foreground service is the only way to show a notification the user can't
 * lose — Android requires the service to hold one, and in exchange the
 * process is protected from being killed. The notification body is a custom
 * RemoteViews layout (same tech as the home-screen widget).
 *
 * Data flows one way: Flutter pre-renders the slideshow cards as JSON into
 * HomeWidgetPreferences (the same store the widgets read) and pings
 * ACTION_REFRESH; this service only ever *reads* prefs and re-renders.
 * Paging (◀ ▶) is fully native: just an index into the cached JSON array,
 * so it works instantly even when the Flutter engine isn't running.
 */
class LiveDashboardService : Service() {

    companion object {
        const val ACTION_START = "com.lifetracker.life_tracker.live.START"
        const val ACTION_REFRESH = "com.lifetracker.life_tracker.live.REFRESH"
        const val ACTION_PREV = "com.lifetracker.life_tracker.live.PREV"
        const val ACTION_NEXT = "com.lifetracker.life_tracker.live.NEXT"

        /** Notification id — documented in notification_service.dart's ID map. */
        const val NOTIFICATION_ID = 50001

        const val CHANNEL_ID = "live_dashboard"

        /** PendingIntent request codes (unique per action across the app). */
        private const val RC_PREV = 51001
        private const val RC_NEXT = 51002
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

    /** Which slideshow card is showing. Lives as long as the service does. */
    private var currentIndex = 0

    /**
     * Re-renders whenever the Dart side (foreground app OR the headless
     * ✓/snooze callback) rewrites the card data. Must be a field — Android
     * holds prefs listeners weakly, a local would be GC'd within minutes.
     */
    private val prefsListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == "live_cards" || key == "live_mode") {
                getSystemService(NotificationManager::class.java)
                    .notify(NOTIFICATION_ID, buildNotification())
            }
        }

    override fun onCreate() {
        super.onCreate()
        getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .registerOnSharedPreferenceChangeListener(prefsListener)
    }

    override fun onDestroy() {
        getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .unregisterOnSharedPreferenceChangeListener(prefsListener)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PREV -> currentIndex--
            ACTION_NEXT -> currentIndex++
            // START/REFRESH/null (restart after kill): render as-is.
        }
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

    /** One parsed slideshow card (pre-rendered by the Dart side). */
    private data class Card(
        val type: String,
        val id: Int,
        val title: String,
        val sub: String,
        val color: Int,
    )

    private fun loadCards(): List<Card> {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val json = prefs.getString("live_cards", "[]") ?: "[]"
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Card(
                    type = o.optString("type", "task"),
                    id = o.optInt("id", 0),
                    title = o.optString("title", ""),
                    sub = o.optString("sub", ""),
                    color = parseColor(o.optString("color", "#FF8E9AAF")),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun parseColor(hex: String): Int =
        try {
            Color.parseColor(hex)
        } catch (_: IllegalArgumentException) {
            0xFF8E9AAF.toInt()
        }

    private fun servicePendingIntent(action: String, requestCode: Int): PendingIntent =
        PendingIntent.getService(
            this,
            requestCode,
            Intent(this, LiveDashboardService::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun buildNotification(): Notification {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val date = prefs.getString("today_date", "") ?: ""
        val shift = prefs.getString("today_shift", "") ?: ""
        val counts = prefs.getString("today_counts", "Open Uplan to sync") ?: ""
        val header = if (shift.isEmpty()) "$counts  ·  $date"
        else "$counts  ·  $shift  ·  $date"

        val cards = loadCards()
        // Wrap the index in both directions (‹ from the first card lands on
        // the last) and keep it valid when the card list shrinks.
        val index = if (cards.isEmpty()) 0
        else ((currentIndex % cards.size) + cards.size) % cards.size
        currentIndex = index
        val card = cards.getOrNull(index)

        // ── Collapsed: just the current card (or the glance when empty) ────
        val collapsed = RemoteViews(packageName, R.layout.live_card).apply {
            if (card != null) {
                setTextViewText(R.id.live_title, card.title)
                setTextViewText(R.id.live_sub, card.sub)
            } else {
                setTextViewText(R.id.live_title, counts)
                setTextViewText(
                    R.id.live_sub,
                    if (shift.isEmpty()) date else "$shift  ·  $date",
                )
            }
        }

        // ── Expanded: header + card + ◀ n/m ▶ controls ─────────────────────
        val expanded = RemoteViews(packageName, R.layout.live_card_expanded).apply {
            setTextViewText(R.id.live_exp_header, header)
            if (card != null) {
                setTextViewText(R.id.live_exp_title, card.title)
                setTextViewText(R.id.live_exp_sub, card.sub)
                setTextColor(R.id.live_exp_dot, card.color)
                setTextViewText(R.id.live_pos, "${index + 1}/${cards.size}")

                // ✓/snooze run the registered Dart callback in a headless
                // engine (home_widget background intent) — no app needed.
                setViewVisibility(R.id.live_done, View.VISIBLE)
                setViewVisibility(R.id.live_snooze, View.VISIBLE)
                setOnClickPendingIntent(
                    R.id.live_done,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        this@LiveDashboardService,
                        Uri.parse(
                            "uplan://live?action=complete&type=${card.type}&id=${card.id}"),
                    ),
                )
                setOnClickPendingIntent(
                    R.id.live_snooze,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        this@LiveDashboardService,
                        Uri.parse(
                            "uplan://live?action=snooze&type=${card.type}&id=${card.id}"),
                    ),
                )
            } else {
                setTextViewText(R.id.live_exp_title, "All clear 🎉")
                setTextViewText(R.id.live_exp_sub, "Nothing pending right now")
                setTextColor(R.id.live_exp_dot, 0xFF7BC67E.toInt())
                setTextViewText(R.id.live_pos, "0/0")
                setViewVisibility(R.id.live_done, View.GONE)
                setViewVisibility(R.id.live_snooze, View.GONE)
            }
            setOnClickPendingIntent(
                R.id.live_prev, servicePendingIntent(ACTION_PREV, RC_PREV))
            setOnClickPendingIntent(
                R.id.live_next, servicePendingIntent(ACTION_NEXT, RC_NEXT))
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
        val repost = servicePendingIntent(ACTION_REFRESH, RC_REPOST)

        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            // Never buzz/flash again when the content refreshes.
            .setOnlyAlertOnce(true)
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            // Wraps our custom views in the standard notification frame
            // (app name header, correct light/dark background).
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setContentIntent(openApp)
            .setDeleteIntent(repost)
            .build()
    }
}
