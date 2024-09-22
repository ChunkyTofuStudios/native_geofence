package com.chunkytofustudios.native_geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.loader.FlutterLoader


class NativeGeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NativeGeofenceBroadcastReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val flutterLoader = FlutterLoader()
        flutterLoader.startInitialization(context)
        flutterLoader.ensureInitializationComplete(context, null)
        Log.d(TAG, "Flutter initialized.")
        NativeGeofenceService.enqueueWork(context, intent)
    }
}