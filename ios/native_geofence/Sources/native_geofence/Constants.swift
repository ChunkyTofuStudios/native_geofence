class Constants {
    static let PACKAGE_NAME = "com.chunkytofustudios.native_geofence"
    
    static let HEADLESS_FLUTTER_ENGINE_NAME = "NativeGeofenceIsolate"
    // If a geofence callback has not completed after this long, the headless Flutter engine is replaced once the next
    // geofence event arrives. For reference, iOS only gives apps ~10-30 seconds of background time per geofence event.
    static let HEADLESS_FLUTTER_ENGINE_TIMEOUT_SECONDS: Double = 60
    // Time given to a callback that may have just resumed from app suspension before its engine is replaced.
    static let HEADLESS_FLUTTER_ENGINE_GRACE_SECONDS: Double = 5
    
    static let CALLBACK_DISPATCHER_KEY = "callback_dispatcher_handler"
    static let GEOFENCE_CALLBACK_DICT_KEY = "geofence_callback_dict"
    static let GEOFENCE_AWAITING_INITIAL_STATE_DICT_KEY = "geofence_awaiting_initial_state_dict"
}
