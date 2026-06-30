package com.lifetracker.life_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar

/// Combined month widget: a calendar grid (left) + a scrollable task list
/// (right). Both are RemoteViews collection views. Tapping a day broadcasts
/// [ACTION_SELECT_DAY]; the ‹ › arrows broadcast [ACTION_PREV_MONTH] /
/// [ACTION_NEXT_MONTH] to page between months (offset clamped to -1..+3).
///
/// Flutter writes one "month_cells_map" / "month_titles_map" keyed by
/// "yyyy-MM"; the provider resolves the viewed month from the stored
/// [PREF_OFFSET] and copies that month's data into the keys the grid factory
/// reads ("month_cells" / "month_title").
class UplanMonthWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_SELECT_DAY = "com.lifetracker.life_tracker.SELECT_DAY"
        const val ACTION_PREV_MONTH = "com.lifetracker.life_tracker.PREV_MONTH"
        const val ACTION_NEXT_MONTH = "com.lifetracker.life_tracker.NEXT_MONTH"
        const val EXTRA_DAY = "day_date"
        const val PREFS = "HomeWidgetPreferences"
        const val PREF_OFFSET = "month_offset"
        const val MIN_OFFSET = -1
        const val MAX_OFFSET = 3
        const val DEFAULT_BG = 0x202024 // dark surface (RGB)
    }

    /// Reads an int that home_widget may have stored as a Long.
    private fun readInt(prefs: SharedPreferences, key: String, def: Int): Int {
        return try {
            prefs.getInt(key, def)
        } catch (_: Exception) {
            try {
                prefs.getLong(key, def.toLong()).toInt()
            } catch (_: Exception) {
                def
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        render(context, appWidgetManager, appWidgetIds)
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // Resolve the viewed month from the stored offset into month_cells/title.
        applyOffset(prefs, prefs.getInt(PREF_OFFSET, 0))

        // User-chosen background colour + transparency (from in-app settings).
        val bgColor = 0xFF000000.toInt() or (readInt(prefs, "widget_bg_color", DEFAULT_BG) and 0xFFFFFF)
        val bgAlpha = readInt(prefs, "widget_bg_alpha", 255).coerceIn(0, 255)

        appWidgetIds.forEach { widgetId ->
          try {
            val views = RemoteViews(context.packageName, R.layout.uplan_month_widget)

            views.setInt(R.id.widget_bg, "setColorFilter", bgColor)
            views.setInt(R.id.widget_bg, "setImageAlpha", bgAlpha)

            views.setTextViewText(
                R.id.month_title,
                prefs.getString("month_title", "") ?: ""
            )

            // Calendar grid adapter.
            val gridIntent = Intent(context, MonthRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.month_grid, gridIntent)

            // Side task-list adapter.
            val listIntent = Intent(context, CombinedTasksRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME) + "#list")
            }
            views.setRemoteAdapter(R.id.task_list, listIntent)
            views.setEmptyView(R.id.task_list, R.id.tasks_empty)

            // Tapping a day broadcasts SELECT_DAY (re-sorts the list in place).
            val dayTemplate = PendingIntent.getBroadcast(
                context,
                0,
                Intent(context, UplanMonthWidgetProvider::class.java).apply {
                    action = ACTION_SELECT_DAY
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.month_grid, dayTemplate)

            // ‹ › month navigation.
            views.setOnClickPendingIntent(
                R.id.month_prev, monthIntent(context, ACTION_PREV_MONTH, 2)
            )
            views.setOnClickPendingIntent(
                R.id.month_next, monthIntent(context, ACTION_NEXT_MONTH, 3)
            )

            // Tapping a task row opens the app.
            val rowTemplate = PendingIntent.getActivity(
                context,
                1,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.task_list, rowTemplate)

            // "+" deep-links to the quick-add sheet.
            val addIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("uplan://add_task")
            )
            views.setOnClickPendingIntent(R.id.month_add, addIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.month_grid)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.task_list)
          } catch (_: Exception) {
            // Never let a widget update crash the host app.
          }
        }
    }

    private fun monthIntent(context: Context, action: String, code: Int): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            code,
            Intent(context, UplanMonthWidgetProvider::class.java).apply {
                this.action = action
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /// Copies the month at [offset] (relative to the current month) from the
    /// "yyyy-MM"-keyed maps into "month_cells" / "month_title".
    private fun applyOffset(prefs: SharedPreferences, offset: Int) {
        val mapJson = prefs.getString("month_cells_map", "{}") ?: "{}"
        val titlesJson = prefs.getString("month_titles_map", "{}") ?: "{}"
        val cal = Calendar.getInstance()
        cal.add(Calendar.MONTH, offset)
        val key = String.format(
            "%04d-%02d", cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1
        )
        try {
            val obj = JSONObject(mapJson)
            val arr = obj.optJSONArray(key) ?: return // no data yet — keep current
            val titles = JSONObject(titlesJson)
            prefs.edit()
                .putString("month_cells", arr.toString())
                .putString("month_title", titles.optString(key, ""))
                .apply()
        } catch (_: Exception) {
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val mgr = AppWidgetManager.getInstance(context)
        val ids = mgr.getAppWidgetIds(
            ComponentName(context, UplanMonthWidgetProvider::class.java)
        )
        when (intent.action) {
            ACTION_SELECT_DAY -> {
                val date = intent.getStringExtra(EXTRA_DAY) ?: return
                prefs.edit().putString("selected_date", date).apply()
                mgr.notifyAppWidgetViewDataChanged(ids, R.id.task_list)
            }
            ACTION_PREV_MONTH, ACTION_NEXT_MONTH -> {
                val delta = if (intent.action == ACTION_PREV_MONTH) -1 else 1
                val next = (prefs.getInt(PREF_OFFSET, 0) + delta)
                    .coerceIn(MIN_OFFSET, MAX_OFFSET)
                prefs.edit().putInt(PREF_OFFSET, next).apply()
                render(context, mgr, ids)
            }
        }
    }
}
