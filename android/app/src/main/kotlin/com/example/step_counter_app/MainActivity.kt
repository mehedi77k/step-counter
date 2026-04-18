package com.example.step_counter_app

import android.app.ActivityManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "step_counter/bg_service"
	private val eventChannelName = "step_counter/step_updates"
	private var stepListener: ((Int) -> Unit)? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					if (events == null) {
						return
					}

					val initialSteps = StepForegroundService.getTodaySteps(this@MainActivity)
					events.success(mapOf("steps" to initialSteps))

					val listener: (Int) -> Unit = { steps ->
						runOnUiThread {
							events.success(mapOf("steps" to steps))
						}
					}
					stepListener = listener
					StepForegroundService.addStepUpdateListener(listener)
				}

				override fun onCancel(arguments: Any?) {
					stepListener?.let { StepForegroundService.removeStepUpdateListener(it) }
					stepListener = null
				}
			})

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"startService" -> {
						result.success(StepForegroundService.startService(this))
					}

					"stopService" -> {
						StepForegroundService.stopService(this)
						result.success(true)
					}

					"getTodaySteps" -> {
						val prefs = getSharedPreferences(
							StepForegroundService.PREFS_NAME,
							Context.MODE_PRIVATE
						)
						result.success(
							prefs.getInt(StepForegroundService.KEY_TODAY_STEPS, 0)
						)
					}

					"requestPinWidget" -> {
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
							val manager = getSystemService(AppWidgetManager::class.java)
							val provider = ComponentName(this, StepCounterWidgetProvider::class.java)
							val supported = manager?.isRequestPinAppWidgetSupported == true
							if (supported) {
								val requested = manager?.requestPinAppWidget(provider, null, null) ?: false
								result.success(requested)
							} else {
								result.success(false)
							}
						} else {
							result.success(false)
						}
					}

					"openLockScreenSettings" -> {
						val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(true)
					}

					"refreshWidget" -> {
						StepCounterWidgetProvider.updateAllWidgets(this)
						result.success(true)
					}

					"getBackgroundStatus" -> {
						val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
						val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

						val ignoringBatteryOptimizations = powerManager.isIgnoringBatteryOptimizations(packageName)
						val backgroundRestricted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
							activityManager.isBackgroundRestricted
						} else {
							false
						}

						val autoStartIntent = resolveAutoStartIntent()
						val autoStartAvailable = autoStartIntent != null

						val payload = mapOf(
							"ignoringBatteryOptimizations" to ignoringBatteryOptimizations,
							"backgroundRestricted" to backgroundRestricted,
							"autoStartSettingsAvailable" to autoStartAvailable,
							"autoStartVendor" to Build.MANUFACTURER,
							"serviceRunning" to isServiceRunning()
						)
						result.success(payload)
					}

					"openBatteryOptimizationSettings" -> {
						val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(true)
					}

					"requestIgnoreBatteryOptimization" -> {
						val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
							data = Uri.parse("package:$packageName")
							addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						}
						startActivity(intent)
						result.success(true)
					}

					"openAutoStartSettings" -> {
						val target = resolveAutoStartIntent() ?: Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
							data = Uri.parse("package:$packageName")
						}
						target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(target)
						result.success(true)
					}

					"openBackgroundRestrictionSettings" -> {
						val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
							data = Uri.parse("package:$packageName")
						}
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(true)
					}

					"getStepAlertSettings" -> {
						val prefs = getSharedPreferences(
							StepForegroundService.PREFS_NAME,
							Context.MODE_PRIVATE
						)
						result.success(
							mapOf(
								"enabled" to prefs.getBoolean(StepForegroundService.KEY_ALERT_ENABLED, true),
								"interval" to prefs.getInt(StepForegroundService.KEY_ALERT_INTERVAL, 1000),
								"quietEnabled" to prefs.getBoolean(StepForegroundService.KEY_ALERT_QUIET_ENABLED, false),
								"quietStartMin" to prefs.getInt(StepForegroundService.KEY_ALERT_QUIET_START_MIN, 1320),
								"quietEndMin" to prefs.getInt(StepForegroundService.KEY_ALERT_QUIET_END_MIN, 420)
							)
						)
					}

					"setStepAlertSettings" -> {
						val enabled = call.argument<Boolean>("enabled") ?: true
						val interval = (call.argument<Int>("interval") ?: 1000).coerceAtLeast(100)
						val quietEnabled = call.argument<Boolean>("quietEnabled") ?: false
						val quietStartMin = (call.argument<Int>("quietStartMin") ?: 1320).coerceIn(0, 1439)
						val quietEndMin = (call.argument<Int>("quietEndMin") ?: 420).coerceIn(0, 1439)
						val prefs = getSharedPreferences(
							StepForegroundService.PREFS_NAME,
							Context.MODE_PRIVATE
						)
						prefs.edit()
							.putBoolean(StepForegroundService.KEY_ALERT_ENABLED, enabled)
							.putInt(StepForegroundService.KEY_ALERT_INTERVAL, interval)
							.putBoolean(StepForegroundService.KEY_ALERT_QUIET_ENABLED, quietEnabled)
							.putInt(StepForegroundService.KEY_ALERT_QUIET_START_MIN, quietStartMin)
							.putInt(StepForegroundService.KEY_ALERT_QUIET_END_MIN, quietEndMin)
							.apply()
						result.success(true)
					}

					else -> result.notImplemented()
				}
			}
	}

	override fun onDestroy() {
		stepListener?.let { StepForegroundService.removeStepUpdateListener(it) }
		stepListener = null
		super.onDestroy()
	}

	private fun isServiceRunning(): Boolean {
		return StepForegroundService.isServiceRunning(this)
	}

	private fun resolveAutoStartIntent(): Intent? {
		val intents = listOf(
			Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
			Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
			Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
			Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
			Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
			Intent().setComponent(ComponentName("com.transsion.phonemaster", "com.cyin.himgr.autostart.AutoStartActivity"))
		)

		for (intent in intents) {
			if (intent.resolveActivity(packageManager) != null) {
				return intent
			}
		}
		return null
	}
}
