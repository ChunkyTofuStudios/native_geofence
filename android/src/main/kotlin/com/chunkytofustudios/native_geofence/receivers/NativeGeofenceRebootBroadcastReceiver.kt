package com.chunkytofustudios.native_geofence.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.chunkytofustudios.native_geofence.api.NativeGeofenceApiImpl

class NativeGeofenceRebootBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "NativeGeofenceRebootBroadcastReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "Boot completed broadcast received. Re-creating geofences!")
        NativeGeofenceApiImpl(context).reCreateAfterReboot()
    }
}
