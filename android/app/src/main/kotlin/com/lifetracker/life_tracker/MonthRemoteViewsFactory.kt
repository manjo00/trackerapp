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
        val date: String,
        val bg: String,
        val fg: String,
        val rot: String,
        val rotColor: String,
        val dots: List<String>,
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
                val dotsArr = o.optJSONArray("dots")
                val dotColors = mutableListOf<String>()
                if (dotsArr != null) {
                    for (j in 0 until dotsArr.length()) {
                        dotColors.add(dotsArr.optString(j))
                    }
                }
                parsed.add(
                    Cell(
                        day = o.optInt("day", 0),
                        date = o.optString("date", ""),
                        bg = o.optString("bg", ""),
                        fg = o.optString("fg", "#FFFFFFFF"),
                        rot = o.optString("rot", ""),
                        rotColor = o.optString("rotColor", ""),
                        dots = dotColors,
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

        val dotIds = intArrayOf(R.id.cell_dot1, R.id.cell_dot2, R.id.cell_dot3)
        if (cell.day == 0) {
            // Leading blank.
            rv.setTextViewText(R.id.cell_day, "")
            rv.setViewVisibility(R.id.cell_rot, View.GONE)
            for (id in dotIds) rv.setViewVisibility(id, View.GONE)
            rv.setInt(R.id.cell_root, "setBackgroundColor", Color.TRANSPARENT)
        } else {
            rv.setTextViewText(R.id.cell_day, cell.day.toString())
            try {
                rv.setTextColor(R.id.cell_day, Color.parseColor(cell.fg))
            } catch (_: Exception) {
            }
            // Rotation label under the day number. Coloured with the cell's
            // dark foreground (not the pale rotation colour) so it always reads
            // on the light shift fill.
            if (cell.rot.isNotEmpty()) {
                rv.setViewVisibility(R.id.cell_rot, View.VISIBLE)
                rv.setTextViewText(R.id.cell_rot, cell.rot)
                try {
                    rv.setTextColor(R.id.cell_rot, Color.parseColor(cell.fg))
                } catch (_: Exception) {
                }
            } else {
                rv.setViewVisibility(R.id.cell_rot, View.GONE)
            }
            if (cell.bg.isNotEmpty()) {
                try {
                    rv.setInt(R.id.cell_root, "setBackgroundColor", Color.parseColor(cell.bg))
                } catch (_: Exception) {
                }
            } else {
                rv.setInt(R.id.cell_root, "setBackgroundColor", Color.TRANSPARENT)
            }
            // Up to 3 priority-coloured dots.
            for (i in dotIds.indices) {
                if (i < cell.dots.size) {
                    rv.setViewVisibility(dotIds[i], View.VISIBLE)
                    try {
                        rv.setTextColor(dotIds[i], Color.parseColor(cell.dots[i]))
                    } catch (_: Exception) {
                    }
                } else {
                    rv.setViewVisibility(dotIds[i], View.GONE)
                }
            }
        }

        // Fill-in carries the date so the SELECT_DAY broadcast knows which day.
        val fill = Intent().putExtra(UplanMonthWidgetProvider.EXTRA_DAY, cell.date)
        rv.setOnClickFillInIntent(R.id.cell_root, fill)
        return rv
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
