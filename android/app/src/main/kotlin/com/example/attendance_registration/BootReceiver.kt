package com.example.attendance_registration

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.i("BootReceiver", "Boot broadcast: ${intent.action}")
        // Optionally start a lightweight foreground service to prep things
        // (Your UI will appear because MainActivity is HOME.)
        val svc = Intent(context, AutoLockService::class.java)
        svc.putExtra("interval", 30)
        ContextCompat.startForegroundService(context, svc)
    }
}
