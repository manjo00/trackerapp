package com.lifetracker.life_tracker

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/// Builds the rows for the agenda widget's ListView.
///
/// Reads the "agenda_items" JSON array that Flutter saved through the
/// home_widget plugin (stored in the "HomeWidgetPreferences" SharedPreferences).
/// Each element is { "title", "sub", "color" }.
class AgendaRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class Item(val title: String, val sub: String, val color: Int)

    private var items: List<Item> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("agenda_items", "[]") ?: "[]"
        val parsed = mutableListOf<Item>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                parsed.add(
                    Item(
                        title = o.optString("title", ""),
                        sub = o.optString("sub", ""),
                        color = o.optInt("color", 0xB0FFFFFF.toInt())
                    )
                )
            }
        } catch (_: Exception) {
            // Leave the list empty on any parse error.
        }
        items = parsed
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val item = items[position]
        val row = RemoteViews(context.packageName, R.layout.uplan_agenda_row)
        row.setTextViewText(R.id.row_title, item.title)
        row.setTextViewText(R.id.row_sub, item.sub)
        row.setTextColor(R.id.row_sub, item.color)
        // Empty fill-in → the row click fires the list's PendingIntent template.
        row.setOnClickFillInIntent(R.id.agenda_row, Intent())
        return row
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
