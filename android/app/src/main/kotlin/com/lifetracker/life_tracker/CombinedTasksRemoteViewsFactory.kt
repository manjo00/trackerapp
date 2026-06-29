package com.lifetracker.life_tracker

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/// Builds the side task list for the combined month widget, re-sorted so the
/// selected day's tasks come first, then the rest by date.
///
/// Reads "combined_tasks" (JSON of { title, date, label }) and the selected day
/// ("selected_date", falling back to "widget_today") from the home_widget prefs.
class CombinedTasksRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class Row(val title: String, val date: String, val label: String)

    private var rows: List<Row> = emptyList()
    private var selected: String = ""

    private val accent = Color.parseColor("#FFB39DDB")
    private val muted = Color.parseColor("#80FFFFFF")

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        selected = prefs.getString("selected_date", null)
            ?: prefs.getString("widget_today", "") ?: ""

        val json = prefs.getString("combined_tasks", "[]") ?: "[]"
        val parsed = mutableListOf<Row>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                parsed.add(
                    Row(
                        title = o.optString("title", ""),
                        date = o.optString("date", ""),
                        label = o.optString("label", ""),
                    )
                )
            }
        } catch (_: Exception) {
        }
        // Selected day first, then everything else by date ascending.
        rows = parsed.sortedWith(
            compareBy({ if (it.date == selected) 0 else 1 }, { it.date })
        )
    }

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        val row = rows[position]
        val rv = RemoteViews(context.packageName, R.layout.uplan_combined_task_row)
        rv.setTextViewText(R.id.ctask_title, row.title)
        rv.setTextViewText(R.id.ctask_sub, row.label)
        rv.setTextColor(
            R.id.ctask_sub,
            if (row.date == selected) accent else muted,
        )
        rv.setOnClickFillInIntent(R.id.ctask_root, Intent())
        return rv
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
