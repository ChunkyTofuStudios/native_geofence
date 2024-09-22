package com.chunkytofustudios.native_geofence

class Constants {
    companion object {
        const val SHARED_PREFERENCES_KEY = "native_geofence_plugin_cache"
        const val CALLBACK_HANDLE_KEY = "callback_handle"
        const val CALLBACK_DISPATCHER_HANDLE_KEY = "callback_dispatch_handler"
        const val PERSISTENT_GEOFENCES_IDS = "persistent_geofences_ids"
        const val BOOT_COMPLETED_RECEIVED_MARKER = "flutter.bootcompleted_received"

        const val ACTION_SHUTDOWN = "SHUTDOWN"
    }
}
