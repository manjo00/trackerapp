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

/// The "Upcoming" agenda widget — a scrolling list of overdue + upcoming tasks.
///
/// This is a collection widget: the ListView's rows are supplied by
/// [AgendaRemoteViewsService] / [AgendaRemoteViewsFactory], which read the
/// task list (as JSON) that Flutter wrote via HomeWidget.saveWidgetData.
class UplanAgendaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.uplan_agenda_widget)

            // Point the ListView at our RemoteViewsService.
            val serviceIntent = Intent(context, AgendaRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                // Unique data so each widget instance gets its own factory.
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.agenda_list, serviceIntent)
            views.setEmptyView(R.id.agenda_list, R.id.agenda_empty)

            // Row taps fire this template (opens the app); rows add an empty
            // fill-in intent so the click registers.
            val rowTemplate = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.agenda_list, rowTemplate)

            // "+" deep-links to the New Task screen.
            val addIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("uplan://add_task")
            )
            views.setOnClickPendingIntent(R.id.agenda_add, addIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
            // Force the list to re-read its data (covers data-only refreshes).
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.agenda_list)
        }
    }
}
