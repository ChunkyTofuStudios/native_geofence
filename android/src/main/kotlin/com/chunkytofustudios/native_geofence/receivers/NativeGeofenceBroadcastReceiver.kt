package com.chunkytofustudios.native_geofence.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import com.chunkytofustudios.native_geofence.Constants
import com.chunkytofustudios.native_geofence.NativeGeofenceBackgroundWorker
import com.chunkytofustudios.native_geofence.generated.GeofenceCallbackParamsWire
import com.chunkytofustudios.native_geofence.model.GeofenceCallbackParamsStorage
import com.chunkytofustudios.native_geofence.util.ActiveGeofenceWires
import com.chunkytofustudios.native_geofence.util.GeofenceEvents
import com.chunkytofustudios.native_geofence.util.LocationWires
import com.google.android.gms.location.GeofencingEvent
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class NativeGeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NativeGeofenceBroadcastReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Geofence broadcast received.")

        val geofenceCallbackParams = getGeofenceCallbackParams(intent) ?: return

        val jsonData =
            Json.encodeToString(GeofenceCallbackParamsStorage.fromWire(geofenceCallbackParams))
        val workRequest = OneTimeWorkRequestBuilder<NativeGeofenceBackgroundWorker>()
            .setInputData(Data.Builder().putString(Constants.WORKER_PAYLOAD_KEY, jsonData).build())
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()

        val workManager = WorkManager.getInstance(context)
        val work = workManager.beginUniqueWork(
            Constants.GEOFENCE_CALLBACK_WORK_GROUP,
            // Process geofence callbacks sequentially.
            ExistingWorkPolicy.APPEND,
            workRequest
        )
        work.enqueue()
    }

    private fun getGeofenceCallbackParams(intent: Intent): GeofenceCallbackParamsWire? {
        val callbackHandle = intent.getLongExtra(Constants.CALLBACK_HANDLE_KEY, 0)
        if (callbackHandle == 0L) {
            Log.e(TAG, "GeofencingEvent callback handle is missing.")
            return null
        }

        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent == null) {
            Log.e(TAG, "GeofencingEvent is null.")
            return null
        }
        if (geofencingEvent.hasError()) {
            Log.e(TAG, "GeofencingEvent has error Code=${geofencingEvent.errorCode}.")
            return null
        }

        // Get the transition type.
        val geofenceEvent = GeofenceEvents.fromInt(geofencingEvent.geofenceTransition)
        if (geofenceEvent == null) {
            Log.e(
                TAG,
                "GeofencingEvent has invalid transition ID=${geofencingEvent.geofenceTransition}."
            )
            return null
        }

        // Get the geofences that were triggered. A single event can trigger
        // multiple geofences.
        val triggeringGeofences = geofencingEvent.triggeringGeofences?.map {
            ActiveGeofenceWires.fromGeofence(it)
        }
        if (triggeringGeofences.isNullOrEmpty()) {
            Log.e(TAG, "No triggering geofences found.")
            return null
        }

        val location = geofencingEvent.triggeringLocation
        if (location == null) {
            Log.w(TAG, "No triggering location found.")
        }

        return GeofenceCallbackParamsWire(
            triggeringGeofences,
            geofenceEvent,
            location?.let { LocationWires.fromLocation(it) },
            callbackHandle
        )
    }
}
