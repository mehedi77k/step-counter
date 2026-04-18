package com.example.step_counter_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.DecimalFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt

open class StepCounterWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.example.step_counter_app.ACTION_REFRESH_WIDGET"

        private data class WidgetVariant(
            val providerClass: Class<out AppWidgetProvider>,
            val layoutRes: Int
        )

        private val variants = listOf(
            WidgetVariant(StepCounterWidgetProvider::class.java, R.layout.step_counter_widget),
            WidgetVariant(StepCounterWidgetCompactProvider::class.java, R.layout.step_counter_widget_compact),
            WidgetVariant(StepCounterWidgetWideProvider::class.java, R.layout.step_counter_widget_wide),
            WidgetVariant(StepCounterWidgetTallProvider::class.java, R.layout.step_counter_widget_tall),
            WidgetVariant(StepCounterWidgetXlProvider::class.java, R.layout.step_counter_widget_xl)
        )

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for (variant in variants) {
                val component = ComponentName(context, variant.providerClass)
                val ids = manager.getAppWidgetIds(component)
                for (id in ids) {
                    updateWidget(context, manager, id, variant.layoutRes)
                }
            }
        }

        private fun layoutForProvider(providerClass: Class<out AppWidgetProvider>): Int {
            return variants.firstOrNull { it.providerClass == providerClass }?.layoutRes
                ?: R.layout.step_counter_widget
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            layoutRes: Int
        ) {
            val servicePrefs = context.getSharedPreferences(StepForegroundService.PREFS_NAME, Context.MODE_PRIVATE)
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val lockEnabled = flutterPrefs.getBoolean("flutter.widget_lock_enabled", false)

            val today = SimpleDateFormat("yyyy-M-d", Locale.US).format(Date())
            val storedDate = servicePrefs.getString(StepForegroundService.KEY_DATE, today)
            val todaySteps = if (storedDate == today) {
                servicePrefs.getInt(StepForegroundService.KEY_TODAY_STEPS, 0)
            } else {
                0
            }

            val goal = readGoal(flutterPrefs)
            val progress = ((todaySteps.toFloat() / max(1, goal).toFloat()) * 100).roundToInt().coerceIn(0, 100)
            val calories = (todaySteps * 0.05).roundToInt()
            val distanceKm = todaySteps * 0.00075
            val activeMin = max(1, (todaySteps / 180.0).roundToInt())

            val views = RemoteViews(context.packageName, layoutRes)
            views.setTextViewText(R.id.widget_steps_value, DecimalFormat("#,###").format(todaySteps))
            views.setTextViewText(R.id.widget_goal_value, "/${DecimalFormat("#,###").format(goal)}")
            views.setTextViewText(R.id.widget_percent, "$progress%")
            views.setProgressBar(R.id.widget_progress, 100, progress, false)
            if (lockEnabled) {
                views.setTextViewText(R.id.widget_calories, "$calories kcal")
                views.setTextViewText(R.id.widget_distance, "${String.format(Locale.US, "%.2f", distanceKm)} km")
                views.setTextViewText(R.id.widget_minutes, "$activeMin min")
            } else {
                views.setTextViewText(R.id.widget_calories, "lock OFF")
                views.setTextViewText(R.id.widget_distance, "enable in app")
                views.setTextViewText(R.id.widget_minutes, "settings")
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val openApp = PendingIntent.getActivity(
                    context,
                    appWidgetId,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_btn_start, openApp)
                views.setOnClickPendingIntent(R.id.widget_btn_water, openApp)
                views.setOnClickPendingIntent(R.id.widget_root, openApp)
            }

            manager.updateAppWidget(appWidgetId, views)
        }

        private fun readGoal(prefs: android.content.SharedPreferences): Int {
            val key = "flutter.daily_goal"
            return when {
                prefs.contains(key) -> prefs.all[key].toString().toIntOrNull() ?: 10000
                else -> 10000
            }.coerceIn(5000, 25000)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val layoutRes = layoutForProvider(javaClass)
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id, layoutRes)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH || intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            updateAllWidgets(context)
        }
    }
}

class StepCounterWidgetCompactProvider : StepCounterWidgetProvider()

class StepCounterWidgetWideProvider : StepCounterWidgetProvider()

class StepCounterWidgetTallProvider : StepCounterWidgetProvider()

class StepCounterWidgetXlProvider : StepCounterWidgetProvider()
