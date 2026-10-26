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
import com.chunkytofustudios.native_geofence.util.NativeGeofencePersistence
import com.google.android.gms.location.GeofencingEvent
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class NativeGeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NativeGeofenceBroadcastReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Geofence broadcast received.")

        // Geofences created with different callbacks can trigger together, each callback is run
        // with its own geofences.
        for (geofenceCallbackParams in getGeofenceCallbackParams(context, intent)) {
            val jsonData =
                Json.encodeToString(GeofenceCallbackParamsStorage.fromWire(geofenceCallbackParams))
            val workRequest = OneTimeWorkRequestBuilder<NativeGeofenceBackgroundWorker>()
                .setInputData(Data.Builder().putString(Constants.WORKER_PAYLOAD_KEY, jsonData).build())
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                .build()

            val workManager = WorkManager.getInstance(context)
            val work = workManager.beginUniqueWork(
                Constants.GEOFENCE_CALLBACK_WORK_GROUP,
                // Process geofence callbacks sequentially. Unlike APPEND, APPEND_OR_REPLACE starts a new
                // chain after a failed callback, instead of failing every callback appended to it.
                ExistingWorkPolicy.APPEND_OR_REPLACE,
                workRequest
            )
            work.enqueue()
        }
    }

    private fun getGeofenceCallbackParams(
        context: Context,
        intent: Intent
    ): List<GeofenceCallbackParamsWire> {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent == null) {
            Log.e(TAG, "GeofencingEvent is null.")
            return emptyList()
        }
        if (geofencingEvent.hasError()) {
            Log.e(TAG, "GeofencingEvent has error Code=${geofencingEvent.errorCode}.")
            return emptyList()
        }

        // Get the transition type.
        val geofenceEvent = GeofenceEvents.fromInt(geofencingEvent.geofenceTransition)
        if (geofenceEvent == null) {
            Log.e(
                TAG,
                "GeofencingEvent has invalid transition ID=${geofencingEvent.geofenceTransition}."
            )
            return emptyList()
        }

        // Get the geofences that were triggered. A single event can trigger
        // multiple geofences.
        val triggeringGeofences = geofencingEvent.triggeringGeofences
        if (triggeringGeofences.isNullOrEmpty()) {
            Log.e(TAG, "No triggering geofences found.")
            return emptyList()
        }

        val location = geofencingEvent.triggeringLocation
        if (location == null) {
            Log.w(TAG, "No triggering location found.")
        }

        // All geofences share one PendingIntent, so its callback handle extra is the one of the most
        // recently created geofence. Use the callback each geofence was created with instead, and
        // fall back to the extra for a geofence whose initial trigger arrives before it is saved.
        val callbackHandles = NativeGeofencePersistence.getAllGeofences(context)
            .associate { it.id to it.callbackHandle }
        val intentCallbackHandle = intent.getLongExtra(Constants.CALLBACK_HANDLE_KEY, 0)

        return triggeringGeofences
            .groupBy { callbackHandles[it.requestId] ?: intentCallbackHandle }
            .mapNotNull { (callbackHandle, geofences) ->
                if (callbackHandle == 0L) {
                    Log.e(TAG, "Callback handle is missing for Geofence IDs=${geofences.map { it.requestId }}.")
                    return@mapNotNull null
                }
                GeofenceCallbackParamsWire(
                    geofences.map { ActiveGeofenceWires.fromGeofence(it) },
                    geofenceEvent,
                    location?.let { LocationWires.fromLocation(it) },
                    callbackHandle,
                    location?.time
                )
            }
    }
}
