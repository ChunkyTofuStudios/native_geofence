package com.chunkytofustudios.native_geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NativeGeofenceRebootBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "NativeGeofenceReboot"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "Setting boot completed marker!")
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean(Constants.BOOT_COMPLETED_RECEIVED_MARKER, true)
            .apply()

        Log.i(TAG, "Re-registering geofences!")
        NativeGeofencePlugin.reRegisterAfterReboot(context)
    }
}
