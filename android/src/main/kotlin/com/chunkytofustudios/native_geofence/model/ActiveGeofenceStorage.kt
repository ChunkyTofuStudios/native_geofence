package com.chunkytofustudios.native_geofence.model

import com.chunkytofustudios.native_geofence.generated.ActiveGeofenceWire
import com.chunkytofustudios.native_geofence.generated.GeofenceEvent
import kotlinx.serialization.Serializable

@Serializable
class ActiveGeofenceStorage(
    private val id: String,
    private val location: LocationStorage,
    private val radiusMeters: Double,
    private val triggers: List<GeofenceEvent>,
    private val androidSettings: AndroidGeofenceSettingsStorage?,
) {
    companion object {
        fun fromWire(e: ActiveGeofenceWire): ActiveGeofenceStorage {
            return ActiveGeofenceStorage(
                e.id,
                LocationStorage.fromWire(e.location),
                e.radiusMeters,
                e.triggers,
                e.androidSettings?.let { AndroidGeofenceSettingsStorage.fromWire(it) },
            )
        }
    }

    fun toWire(): ActiveGeofenceWire {
        return ActiveGeofenceWire(
            id,
            location.toWire(),
            radiusMeters,
            triggers,
            androidSettings?.toWire(),
        )
    }
}
