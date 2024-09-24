package com.chunkytofustudios.native_geofence.model

import AndroidGeofenceSettingsWire
import GeofenceEvent
import kotlinx.serialization.Serializable

@Serializable
class AndroidGeofenceSettingsStorage(
    private val initialTriggers: List<GeofenceEvent>,
    private val expirationDurationMillis: Long? = null,
    private val loiteringDelayMillis: Long,
    private val notificationResponsivenessMillis: Long? = null
) {
    companion object {
        fun fromWire(e: AndroidGeofenceSettingsWire): AndroidGeofenceSettingsStorage {
            return AndroidGeofenceSettingsStorage(
                e.initialTriggers,
                e.expirationDurationMillis,
                e.loiteringDelayMillis,
                e.notificationResponsivenessMillis
            )
        }
    }

    fun toWire(): AndroidGeofenceSettingsWire {
        return AndroidGeofenceSettingsWire(
            initialTriggers,
            expirationDurationMillis,
            loiteringDelayMillis,
            notificationResponsivenessMillis
        )
    }
}
