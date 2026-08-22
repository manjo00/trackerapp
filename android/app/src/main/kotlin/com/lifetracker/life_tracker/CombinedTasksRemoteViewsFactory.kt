package com.lifetracker.life_tracker

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/// Builds the combined month widget's side list as Todoist-style date headlines
/// with their tasks beneath. The selected day's group is moved to the top and
/// highlighted. Reads "combined_tasks" ({ title, date, label, color }) and the
/// selected day ("selected_date") from the home_widget prefs. Date headlines
/// are derived from the clock at draw time (see WidgetDates) so the list never
/// keeps calling yesterday "Today".
class CombinedTasksRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class Item(
        val isHeader: Boolean,
        val label: String,
        val highlighted: Boolean,
        val title: String,
        val color: String,
    )

    private data class Task(
        val title: String,
        val date: String,
        val color: String,
    )

    private var items: List<Item> = emptyList()

    private val accent = Color.parseColor("#FFB39DDB")
    private val accentBg = Color.parseColor("#33B39DDB")
    private val muted = Color.parseColor("#B0FFFFFF")

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        // Fall back to the clock, not to the pushed "widget_today" — that
        // string is only as fresh as the last time the app ran. A selected day
        // that has since gone by is dropped for the same reason.
        val today = WidgetDates.todayKey()
        val picked = prefs.getString("selected_date", null)
        val selected = if (picked == null || (WidgetDates.daysFromToday(picked) ?: 0L) < 0L) {
            today
        } else {
            picked
        }

        val tasks = mutableListOf<Task>()
        try {
            val arr = JSONArray(prefs.getString("combined_tasks", "[]") ?: "[]")
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                tasks.add(
                    Task(
                        title = o.optString("title", ""),
                        date = o.optString("date", ""),
                        color = o.optString("color", "#80FFFFFF"),
                    )
                )
            }
        } catch (_: Exception) {
        }

        // Group by date, preserving the (date-sorted) order tasks arrive in.
        val groups = LinkedHashMap<String, MutableList<Task>>()
        for (t in tasks) {
            groups.getOrPut(t.date) { mutableListOf() }.add(t)
        }

        // Ordered dates: selected day first (even if it has no tasks), then the rest.
        val orderedDates = mutableListOf<String>()
        if (selected.isNotEmpty()) orderedDates.add(selected)
        for (d in groups.keys) if (d != selected) orderedDates.add(d)

        val list = mutableListOf<Item>()
        for (d in orderedDates) {
            // Always derived from today's date, never from the pushed label.
            val label = WidgetDates.dateHeadline(d)
            list.add(Item(true, label, d == selected, "", ""))
            groups[d]?.forEach { t ->
                list.add(Item(false, "", d == selected, t.title, t.color))
            }
        }
        items = list
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val item = items[position]
        return if (item.isHeader) {
            RemoteViews(context.packageName, R.layout.uplan_group_header).apply {
                setTextViewText(R.id.header_label, item.label)
                if (item.highlighted) {
                    setTextColor(R.id.header_label, accent)
                    setInt(R.id.header_root, "setBackgroundColor", accentBg)
                } else {
                    setTextColor(R.id.header_label, muted)
                    setInt(R.id.header_root, "setBackgroundColor", Color.TRANSPARENT)
                }
                setOnClickFillInIntent(R.id.header_root, Intent())
            }
        } else {
            RemoteViews(context.packageName, R.layout.uplan_combined_task_row).apply {
                setTextViewText(R.id.ctask_title, item.title)
                try {
                    setTextColor(R.id.ctask_dot, Color.parseColor(item.color))
                } catch (_: Exception) {
                }
                setOnClickFillInIntent(R.id.ctask_root, Intent())
            }
        }
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 2
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
