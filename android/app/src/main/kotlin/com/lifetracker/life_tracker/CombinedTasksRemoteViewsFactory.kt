package com.lifetracker.life_tracker

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/// Builds the combined month widget's side list as Todoist-style date headlines
/// with their tasks beneath. The selected day's group is moved to the top and
/// highlighted. Reads "combined_tasks" ({ title, date, label, color }) and the
/// selected day ("selected_date" → "widget_today") from the home_widget prefs.
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
        val label: String,
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
        val selected = prefs.getString("selected_date", null)
            ?: prefs.getString("widget_today", "") ?: ""

        val tasks = mutableListOf<Task>()
        try {
            val arr = JSONArray(prefs.getString("combined_tasks", "[]") ?: "[]")
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                tasks.add(
                    Task(
                        title = o.optString("title", ""),
                        date = o.optString("date", ""),
                        label = o.optString("label", ""),
                        color = o.optString("color", "#80FFFFFF"),
                    )
                )
            }
        } catch (_: Exception) {
        }

        // Group by date, preserving the (date-sorted) order tasks arrive in.
        val groups = LinkedHashMap<String, MutableList<Task>>()
        val labels = HashMap<String, String>()
        for (t in tasks) {
            groups.getOrPut(t.date) { mutableListOf() }.add(t)
            labels[t.date] = t.label
        }

        // Ordered dates: selected day first (even if it has no tasks), then the rest.
        val orderedDates = mutableListOf<String>()
        if (selected.isNotEmpty()) orderedDates.add(selected)
        for (d in groups.keys) if (d != selected) orderedDates.add(d)

        val list = mutableListOf<Item>()
        for (d in orderedDates) {
            val label = labels[d] ?: labelFor(d)
            list.add(Item(true, label, d == selected, "", ""))
            groups[d]?.forEach { t ->
                list.add(Item(false, "", d == selected, t.title, t.color))
            }
        }
        items = list
    }

    /// Headline label for a date that has no tasks (e.g. an empty selected day).
    private fun labelFor(dateStr: String): String {
        return try {
            val d = LocalDate.parse(dateStr)
            val base = d.format(DateTimeFormatter.ofPattern("EEE, d MMM"))
            when (ChronoUnit.DAYS.between(LocalDate.now(), d)) {
                0L -> "$base • Today"
                1L -> "$base • Tomorrow"
                else -> base
            }
        } catch (_: Exception) {
            dateStr
        }
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
