package com.lifetracker.life_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Month-grid home-screen widget. The 7-column GridView is a collection view
/// fed by [MonthRemoteViewsService] / [MonthRemoteViewsFactory], which read the
/// "month_cells" JSON that Flutter writes (day number, shift colour, task dot).
class UplanMonthWidgetProvider : HomeWidgetProvider() {
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

            // Grid adapter.
            val serviceIntent = Intent(context, MonthRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.month_grid, serviceIntent)

            // Tapping a day opens the app.
            val cellTemplate = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.month_grid, cellTemplate)

            // "+" deep-links to the quick-add sheet.
            val addIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("uplan://add_task")
            )
            views.setOnClickPendingIntent(R.id.month_add, addIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.month_grid)
          } catch (_: Exception) {
            // Never let a widget update crash the host app.
          }
        }
    }
}
