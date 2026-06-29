package com.lifetracker.life_tracker

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/// Builds the day cells for the month-grid widget.
///
/// Reads the "month_cells" JSON written by Flutter (HomeWidgetService): each
/// element is { day, bg, fg, dot } — day number (0 = leading blank), background
/// hex (empty = transparent), text hex, and whether a task is due that day.
class MonthRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class Cell(
        val day: Int,
        val bg: String,
        val fg: String,
        val dot: Boolean,
    )

    private var cells: List<Cell> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("month_cells", "[]") ?: "[]"
        val parsed = mutableListOf<Cell>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                parsed.add(
                    Cell(
                        day = o.optInt("day", 0),
                        bg = o.optString("bg", ""),
                        fg = o.optString("fg", "#FFFFFFFF"),
                        dot = o.optBoolean("dot", false),
                    )
                )
            }
        } catch (_: Exception) {
        }
        cells = parsed
    }

    override fun onDestroy() {
        cells = emptyList()
    }

    override fun getCount(): Int = cells.size

    override fun getViewAt(position: Int): RemoteViews {
        val cell = cells[position]
        val rv = RemoteViews(context.packageName, R.layout.uplan_month_cell)

        if (cell.day == 0) {
            // Leading blank.
            rv.setTextViewText(R.id.cell_day, "")
            rv.setViewVisibility(R.id.cell_dot, View.GONE)
            rv.setInt(R.id.cell_root, "setBackgroundColor", Color.TRANSPARENT)
        } else {
            rv.setTextViewText(R.id.cell_day, cell.day.toString())
            try {
                rv.setTextColor(R.id.cell_day, Color.parseColor(cell.fg))
            } catch (_: Exception) {
            }
            if (cell.bg.isNotEmpty()) {
                try {
                    rv.setInt(R.id.cell_root, "setBackgroundColor", Color.parseColor(cell.bg))
                } catch (_: Exception) {
                }
            } else {
                rv.setInt(R.id.cell_root, "setBackgroundColor", Color.TRANSPARENT)
            }
            if (cell.dot) {
                rv.setViewVisibility(R.id.cell_dot, View.VISIBLE)
                try {
                    rv.setTextColor(R.id.cell_dot, Color.parseColor(cell.fg))
                } catch (_: Exception) {
                }
            } else {
                rv.setViewVisibility(R.id.cell_dot, View.GONE)
            }
        }

        rv.setOnClickFillInIntent(R.id.cell_root, Intent())
        return rv
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
