package com.chunkytofustudios.native_geofence.api

import ActiveGeofenceWire
import FlutterError
import GeofenceWire
import NativeGeofenceApi
import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.chunkytofustudios.native_geofence.Constants
import com.chunkytofustudios.native_geofence.util.GeofenceEvents
import com.chunkytofustudios.native_geofence.receivers.NativeGeofenceBroadcastReceiver
import com.chunkytofustudios.native_geofence.util.ActiveGeofenceWires
import com.chunkytofustudios.native_geofence.util.GeofenceWires
import com.chunkytofustudios.native_geofence.util.NativeGeofencePersistence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

class NativeGeofenceApiImpl(private val context: Context) : NativeGeofenceApi {
    companion object {
        @JvmStatic
        private val TAG = "NativeGeofenceApiImpl"
    }

    private val geofencingClient = LocationServices.getGeofencingClient(context)

    override fun initialize(callbackDispatcherHandle: Long) {
        context.getSharedPreferences(Constants.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
            .edit()
            .putLong(Constants.CALLBACK_DISPATCHER_HANDLE_KEY, callbackDispatcherHandle)
            .apply()
        Log.d(TAG, "Initialized NativeGeofenceApi.")
    }

    override fun createGeofence(
        geofence: GeofenceWire,
        callback: (Result<Unit>) -> Unit
    ) {
        createGeofenceHelper(geofence, true, callback)
    }

    override fun reCreateAfterReboot() {
        val geofences = NativeGeofencePersistence.getAllGeofences(context)
        for (geofence in geofences) {
            createGeofenceHelper(geofence, false, null)
        }
        Log.d(TAG, "${geofences.size} geofences re-created.")
    }

    override fun getGeofenceIds(): List<String> {
        return NativeGeofencePersistence.getAllGeofenceIds(context)
    }

    override fun getGeofences(): List<ActiveGeofenceWire> {
        val geofences = NativeGeofencePersistence.getAllGeofences(context)
        return geofences.map { ActiveGeofenceWires.fromGeofenceWire(it) }.toList()
    }

    override fun removeGeofenceById(id: String, callback: (Result<Unit>) -> Unit) {
        geofencingClient.removeGeofences(listOf(id)).run {
            addOnSuccessListener {
                NativeGeofencePersistence.removeGeofence(context, id)
                Log.d(TAG, "Removed Geofence ID=$id.")
                callback.invoke(Result.success(Unit))
            }
            addOnFailureListener {
                val existingIds = NativeGeofencePersistence.getAllGeofenceIds(context)
                val errorCode =
                    if (existingIds.contains(id)) NativeGeofenceErrorCode.PLUGIN_INTERNAL else NativeGeofenceErrorCode.GEOFENCE_NOT_FOUND
                Log.e(TAG, "Failure when removing Geofence ID=$id: $it")
                callback.invoke(
                    Result.failure(
                        FlutterError(
                            errorCode.raw.toString(),
                            it.toString()
                        )
                    )
                )
            }
        }
    }

    override fun removeAllGeofences(callback: (Result<Unit>) -> Unit) {
        geofencingClient.removeGeofences(getGeofencePendingIndent(context, null)).run {
            addOnSuccessListener {
                NativeGeofencePersistence.removeAllGeofences(context)
                Log.d(TAG, "Removed all geofences (if any).")
                callback.invoke(Result.success(Unit))
            }
            addOnFailureListener {
                Log.e(TAG, "Failed to remove all geofences: $it")
                callback.invoke(
                    Result.failure(
                        FlutterError(
                            NativeGeofenceErrorCode.PLUGIN_INTERNAL.raw.toString(),
                            it.toString()
                        )
                    )
                )
            }
        }
    }

    private fun getGeofencePendingIndent(
        context: Context,
        callbackHandle: Long?
    ): PendingIntent {
        val intent = Intent(context, NativeGeofenceBroadcastReceiver::class.java)
        if (callbackHandle != null) {
            intent.putExtra(Constants.CALLBACK_HANDLE_KEY, callbackHandle)
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
        } else {
            PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT
            )
        }
    }

    @SuppressLint("MissingPermission")
    private fun createGeofenceHelper(
        geofence: GeofenceWire,
        cache: Boolean,
        callback: ((Result<Unit>) -> Unit)?
    ) {
        // We try to create the Geofence without checking for permissions.
        // Only if creation fails we will alert the Flutter plugin of the permission issue.
        geofencingClient.addGeofences(
            GeofencingRequest.Builder().apply {
                setInitialTrigger(GeofenceEvents.createMask(geofence.androidSettings.initialTriggers))
                addGeofence(GeofenceWires.toGeofence(geofence))
            }.build(),
            getGeofencePendingIndent(context, geofence.callbackHandle)
        ).run {
            addOnSuccessListener {
                if (cache) {
                    NativeGeofencePersistence.saveGeofence(context, geofence)
                }
                Log.d(TAG, "Successfully added Geofence ID=${geofence.id}.")
                callback?.invoke(Result.success(Unit))
            }
            addOnFailureListener {
                Log.e(TAG, "Failed to add Geofence ID=${geofence.id}: $it")

                if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED) {
                    Log.e(TAG, "Lacking permission: ACCESS_FINE_LOCATION")
                    callback?.invoke(
                        Result.failure(
                            FlutterError(
                                NativeGeofenceErrorCode.MISSING_LOCATION_PERMISSION.raw.toString(),
                                "The ACCESS_FINE_LOCATION needs to be granted in order to setup geofences."
                            )
                        )
                    )
                    return@addOnFailureListener
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    if (ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.ACCESS_BACKGROUND_LOCATION
                        )
                        != PackageManager.PERMISSION_GRANTED
                    ) {
                        Log.e(TAG, "Running on API ${Build.VERSION.SDK_INT} and lacking permission: ACCESS_BACKGROUND_LOCATION")
                        callback?.invoke(
                            Result.failure(
                                FlutterError(
                                    NativeGeofenceErrorCode.MISSING_BACKGROUND_LOCATION_PERMISSION.raw.toString(),
                                    "The ACCESS_BACKGROUND_LOCATION needs to be granted in order to setup geofences.",
                                    "Running on Android API ${Build.VERSION.SDK_INT}."
                                )
                            )
                        )
                        return@addOnFailureListener
                    }
                }

                callback?.invoke(
                    Result.failure(
                        FlutterError(
                            NativeGeofenceErrorCode.PLUGIN_INTERNAL.raw.toString(),
                            it.toString()
                        )
                    )
                )
            }
        }
    }
}
