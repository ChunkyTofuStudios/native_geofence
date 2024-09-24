package com.chunkytofustudios.native_geofence.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.chunkytofustudios.native_geofence.Constants
import com.chunkytofustudios.native_geofence.api.NativeGeofenceApiImpl

class NativeGeofenceRebootBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "NativeGeofenceReboot"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Boot completed broadcast received.")
        Log.i(TAG, "Re-registering geofences!")
        NativeGeofenceApiImpl(context).reCreateAfterReboot()
    }
}
