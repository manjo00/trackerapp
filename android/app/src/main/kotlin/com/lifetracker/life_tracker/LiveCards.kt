package com.lifetracker.life_tracker

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import org.json.JSONArray
import org.json.JSONObject

/**
 * Turns the raw items Dart pushes into the slideshow cards the live
 * notification shows — bucketed, worded and coloured **at draw time**.
 *
 * This notification can stay on screen for days. When Dart decided the buckets
 * and the wording, a task that went overdue at midnight kept saying "Due
 * today", a task due tomorrow stayed in Captured, and habits ticked yesterday
 * never came back — until something happened to run the app. Working it out
 * here means a redraw is enough, and [MidnightRefreshReceiver] books one.
 *
 * The card `type` still says "inbox" for the captured bucket: snooze keys are
 * stored as "type:id", and renaming it would orphan every snooze saved before.
 */
object LiveCards {

    private const val OVERDUE = "#FFE57373" // red — beats the priority colour
    private const val HABIT = "#FFA6ABEC"   // periwinkle
    private const val CAPTURED = "#FF8E9AAF" // slate

    data class Card(
        val type: String,
        val id: Int,
        val title: String,
        val sub: String,
        val color: Int,
    )

    private data class Item(
        val type: String,
        val id: Int,
        val title: String,
        val date: String?,
        val time: String?,
        val prio: Int,
        val listed: Boolean,
    )

    /** Task priority (0 low / 1 med / 2 high) → accent hex. */
    private fun priorityHex(p: Int): String = when (p) {
        2 -> "#FFE07070" // high — soft red
        0 -> "#FF8E9AAF" // low — muted slate
        else -> "#FFFFB347" // medium — warm amber
    }

    fun parseColor(hex: String): Int = try {
        Color.parseColor(hex)
    } catch (_: IllegalArgumentException) {
        0xFF8E9AAF.toInt()
    }

    /**
     * The cards to show right now: overdue (most overdue first), then due
     * today, then habits still to tick, then captured.
     */
    fun build(context: Context, nowMillis: Long): List<Card> {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences", Context.MODE_PRIVATE)
        val today = WidgetDates.todayKey()
        val items = readItems(prefs)
        val snoozed = readSnoozes(prefs, nowMillis)
        val hiddenHabits = readDoneHabits(prefs, today)

        // Overdue keeps its due date alongside the card so the sort is by
        // date, not by the rendered text ("10d overdue" sorts before "3d").
        val overdue = mutableListOf<Pair<String, Card>>()
        val dueToday = mutableListOf<Card>()
        val habits = mutableListOf<Card>()
        val captured = mutableListOf<Card>()

        for (item in items) {
            if (item.type == "habit") {
                if (item.id in hiddenHabits) continue
                if ("habit:${item.id}" in snoozed) continue
                habits.add(Card("habit", item.id, item.title, "Habit",
                    parseColor(HABIT)))
                continue
            }

            val date = item.date
            val daysLate = if (date == null) null else WidgetDates.daysFromToday(date)
            when {
                // Overdue: a due date that has already gone by. The explicit
                // date null-check is what lets it be used as the sort key.
                date != null && daysLate != null && daysLate < 0L -> {
                    if ("task:${item.id}" in snoozed) continue
                    val n = -daysLate
                    overdue.add(
                        date to Card("task", item.id, item.title,
                            "${n}d overdue", parseColor(OVERDUE))
                    )
                }
                // Due today.
                daysLate != null && daysLate == 0L -> {
                    if ("task:${item.id}" in snoozed) continue
                    val time = if (item.time.isNullOrEmpty()) "" else " · ${item.time}"
                    dueToday.add(Card("task", item.id, item.title,
                        "Due today$time", parseColor(priorityHex(item.prio))))
                }
                // Captured: filed nowhere, and not due before some later day.
                !item.listed -> {
                    if ("inbox:${item.id}" in snoozed) continue
                    captured.add(Card("inbox", item.id, item.title, "Captured",
                        parseColor(CAPTURED)))
                }
            }
        }

        overdue.sortBy { it.first } // oldest due date first = most overdue
        return overdue.map { it.second } + dueToday + habits + captured
    }

    private fun readItems(prefs: SharedPreferences): List<Item> {
        val json = prefs.getString("live_items", "[]") ?: "[]"
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).mapNotNull { i ->
                val o = arr.optJSONObject(i) ?: return@mapNotNull null
                Item(
                    type = o.optString("type", "task"),
                    id = o.optInt("id", 0),
                    title = o.optString("title", ""),
                    date = if (o.isNull("date")) null else o.optString("date"),
                    time = if (o.isNull("time")) null else o.optString("time"),
                    prio = o.optInt("prio", 1),
                    listed = o.optBoolean("listed", false),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /** Snooze keys still in force at [nowMillis]. */
    private fun readSnoozes(prefs: SharedPreferences, nowMillis: Long): Set<String> {
        val json = prefs.getString("live_snoozes", "{}") ?: "{}"
        return try {
            val obj = JSONObject(json)
            obj.keys().asSequence()
                .filter { obj.optLong(it, 0L) > nowMillis }
                .toSet()
        } catch (_: Exception) {
            emptySet()
        }
    }

    /**
     * Habits already ticked — but only if the snapshot describes today. On any
     * later day nothing has been ticked yet, so they all come back on their own.
     */
    private fun readDoneHabits(prefs: SharedPreferences, today: String): Set<Int> {
        if ((prefs.getString("live_snapshot_date", "") ?: "") != today) return emptySet()
        val json = prefs.getString("live_habits_done", "[]") ?: "[]"
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { arr.optInt(it, -1) }.toSet()
        } catch (_: Exception) {
            emptySet()
        }
    }
}
