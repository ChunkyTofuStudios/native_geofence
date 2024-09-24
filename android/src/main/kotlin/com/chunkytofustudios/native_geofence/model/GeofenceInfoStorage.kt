package com.chunkytofustudios.native_geofence.model

import GeofenceEvent
import GeofenceInfoWire
import kotlinx.serialization.Serializable

@Serializable
class GeofenceInfoStorage(
    private val id: String,
    private val location: LocationStorage,
    private val radiusMeters: Double,
    private val triggers: List<GeofenceEvent>,
    private val androidSettings: AndroidGeofenceSettingsStorage,
) {
    companion object {
        fun fromWire(e: GeofenceInfoWire): GeofenceInfoStorage {
            return GeofenceInfoStorage(
                e.id,
                LocationStorage.fromWire(e.location),
                e.radiusMeters,
                e.triggers,
                AndroidGeofenceSettingsStorage.fromWire(e.androidSettings),
            )
        }
    }

    fun toWire(): GeofenceInfoWire {
        return GeofenceInfoWire(
            id,
            location.toWire(),
            radiusMeters,
            triggers,
            androidSettings.toWire(),
        )
    }
}
