package com.chunkytofustudios.native_geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.view.FlutterMain


class NativeGeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NativeGeofenceBroadcastReceiver"
    }
    override fun onReceive(context: Context, intent: Intent) {
        FlutterMain.startInitialization(context)
        FlutterMain.ensureInitializationComplete(context, null)
        NativeGeofenceService.enqueueWork(context, intent)
    }
}