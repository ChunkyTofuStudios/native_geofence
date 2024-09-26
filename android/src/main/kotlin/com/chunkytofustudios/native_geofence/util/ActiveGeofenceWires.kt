package com.chunkytofustudios.native_geofence.util

import ActiveGeofenceWire
import AndroidGeofenceSettingsWire
import GeofenceWire
import LocationWire
import com.google.android.gms.location.Geofence

class ActiveGeofenceWires {
    companion object {
        fun fromGeofence(e: Geofence): ActiveGeofenceWire {
            return ActiveGeofenceWire(
                e.requestId,
                LocationWire(e.latitude, e.longitude),
                e.radius.toDouble(),
                GeofenceEvents.fromMask(e.transitionTypes),
                AndroidGeofenceSettingsWire(
                    emptyList(),
                    e.expirationTime,
                    e.loiteringDelay.toLong(),
                    e.notificationResponsiveness.toLong()
                )
            )
        }

        fun fromGeofenceWire(e: GeofenceWire): ActiveGeofenceWire {
            return ActiveGeofenceWire(
                e.id,
                e.location,
                e.radiusMeters,
                e.triggers,
                e.androidSettings
            )
        }
    }
}
