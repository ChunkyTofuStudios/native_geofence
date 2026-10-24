package com.chunkytofustudios.native_geofence.model

import com.chunkytofustudios.native_geofence.generated.LocationWire
import kotlinx.serialization.Serializable

@Serializable
class LocationStorage(
    private val latitude: Double,
    private val longitude: Double
) {
    companion object {
        fun fromWire(e: LocationWire): LocationStorage {
            return LocationStorage(e.latitude, e.longitude)
        }
    }

    fun toWire(): LocationWire {
        return LocationWire(
            latitude,
            longitude,
        )
    }
}
