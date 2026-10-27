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
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED ->
                Log.i(TAG, "Boot completed broadcast received. Re-creating geofences!")
            // Play services removes the app's geofences when the app is updated.
            Intent.ACTION_MY_PACKAGE_REPLACED ->
                Log.i(TAG, "App updated broadcast received. Re-creating geofences!")
            else -> {
                Log.w(TAG, "Ignoring unexpected broadcast: ${intent.action}")
                return
            }
        }
        NativeGeofenceApiImpl(context).reCreateAfterReboot()
    }
}
