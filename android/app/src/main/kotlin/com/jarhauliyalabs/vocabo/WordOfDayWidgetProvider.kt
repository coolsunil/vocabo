package com.jarhauliyalabs.vocabo

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.app.PendingIntent
import org.json.JSONArray
import java.util.Calendar

class WordOfDayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val (word, meaningEn, meaningHi, example) = getTodaysWord(context)

        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.word_of_day_widget)
            views.setTextViewText(R.id.widget_word, word)
            views.setTextViewText(R.id.widget_meaning, meaningEn)
            views.setTextViewText(R.id.widget_meaning_hi, meaningHi)
            views.setTextViewText(R.id.widget_example, example)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private data class WordData(
        val word: String,
        val meaningEn: String,
        val meaningHi: String,
        val example: String,
    )

    private fun getTodaysWord(context: Context): WordData {
        val cal = Calendar.getInstance()
        val today = "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.MONTH) + 1}-${cal.get(Calendar.DAY_OF_MONTH)}"

        // Use Flutter-pushed data only if it was saved today
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val pushedDate = prefs.getString("wod_date", null)
        if (pushedDate == today) {
            val word = prefs.getString("wod_word", null)
            if (!word.isNullOrEmpty()) {
                val meaningEn = prefs.getString("wod_meaning_en", "") ?: ""
                val meaningHi = prefs.getString("wod_meaning_hi", "") ?: ""
                val example = prefs.getString("wod_example", "") ?: ""
                return WordData(word, meaningEn.ifEmpty { meaningHi }, meaningHi, example)
            }
        }

        // Fallback: compute from JSON (before app is opened today)
        return try {
            val json = context.assets
                .open("flutter_assets/assets/data/core_words.json")
                .bufferedReader().use { it.readText() }
            val array = JSONArray(json)
            val seed = (cal.get(Calendar.YEAR) * 10000 +
                    (cal.get(Calendar.MONTH) + 1) * 100 +
                    cal.get(Calendar.DAY_OF_MONTH)).toLong()
            val index = (seed % array.length()).toInt()
            val obj = array.getJSONObject(index)
            val word = obj.optString("word").ifEmpty { "—" }
            val meaningEn = obj.optString("meaning_en")
            val meaningHi = obj.optString("meaning_hi")
            val example = obj.optString("example")
            WordData(word, meaningEn.ifEmpty { meaningHi }, meaningHi, example)
        } catch (e: Exception) {
            WordData("—", "Open Vocabo to load today's word", "", "")
        }
    }
}
