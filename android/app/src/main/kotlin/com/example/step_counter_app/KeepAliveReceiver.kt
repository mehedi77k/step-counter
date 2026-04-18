package com.example.step_counter_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class KeepAliveReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == StepForegroundService.ACTION_KEEP_ALIVE) {
            StepForegroundService.startService(context)
            StepForegroundService.scheduleKeepAlive(context)
        }
    }
}
