package com.chunkytofustudios.native_geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NativeGeofenceRebootBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        //if (intent.getAction().equals("android.intent.action.BOOT_COMPLETED")) {

        Log.e("GEOFENCING REBOOT", "Setting boot completed marker!")
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean(Constants.BOOT_COMPLETED_RECEIVED_MARKER, true)
            .apply()


        Log.e("GEOFENCING REBOOT", "Re-registering geofences!")
        NativeGeofencePlugin.reRegisterAfterReboot(context)
        //}
    }
}
