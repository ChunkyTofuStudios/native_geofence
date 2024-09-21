package com.chunkytofustudios.native_geofence;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

class NativeGeofenceRebootBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        //if (intent.getAction().equals("android.intent.action.BOOT_COMPLETED")) {

        Log.e("GEOFENCING REBOOT", "Setting boot completed marker!")
        // Write a bootreceivedmarker to sharedprefs
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean(NativeGeofencePlugin.BOOTCOMPLETED_RECEIVED_MARKER, true)
            .apply()


        Log.e("GEOFENCING REBOOT", "Reregistering geofences!")
            NativeGeofencePlugin.reRegisterAfterReboot(context)
        //}
    }
}
