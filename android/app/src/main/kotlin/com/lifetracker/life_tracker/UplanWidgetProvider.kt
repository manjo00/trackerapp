package com.lifetracker.life_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Native home-screen widget for Uplan's "Today" glance.
///
/// [HomeWidgetProvider] (from the home_widget package) hands us [widgetData] —
/// a SharedPreferences populated by the Flutter side via HomeWidget.saveWidgetData.
/// We read those values, fill the RemoteViews layout, and wire a tap to open
/// the app. Defaults keep the widget readable before Flutter has written data.
class UplanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.uplan_widget)

            val date = widgetData.getString("today_date", "") ?: ""
            val shift = widgetData.getString("today_shift", "Rest day") ?: "Rest day"
            val counts = widgetData.getString("today_counts", "Tap to open") ?: "Tap to open"
            val shiftColor = widgetData.getInt("today_shift_color", 0xFFFFFFFF.toInt())

            views.setTextViewText(R.id.widget_date, date)
            views.setTextViewText(R.id.widget_shift, shift)
            views.setTextViewText(R.id.widget_counts, counts)
            views.setTextColor(R.id.widget_shift, shiftColor)

            // Tapping the body opens the app on its last screen.
            val openIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, openIntent)

            // Tapping "+" opens the app and deep-links to the New Task screen.
            val addIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("uplan://add_task")
            )
            views.setOnClickPendingIntent(R.id.widget_add, addIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
