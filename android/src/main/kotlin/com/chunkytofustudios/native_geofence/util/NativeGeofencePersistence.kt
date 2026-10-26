package com.chunkytofustudios.native_geofence.util

import android.content.Context
import android.util.Log
import com.chunkytofustudios.native_geofence.Constants
import com.chunkytofustudios.native_geofence.generated.GeofenceWire
import com.chunkytofustudios.native_geofence.model.GeofenceStorage
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString

class NativeGeofencePersistence {
    companion object {
        @JvmStatic
        private val TAG = "NativeGeofencePersistence"

        @JvmStatic
        private val sharedPreferencesLock = Object()

        @JvmStatic
        private fun getGeofenceKey(id: String): String {
            return Constants.PERSISTENT_GEOFENCE_KEY_PREFIX + id
        }

        @JvmStatic
        fun saveGeofence(context: Context, geofence: GeofenceWire) {
            synchronized(sharedPreferencesLock) {
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                val jsonData =
                    Json.encodeToString(GeofenceStorage.fromWire(geofence, System.currentTimeMillis()))
                var persistentGeofences =
                    p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS_KEY, null)
                persistentGeofences = if (persistentGeofences == null) {
                    HashSet<String>()
                } else {
                    HashSet<String>(persistentGeofences)
                }
                persistentGeofences.add(geofence.id)
                context.getSharedPreferences(Constants.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                    .edit()
                    .putStringSet(Constants.PERSISTENT_GEOFENCES_IDS_KEY, persistentGeofences)
                    .putString(getGeofenceKey(geofence.id), jsonData)
                    .apply()
                Log.d(TAG, "Saved Geofence ID=${geofence.id} to storage.")
            }
        }

        @JvmStatic
        fun getAllGeofenceIds(context: Context): List<String> {
            return getAllGeofences(context).map { it.id }
        }

        // Expired geofences are removed from storage, since Android has removed them as well.
        // With remainingExpiration, each geofence's expiration is the time it has left instead of the
        // duration it was created with, for re-creating it.
        @JvmStatic
        fun getAllGeofences(context: Context, remainingExpiration: Boolean = false): List<GeofenceWire> {
            synchronized(sharedPreferencesLock) {
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                val persistentGeofences =
                    p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS_KEY, null)
                        ?: return emptyList()

                val nowMillis = System.currentTimeMillis()
                val result = mutableListOf<GeofenceWire>()
                val expiredIds = mutableListOf<String>()
                for (id in persistentGeofences) {
                    val jsonData = p.getString(getGeofenceKey(id), null)
                    if (jsonData == null) {
                        Log.e(TAG, "No data found for Geofence ID=${id} in storage.")
                        continue
                    }
                    try {
                        val geofenceStorage = Json.decodeFromString<GeofenceStorage>(jsonData)
                        if (geofenceStorage.isExpired(nowMillis)) {
                            Log.d(TAG, "Geofence ID=${id} has expired.")
                            expiredIds.add(id)
                            continue
                        }
                        result.add(geofenceStorage.toWire(if (remainingExpiration) nowMillis else null))
                    } catch (e: Exception) {
                        Log.e(
                            TAG,
                            "Failed to parse Geofence ID=${id} from storage. Data=${jsonData}"
                        )
                    }
                }
                for (id in expiredIds) {
                    removeGeofence(context, id)
                }
                Log.d(TAG, "Retrieved ${result.size} Geofences from storage.")
                return result
            }
        }

        @JvmStatic
        fun removeGeofence(context: Context, geofenceId: String) {
            synchronized(sharedPreferencesLock) {
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                var persistentGeofences =
                    p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS_KEY, null)
                persistentGeofences = if (persistentGeofences == null) {
                    HashSet<String>()
                } else {
                    HashSet<String>(persistentGeofences)
                }
                persistentGeofences.remove(geofenceId)
                context.getSharedPreferences(Constants.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                    .edit()
                    .putStringSet(Constants.PERSISTENT_GEOFENCES_IDS_KEY, persistentGeofences)
                    .remove(getGeofenceKey(geofenceId))
                    .apply()
                Log.d(TAG, "Removed Geofence ID=${geofenceId} from storage.")
            }
        }

        @JvmStatic
        fun removeAllGeofences(context: Context) {
            synchronized(sharedPreferencesLock) {
                val p = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                var persistentGeofences =
                    p.getStringSet(Constants.PERSISTENT_GEOFENCES_IDS_KEY, null)
                persistentGeofences = if (persistentGeofences == null) {
                    HashSet<String>()
                } else {
                    HashSet<String>(persistentGeofences)
                }
                val editor = context.getSharedPreferences(
                    Constants.SHARED_PREFERENCES_KEY,
                    Context.MODE_PRIVATE
                )
                    .edit()
                    .remove(Constants.PERSISTENT_GEOFENCES_IDS_KEY)
                for (id in persistentGeofences) {
                    editor.remove(getGeofenceKey(id))
                }
                editor.apply()
                Log.d(TAG, "Removed ${persistentGeofences.size} Geofences from storage.")
            }
        }
    }
}
