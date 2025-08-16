package com.example.attendance_registration

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.attendance/lock"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "lockScreen" -> {
                    val policyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val adminReceiver = ComponentName(this, MyDeviceAdminReceiver::class.java)

                    if (policyManager.isAdminActive(adminReceiver)) {
                        policyManager.lockNow()
                        result.success("Locked")
                    } else {
                        result.error("NOT_ADMIN", "Not a device admin", null)
                    }
                }

                "startLockService" -> {
                    val interval = call.argument<Int>("interval") ?: 30
                    val serviceIntent = Intent(this, AutoLockService::class.java)
                    serviceIntent.putExtra("interval", interval)
                    startForegroundService(serviceIntent)
                    result.success("Lock service started with interval $interval sec")
                }

                "showTestNotification" -> {
                    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val channelId = "lock_channel"

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val channel = NotificationChannel(
                            channelId,
                            "Test Notifications",
                            NotificationManager.IMPORTANCE_HIGH
                        ).apply {
                            description = "Channel for testing notifications"
                            enableLights(true)
                            enableVibration(true)
                        }
                        manager.createNotificationChannel(channel)
                    }

                    val notification = NotificationCompat.Builder(this, channelId)
                        .setContentTitle("🔔 Test Notification")
                        .setContentText("This is a manual test of the notification system.")
                        .setSmallIcon(android.R.drawable.ic_dialog_info)
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .setDefaults(NotificationCompat.DEFAULT_ALL)
                        .setAutoCancel(true)
                        .build()

                    manager.notify(99, notification)
                    result.success("Test notification shown")
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
