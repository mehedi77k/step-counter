package com.example.step_counter_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.AlarmManager
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.concurrent.CopyOnWriteArraySet

class StepForegroundService : Service(), SensorEventListener {

    companion object {
        const val PREFS_NAME = "step_counter_bg"
        const val KEY_LAST_SENSOR = "last_sensor"
        const val KEY_TODAY_STEPS = "today_steps"
        const val KEY_DATE = "date"
        const val KEY_ALERT_ENABLED = "alert_enabled"
        const val KEY_ALERT_INTERVAL = "alert_interval"
        const val KEY_LAST_ALERT_MILESTONE = "last_alert_milestone"
        const val KEY_ALERT_QUIET_ENABLED = "alert_quiet_enabled"
        const val KEY_ALERT_QUIET_START_MIN = "alert_quiet_start_min"
        const val KEY_ALERT_QUIET_END_MIN = "alert_quiet_end_min"

        private const val CHANNEL_ID = "step_counter_tracking"
        private const val CHANNEL_NAME = "Step Tracking"
        private const val NOTIFICATION_ID = 701
        private const val KEEP_ALIVE_ALARM_REQUEST = 1701
        private const val RESTART_ALARM_REQUEST = 1702
        const val ACTION_KEEP_ALIVE = "com.example.step_counter_app.ACTION_KEEP_ALIVE"
        private val stepUpdateListeners = CopyOnWriteArraySet<(Int) -> Unit>()

        fun startService(context: Context): Boolean {
            val intent = Intent(context, StepForegroundService::class.java)
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                true
            } catch (_: Exception) {
                // On aggressive OEM/background-restricted devices this may fail temporarily.
                // Queue another restart attempt instead of letting tracking die silently.
                scheduleImmediateRestart(context, 6000L)
                false
            }
        }

        fun stopService(context: Context) {
            context.stopService(Intent(context, StepForegroundService::class.java))
        }

        fun getTodaySteps(context: Context): Int {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-M-d", Locale.US).format(Date())
            val storedDate = prefs.getString(KEY_DATE, today)
            return if (storedDate == today) {
                prefs.getInt(KEY_TODAY_STEPS, 0)
            } else {
                0
            }
        }

        fun addStepUpdateListener(listener: (Int) -> Unit) {
            stepUpdateListeners.add(listener)
        }

        fun removeStepUpdateListener(listener: (Int) -> Unit) {
            stepUpdateListeners.remove(listener)
        }

        fun isServiceRunning(context: Context): Boolean {
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            @Suppress("DEPRECATION")
            for (service in manager.getRunningServices(Int.MAX_VALUE)) {
                if (StepForegroundService::class.java.name == service.service.className) {
                    return true
                }
            }
            return false
        }

        private fun notifyStepUpdate(steps: Int) {
            for (listener in stepUpdateListeners) {
                listener(steps)
            }
        }

        fun scheduleKeepAlive(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, KeepAliveReceiver::class.java).apply {
                action = ACTION_KEEP_ALIVE
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                KEEP_ALIVE_ALARM_REQUEST,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val nextTrigger = System.currentTimeMillis() + 5 * 60 * 1000L
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                nextTrigger,
                pendingIntent
            )
        }

        fun scheduleImmediateRestart(context: Context, delayMs: Long = 250L) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val restartIntent = Intent(context, StepForegroundService::class.java)
            val restartPendingIntent = PendingIntent.getService(
                context,
                RESTART_ALARM_REQUEST,
                restartIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val triggerAt = SystemClock.elapsedRealtime() + delayMs
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAt,
                        restartPendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAt,
                        restartPendingIntent
                    )
                }
            } catch (_: SecurityException) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    restartPendingIntent
                )
            }
        }
    }

    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null

    override fun onCreate() {
        super.onCreate()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    }

    private fun ensureTodayStore() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = SimpleDateFormat("yyyy-M-d", Locale.US).format(Date())
        val savedDate = prefs.getString(KEY_DATE, null)

        if (savedDate == today) {
            return
        }

        prefs.edit()
            .putString(KEY_DATE, today)
            .putInt(KEY_TODAY_STEPS, 0)
            .putFloat(KEY_LAST_SENSOR, -1f)
            .putInt(KEY_LAST_ALERT_MILESTONE, 0)
            .apply()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureTodayStore()
        startForeground(NOTIFICATION_ID, buildNotification(currentStepsText()))
        scheduleKeepAlive(this)
        notifyStepUpdate(getTodaySteps(this))

        sensorManager?.unregisterListener(this)
        val registered = sensorManager?.registerListener(
            this,
            stepSensor,
            SensorManager.SENSOR_DELAY_NORMAL
        ) ?: false

        if (!registered) {
            stopSelf()
        }

        return START_STICKY
    }

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        scheduleKeepAlive(this)
        scheduleImmediateRestart(this)
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Some OEMs kill foreground services when the task is swiped from recents.
        // Schedule restart so counting can continue after task removal.
        startService(applicationContext)
        scheduleKeepAlive(this)
        scheduleImmediateRestart(applicationContext)
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_STEP_COUNTER) {
            return
        }

        val currentCounter = event.values[0]
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = SimpleDateFormat("yyyy-M-d", Locale.US).format(Date())

        var storedDate = prefs.getString(KEY_DATE, null)
        var lastSensor = prefs.getFloat(KEY_LAST_SENSOR, -1f)
        var todaySteps = prefs.getInt(KEY_TODAY_STEPS, 0)

        if (storedDate != today) {
            storedDate = today
            todaySteps = 0
            lastSensor = currentCounter
            prefs.edit().putInt(KEY_LAST_ALERT_MILESTONE, 0).apply()
        }

        if (lastSensor < 0f) {
            lastSensor = currentCounter
        }

        var delta = (currentCounter - lastSensor).toInt()
        if (delta < 0) {
            // Sensor may reset after reboot; continue from fresh baseline.
            delta = currentCounter.toInt()
        }

        todaySteps += delta

        var lastAlertMilestone = prefs.getInt(KEY_LAST_ALERT_MILESTONE, 0)
        val alertEnabled = prefs.getBoolean(KEY_ALERT_ENABLED, true)
        val alertInterval = prefs.getInt(KEY_ALERT_INTERVAL, 1000).coerceAtLeast(100)
        val quietEnabled = prefs.getBoolean(KEY_ALERT_QUIET_ENABLED, false)
        val quietStartMin = prefs.getInt(KEY_ALERT_QUIET_START_MIN, 1320).coerceIn(0, 1439)
        val quietEndMin = prefs.getInt(KEY_ALERT_QUIET_END_MIN, 420).coerceIn(0, 1439)
        val currentMilestone = todaySteps / alertInterval
        val nowMinutes = currentMinuteOfDay()
        val inQuietHours = quietEnabled && isInQuietHours(nowMinutes, quietStartMin, quietEndMin)

        if (alertEnabled && !inQuietHours && currentMilestone > lastAlertMilestone && todaySteps >= alertInterval) {
            val reached = currentMilestone * alertInterval
            sendMilestoneNotification(reached)
            lastAlertMilestone = currentMilestone
        }

        prefs.edit()
            .putString(KEY_DATE, storedDate)
            .putFloat(KEY_LAST_SENSOR, currentCounter)
            .putInt(KEY_TODAY_STEPS, todaySteps)
            .putInt(KEY_LAST_ALERT_MILESTONE, lastAlertMilestone)
            .apply()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification("$todaySteps steps today"))
        notifyStepUpdate(todaySteps)
        StepCounterWidgetProvider.updateAllWidgets(this)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
    }

    private fun currentStepsText(): String {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val todaySteps = prefs.getInt(KEY_TODAY_STEPS, 0)
        return "$todaySteps steps today"
    }

    private fun buildNotification(content: String): Notification {
        createNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Step Counter")
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun sendMilestoneNotification(reachedSteps: Int) {
        createNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val milestoneNotification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Step milestone reached")
            .setContentText("Awesome! You reached $reachedSteps steps.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(1702, milestoneNotification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        )
        channel.setShowBadge(false)
        channel.enableVibration(false)
        channel.setSound(null, null)
        channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        manager.createNotificationChannel(channel)
    }

    private fun currentMinuteOfDay(): Int {
        val now = Calendar.getInstance()
        return now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
    }

    private fun isInQuietHours(nowMin: Int, startMin: Int, endMin: Int): Boolean {
        if (startMin == endMin) {
            return false
        }

        return if (startMin < endMin) {
            nowMin in startMin until endMin
        } else {
            nowMin >= startMin || nowMin < endMin
        }
    }
}
