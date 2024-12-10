package com.chunkytofustudios.native_geofence.util

import com.chunkytofustudios.native_geofence.generated.GeofenceWire
import com.google.android.gms.location.Geofence

class GeofenceWires {
    companion object {
        fun toGeofence(e: GeofenceWire): Geofence {
            val geofenceBuilder = Geofence.Builder()
                .setRequestId(e.id)
                .setCircularRegion(
                    e.location.latitude,
                    e.location.longitude,
                    e.radiusMeters.toFloat()
                )
                .setTransitionTypes(GeofenceEvents.createMask(e.triggers))
                .setLoiteringDelay(e.androidSettings.loiteringDelayMillis.toInt())
            if (e.androidSettings.expirationDurationMillis != null) {
                geofenceBuilder.setExpirationDuration(e.androidSettings.expirationDurationMillis)
            }
            if (e.androidSettings.notificationResponsivenessMillis != null) {
                geofenceBuilder.setNotificationResponsiveness(e.androidSettings.notificationResponsivenessMillis.toInt())
            }
            return geofenceBuilder.build()
        }
    }
}
