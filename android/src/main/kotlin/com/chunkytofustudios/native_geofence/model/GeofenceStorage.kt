package com.chunkytofustudios.native_geofence.model

import com.chunkytofustudios.native_geofence.generated.GeofenceEvent
import com.chunkytofustudios.native_geofence.generated.GeofenceWire
import kotlinx.serialization.Serializable

@Serializable
class GeofenceStorage(
    private val id: String,
    private val location: LocationStorage,
    private val radiusMeters: Double,
    private val triggers: List<GeofenceEvent>,
    private val iosSettings: IosGeofenceSettingsStorage,
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
                IosGeofenceSettingsStorage.fromWire(e.iosSettings),
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
            iosSettings.toWire(),
            androidSettings.toWire(),
            callbackHandle
        )
    }
}
