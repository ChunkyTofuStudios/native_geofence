package com.chunkytofustudios.native_geofence.util

import LocationWire
import android.location.Location

class LocationWires {
    companion object {
        fun fromLocation(e: Location): LocationWire {
            return LocationWire(
                e.latitude,
                e.longitude
            )
        }
    }
}
