package com.marvel.todo.marvel_todo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar
import kotlin.math.roundToInt

class TodoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        private const val MAX_ITEMS = 10

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val totalXP = prefs.getLong("flutter.widget_totalXP", 0).toInt()
            val currentLevel = prefs.getLong("flutter.widget_currentLevel", 1).toInt()
            val streakDays = prefs.getLong("flutter.widget_streakDays", 0).toInt()
            val tasksCompleted = prefs.getLong("flutter.widget_totalTasksCompleted", 0).toInt()
            val lecturesCompleted = prefs.getLong("flutter.widget_totalLecturesCompleted", 0).toInt()
            val username = prefs.getString("flutter.widget_username", null) ?: "Hero"

            // XP calculations
            val xpForNextLevel = currentLevel * 100 + 50
            var xpForCurrentLevelStart = 0
            for (i in 1 until currentLevel) {
                xpForCurrentLevelStart += i * 100 + 50
            }
            val xpInCurrentLevel = totalXP - xpForCurrentLevelStart
            val progressPercent = ((xpInCurrentLevel.toFloat() / xpForNextLevel) * 100).roundToInt().coerceIn(0, 100)

            val heroTitle = when {
                currentLevel >= 20 -> "LEGEND"
                currentLevel >= 15 -> "CHAMPION"
                currentLevel >= 10 -> "AVENGER"
                currentLevel >= 5 -> "AGENT"
                else -> "RECRUIT"
            }

            // Dynamic greeting based on time of day
            val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            val greeting = when {
                hour < 5 -> "Late night, $username."
                hour < 12 -> "Good morning, $username."
                hour < 17 -> "Good afternoon, $username."
                hour < 21 -> "Good evening, $username."
                else -> "Late night, $username."
            }

            // Pending tasks and lectures counts
            var remainingTasks = 0
            var remainingLectures = 0

            val tasksJson = prefs.getString("flutter.widget_tasks", null)
            if (tasksJson != null) {
                try {
                    val arr = JSONArray(tasksJson)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        if (!obj.getBoolean("completed")) remainingTasks++
                    }
                } catch (_: Exception) {}
            }

            val lecJson = prefs.getString("flutter.widget_lectures", null)
            if (lecJson != null) {
                try {
                    val arr = JSONArray(lecJson)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        if (!obj.getBoolean("completed")) remainingLectures++
                    }
                } catch (_: Exception) {}
            }

            // Read combined pending items list
            val pendingItems = mutableListOf<Pair<String, String>>() // type, title
            val pendingJson = prefs.getString("flutter.widget_pending_items", null)
            if (pendingJson != null) {
                try {
                    val arr = JSONArray(pendingJson)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        pendingItems.add(Pair(
                            obj.optString("type", "task"),
                            obj.optString("title", "")
                        ))
                    }
                } catch (_: Exception) {}
            }

            val views = RemoteViews(context.packageName, R.layout.todo_widget)

            // Populate header
            views.setTextViewText(R.id.widget_streak, "$streakDays")
            views.setTextViewText(R.id.widget_hero_title, heroTitle)
            views.setTextViewText(R.id.widget_level, "$currentLevel")
            views.setTextViewText(R.id.widget_welcome, greeting)
            views.setTextViewText(R.id.widget_tasks_value, "$tasksCompleted")
            views.setTextViewText(R.id.widget_xp_value, "$totalXP")
            views.setTextViewText(R.id.widget_lectures_value, "$lecturesCompleted")
            views.setTextViewText(R.id.widget_level_label, "Level $currentLevel")
            views.setTextViewText(R.id.widget_xp_progress_label, "$xpInCurrentLevel / $xpForNextLevel XP")
            views.setProgressBar(R.id.widget_xp_progress, 100, progressPercent, false)
            views.setTextViewText(R.id.widget_remaining_tasks, "$remainingTasks")
            views.setTextViewText(R.id.widget_remaining_lectures, "$remainingLectures")

            // Populate pending items list (no cap — show as many as layout supports)
            val itemIds = listOf(
                R.id.widget_item_1, R.id.widget_item_2, R.id.widget_item_3,
                R.id.widget_item_4, R.id.widget_item_5, R.id.widget_item_6,
                R.id.widget_item_7, R.id.widget_item_8, R.id.widget_item_9,
                R.id.widget_item_10
            )
            val dotIds = listOf(
                R.id.widget_item_dot_1, R.id.widget_item_dot_2, R.id.widget_item_dot_3,
                R.id.widget_item_dot_4, R.id.widget_item_dot_5, R.id.widget_item_dot_6,
                R.id.widget_item_dot_7, R.id.widget_item_dot_8, R.id.widget_item_dot_9,
                R.id.widget_item_dot_10
            )

            for (i in 0 until MAX_ITEMS) {
                if (i < pendingItems.size) {
                    val item = pendingItems[i]
                    val prefix = when (item.first) {
                        "course" -> "\u25A0 "
                        "lecture" -> "▶ "
                        else -> "○ "
                    }
                    views.setTextViewText(itemIds[i], "$prefix${item.second}")
                    views.setViewVisibility(itemIds[i], View.VISIBLE)
                    views.setViewVisibility(dotIds[i], View.VISIBLE)
                } else {
                    views.setViewVisibility(itemIds[i], View.GONE)
                    views.setViewVisibility(dotIds[i], View.GONE)
                }
            }

            // Tap to launch app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TodoWidgetProvider::class.java))
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }
    }
}
