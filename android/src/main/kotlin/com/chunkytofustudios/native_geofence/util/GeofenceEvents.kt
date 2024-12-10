package com.chunkytofustudios.native_geofence.util

import com.chunkytofustudios.native_geofence.generated.GeofenceEvent
import com.google.android.gms.location.Geofence

class GeofenceEvents {
    companion object {
        private fun toFlag(event: GeofenceEvent): Int {
            return when (event) {
                GeofenceEvent.ENTER -> Geofence.GEOFENCE_TRANSITION_ENTER
                GeofenceEvent.EXIT -> Geofence.GEOFENCE_TRANSITION_EXIT
                GeofenceEvent.DWELL -> Geofence.GEOFENCE_TRANSITION_DWELL
            }
        }

        fun createMask(events: List<GeofenceEvent>): Int {
            return events.fold(0) { mask, event ->
                mask or toFlag(event)
            }
        }

        fun fromMask(mask: Int): List<GeofenceEvent> {
            return GeofenceEvent.entries.filter { (mask and toFlag(it)) != 0 }
        }

        fun fromInt(id: Int): GeofenceEvent? {
            return when (id) {
                1 -> GeofenceEvent.ENTER
                2 -> GeofenceEvent.EXIT
                4 -> GeofenceEvent.DWELL
                else -> null
            }
        }
    }
}
