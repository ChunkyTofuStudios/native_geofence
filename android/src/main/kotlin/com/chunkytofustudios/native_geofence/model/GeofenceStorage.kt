package com.chunkytofustudios.native_geofence.model

import GeofenceEvent
import GeofenceWire
import kotlinx.serialization.Serializable

@Serializable
class GeofenceStorage(
    private val id: String,
    private val location: LocationStorage,
    private val radiusMeters: Double,
    private val triggers: List<GeofenceEvent>,
    private val androidSettings: AndroidGeofenceSettingsStorage,
    private val callbackHandle: Long
) {
    companion object {
        fun fromWire(e: GeofenceWire): GeofenceStorage {
            return GeofenceStorage(
                e.id,
                LocationStorage.fromWire(e.location),
                e.radiusMeters,
                e.triggers,
                AndroidGeofenceSettingsStorage.fromWire(e.androidSettings),
                e.callbackHandle
            )
        }
    }

    fun toWire(): GeofenceWire {
        return GeofenceWire(
            id,
            location.toWire(),
            radiusMeters,
            triggers,
            androidSettings.toWire(),
            callbackHandle
        )
    }
}
