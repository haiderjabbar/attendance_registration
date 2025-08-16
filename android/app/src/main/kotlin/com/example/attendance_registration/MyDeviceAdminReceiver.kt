package com.example.attendance_registration

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class MyDeviceAdminReceiver : DeviceAdminReceiver() {
    private fun showToast(context: Context, msg: String) {
        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
    }

    override fun onEnabled(context: Context, intent: Intent) {
        showToast(context, "Device Admin: enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        showToast(context, "Device Admin: disabled")
    }
}
