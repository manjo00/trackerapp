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

/// Combined month widget: a calendar grid (left) + a scrollable task list
/// (right). Both are RemoteViews collection views. Tapping a day broadcasts
/// [ACTION_SELECT_DAY]; [onReceive] stores the chosen day and refreshes the
/// task list, which re-sorts that day's tasks to the top.
class UplanMonthWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_SELECT_DAY = "com.lifetracker.life_tracker.SELECT_DAY"
        const val EXTRA_DAY = "day_date"
        const val PREFS = "HomeWidgetPreferences"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
          try {
            val views = RemoteViews(context.packageName, R.layout.uplan_month_widget)

            views.setTextViewText(
                R.id.month_title,
                widgetData.getString("month_title", "") ?: ""
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

    /// Handles a day tap: save the chosen day and refresh the task list so it
    /// re-sorts. Also re-render the grid so the selection can be reflected.
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_SELECT_DAY) {
            val date = intent.getStringExtra(EXTRA_DAY) ?: return
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString("selected_date", date).apply()
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, UplanMonthWidgetProvider::class.java)
            )
            mgr.notifyAppWidgetViewDataChanged(ids, R.id.task_list)
        }
    }
}
