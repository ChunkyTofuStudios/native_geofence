package com.chunkytofustudios.native_geofence.model

import com.chunkytofustudios.native_geofence.generated.GeofenceCallbackParamsWire
import com.chunkytofustudios.native_geofence.generated.GeofenceEvent
import kotlinx.serialization.Serializable

@Serializable
class GeofenceCallbackParamsStorage(
    private val geofences: List<ActiveGeofenceStorage>,
    private val event: GeofenceEvent,
    private val location: LocationStorage? = null,
    private val callbackHandle: Long
) {
    companion object {
        fun fromWire(e: GeofenceCallbackParamsWire): GeofenceCallbackParamsStorage {
            return GeofenceCallbackParamsStorage(
                e.geofences.map { ActiveGeofenceStorage.fromWire(it) }.toList(),
                e.event,
                e.location?.let { LocationStorage.fromWire(it) },
                e.callbackHandle,
            )
        }
    }

    fun toWire(): GeofenceCallbackParamsWire {
        return GeofenceCallbackParamsWire(
            geofences.map { it.toWire() }.toList(),
            event,
            location?.toWire(),
            callbackHandle,
        )
    }
}
