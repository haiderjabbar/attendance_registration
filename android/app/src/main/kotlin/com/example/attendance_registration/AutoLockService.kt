package com.example.attendance_registration

import android.app.*
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.media.RingtoneManager
import android.os.*
import android.provider.Settings
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat

class AutoLockService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var runnable: Runnable
    private var cancelLock = false
    private var overlayShownCount = 0

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()

        // interval in seconds (e.g., 50 minutes -> 3000)
        val interval = intent?.getIntExtra("interval", 30) ?: 30
        val interval2=interval/60;
        val initialNotification = NotificationCompat.Builder(this, "lock_channel")
            .setContentTitle("وقت الدرس")
            .setContentText("المتبقي: $interval2  دقيقة ")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(1, initialNotification)

        handler.removeCallbacksAndMessages(null)
        overlayShownCount = 0

        val policyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminReceiver = ComponentName(this, MyDeviceAdminReceiver::class.java)

        android.util.Log.d("AutoLockService", "Lock interval: $interval seconds")

        runnable = object : Runnable {
            override fun run() {
                cancelLock = false
                android.util.Log.d("AutoLockService", "Running with interval $interval")

                if (policyManager.isAdminActive(adminReceiver)) {
                    if (overlayShownCount < 2) {
                        showPreLockNotification()
                        showOverlayDialog { canceled ->
                            if (!canceled) {
                                handler.postDelayed({
                                    if (!cancelLock) {
                                        policyManager.lockNow()
                                        android.util.Log.d("AutoLockService", "Device locked")
                                    }
                                }, 1000)
                            }
                        }
                        overlayShownCount++
                    }
                }

                // schedule next run after `interval` seconds
                handler.postDelayed(this, interval * 1000L)
            }
        }

        handler.post(runnable)
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(runnable)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "lock_channel",
                "Lock Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                enableLights(true)
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                description = "Notifications for auto-lock warnings"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun showPreLockNotification() {
        val notification = NotificationCompat.Builder(this, "lock_channel")
            .setContentTitle("⚠️ وقت انتهاء الدرس قريباً")
            .setContentText("سيتم قفل الجهاز خلال 10 ثوانٍ")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setAutoCancel(true)
            .build()
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify((System.currentTimeMillis() % 10000).toInt(), notification)
    }

    private var isOverlayAttached = false

    private fun showOverlayDialog(onComplete: (canceled: Boolean) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            android.util.Log.e("OverlayDialog", "Overlay permission not granted")
            return
        }
        if (isAppInForeground()) {
            android.util.Log.d("OverlayDialog", "App in foreground, skipping overlay")
            return
        }

        val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
        val overlayView = inflater.inflate(R.layout.overlay_dialog, null)
        val textView = overlayView.findViewById<TextView>(R.id.overlay_message)
        val cancelButton = overlayView.findViewById<Button>(R.id.cancel_button)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            PixelFormat.TRANSLUCENT
        )

        try {
            windowManager.addView(overlayView, params)
            isOverlayAttached = true
        } catch (e: Exception) {
            e.printStackTrace()
            return
        }

        cancelButton.setOnClickListener {
            cancelLock = true
            if (isOverlayAttached) {
                try {
                    windowManager.removeView(overlayView)
                    isOverlayAttached = false
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            onComplete(true)
        }

        var count = 10
        val countdownHandler = Handler(Looper.getMainLooper())
        val countdownRunnable = object : Runnable {
            override fun run() {
                if (count > 0) {
                    textView.text = "🔒 القفل خلال $count ثانية..."
                    count--
                    countdownHandler.postDelayed(this, 1000)
                } else {
                    if (isOverlayAttached) {
                        try {
                            windowManager.removeView(overlayView)
                            isOverlayAttached = false
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    onComplete(false)
                }
            }
        }

        countdownHandler.post(countdownRunnable)
    }

    private fun isAppInForeground(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val pkg = packageName
        return appProcesses.any {
            it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                    it.processName == pkg
        }
    }
}
