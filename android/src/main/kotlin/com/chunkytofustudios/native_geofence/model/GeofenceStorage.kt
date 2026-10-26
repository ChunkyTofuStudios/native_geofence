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
    private val callbackHandle: Long,
    // When the geofence expires, in milliseconds since the epoch. Null if it never expires, or if it
    // was saved by a version of the plugin before 1.6.0.
    private val expiresAtMillis: Long? = null
) {
    companion object {
        fun fromWire(e: GeofenceWire, createdAtMillis: Long): GeofenceStorage {
            return GeofenceStorage(
                e.id,
                LocationStorage.fromWire(e.location),
                e.radiusMeters,
                e.triggers,
                IosGeofenceSettingsStorage.fromWire(e.iosSettings),
                AndroidGeofenceSettingsStorage.fromWire(e.androidSettings),
                e.callbackHandle,
                e.androidSettings.expirationDurationMillis?.let { createdAtMillis + it }
            )
        }
    }

    fun isExpired(nowMillis: Long): Boolean {
        return expiresAtMillis != null && nowMillis >= expiresAtMillis
    }

    // If nowMillis is set, the expiration is the time the geofence has left at that time, instead of
    // the duration it was created with.
    fun toWire(nowMillis: Long? = null): GeofenceWire {
        val wire = GeofenceWire(
            id,
            location.toWire(),
            radiusMeters,
            triggers,
            iosSettings.toWire(),
            androidSettings.toWire(),
            callbackHandle
        )
        if (nowMillis == null || expiresAtMillis == null) {
            return wire
        }
        return wire.copy(
            androidSettings = wire.androidSettings.copy(expirationDurationMillis = expiresAtMillis - nowMillis)
        )
    }
}
