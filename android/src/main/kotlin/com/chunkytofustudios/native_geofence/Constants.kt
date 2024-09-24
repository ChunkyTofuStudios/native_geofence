package com.chunkytofustudios.native_geofence

class Constants {
    companion object {
        private const val PACKAGE_NAME = "com.chunkytofustudios.native_geofence"

        const val SHARED_PREFERENCES_KEY = "native_geofence_plugin_cache"
        const val PERSISTENT_GEOFENCES_IDS_KEY = "persistent_geofences_ids"
        const val PERSISTENT_GEOFENCE_KEY_PREFIX = "persistent_geofence/"

        const val CALLBACK_HANDLE_KEY = "$PACKAGE_NAME.callback_handle"
        const val CALLBACK_DISPATCHER_HANDLE_KEY = "callback_dispatch_handler"

        const val ACTION_SHUTDOWN = "SHUTDOWN"

        const val WORKER_PAYLOAD_KEY = "$PACKAGE_NAME.worker_payload"
    }
}
