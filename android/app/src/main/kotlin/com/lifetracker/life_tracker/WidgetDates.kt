package com.lifetracker.life_tracker

import android.content.SharedPreferences
import android.graphics.Color
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/**
 * "Today", resolved when a widget DRAWS — not when Flutter last pushed data.
 *
 * Everything date-relative on a widget (which cell wears the ring, whether a
 * task reads "Today" or "Overdue") used to be baked into the payload by Dart.
 * That made a widget correct only until midnight: with the app closed there is
 * nothing to push a fresh payload, so the display froze showing yesterday.
 *
 * Deriving these from the clock at render time means ANY redraw is correct for
 * the day it happens on, however old the underlying data is — a tap, a resize,
 * the midnight alarm, or the launcher rebinding the widget. The stale-data
 * problem shrinks to what it should always have been: tasks you added or ticked
 * while the app was closed.
 */
object WidgetDates {

    /** Today as "yyyy-MM-dd" — the key format the payload uses throughout. */
    fun todayKey(): String = LocalDate.now().toString()

    /** The "Thu, 21 Aug" header line. */
    fun headerText(): String =
        LocalDate.now().format(DateTimeFormatter.ofPattern("EEE, d MMM"))

    /**
     * Whole days from today to [dateKey] (negative = past). Null if the string
     * isn't a date we can read.
     */
    fun daysFromToday(dateKey: String): Long? = try {
        ChronoUnit.DAYS.between(LocalDate.now(), LocalDate.parse(dateKey))
    } catch (_: Exception) {
        null
    }

    /**
     * A date headline for the task list: "Wed, 3 Sep • Today" / "• Tomorrow" /
     * "• Overdue", or the plain date further out.
     */
    fun dateHeadline(dateKey: String): String {
        val days = daysFromToday(dateKey) ?: return dateKey
        val base = try {
            LocalDate.parse(dateKey)
                .format(DateTimeFormatter.ofPattern("EEE, d MMM"))
        } catch (_: Exception) {
            return dateKey
        }
        return when {
            days == 0L -> "$base • Today"
            days == 1L -> "$base • Tomorrow"
            days < 0L -> "$base • Overdue"
            else -> base
        }
    }

    /** Short relative label for the agenda widget's second line. */
    fun agendaSub(dateKey: String): String {
        val days = daysFromToday(dateKey) ?: return dateKey
        return when {
            days == 0L -> "Today"
            days == 1L -> "Tomorrow"
            days < 0L -> "Overdue · " + shortDate(dateKey)
            else -> shortDate(dateKey)
        }
    }

    /** Colour for an agenda row: red overdue, blue today, muted otherwise. */
    fun agendaColor(dateKey: String): Int {
        val days = daysFromToday(dateKey)
        return when {
            days == null -> 0xFFB0B8C4.toInt()
            days < 0L -> 0xFFE57373.toInt()
            days == 0L -> 0xFF8AB4F8.toInt()
            else -> 0xFFB0B8C4.toInt()
        }
    }

    private fun shortDate(dateKey: String): String = try {
        LocalDate.parse(dateKey).format(DateTimeFormatter.ofPattern("EEE d MMM"))
    } catch (_: Exception) {
        dateKey
    }

    /**
     * Today's shift as (text, colour), out of the date-keyed map Dart pushes.
     * "Rest day" is the right fallback for a date with no row: no row means no
     * shift, whether that's a day off or data that predates it.
     */
    fun shiftFor(data: SharedPreferences, today: String): Pair<String, Int> {
        val fallback = Pair("Rest day", 0xFFBFC4CC.toInt())
        return try {
            val map = JSONObject(data.getString("shift_by_date", "{}") ?: "{}")
            val entry = map.optJSONObject(today) ?: return fallback
            Pair(
                entry.optString("t", "Rest day"),
                Color.parseColor(entry.optString("c", "#FFBFC4CC")),
            )
        } catch (_: Exception) {
            fallback
        }
    }

    /**
     * "2 habits left · 3 tasks due", rebuilt for today rather than replayed.
     *
     * Tasks are counted from the pushed list, which carries a date per task, so
     * the count is right on whatever day it is read. Habits can't be recomputed
     * without knowing what was ticked — but on a day the snapshot doesn't
     * cover, nothing has been ticked yet, so the full total is the honest answer.
     */
    fun countsFor(data: SharedPreferences, today: String): String {
        val snapshotDate = data.getString("snapshot_date", "") ?: ""
        val habitsLeft = if (snapshotDate == today) {
            readInt(data, "habits_left", 0)
        } else {
            readInt(data, "habits_total", 0)
        }
        var tasksDue = 0
        try {
            val arr = JSONArray(data.getString("combined_tasks", "[]") ?: "[]")
            for (i in 0 until arr.length()) {
                if (arr.getJSONObject(i).optString("date", "") == today) tasksDue++
            }
        } catch (_: Exception) {
        }
        if (habitsLeft == 0 && tasksDue == 0) return "All done for today"
        val h = if (habitsLeft == 1) "habit" else "habits"
        val t = if (tasksDue == 1) "task" else "tasks"
        return "$habitsLeft $h left · $tasksDue $t due"
    }

    /** home_widget may store a Dart int as a Long — read either shape. */
    private fun readInt(data: SharedPreferences, key: String, def: Int): Int = try {
        data.getInt(key, def)
    } catch (_: Exception) {
        try {
            data.getLong(key, def.toLong()).toInt()
        } catch (_: Exception) {
            def
        }
    }
}
