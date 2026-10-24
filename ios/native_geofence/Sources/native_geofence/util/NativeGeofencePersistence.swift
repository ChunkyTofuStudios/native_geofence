import Foundation

class NativeGeofencePersistence {
    private static let persistentState: UserDefaults = .standard
    
    static func setCallbackDispatcherHandle(_ handle: Int64) {
        persistentState.set(
            NSNumber(value: handle),
            forKey: Constants.CALLBACK_DISPATCHER_KEY
        )
    }
    
    static func getCallbackDispatcherHandle() -> Int64? {
        guard let handle = persistentState.value(forKey: Constants.CALLBACK_DISPATCHER_KEY) else { return nil }
        return (handle as? NSNumber)?.int64Value
    }
    
    static func setRegionCallbackHandle(id: String, handle: Int64) {
        var mapping = getRegionCallbackMapping()
        mapping[id] = NSNumber(value: handle)
        setRegionCallbackMapping(&mapping)
    }
    
    static func getRegionCallbackHandle(id: String) -> Int64? {
        guard let handle = getRegionCallbackMapping()[id] else { return nil }
        return (handle as? NSNumber)?.int64Value
    }
    
    static func removeRegionCallbackHandle(id: String) {
        var mapping = getRegionCallbackMapping()
        mapping.removeValue(forKey: id)
        setRegionCallbackMapping(&mapping)
    }
    
    private static func getRegionCallbackMapping() -> [AnyHashable: Any] {
        var callbackDict = persistentState.dictionary(forKey: Constants.GEOFENCE_CALLBACK_DICT_KEY)
        if callbackDict == nil {
            callbackDict = [:]
            persistentState.set(callbackDict, forKey: Constants.GEOFENCE_CALLBACK_DICT_KEY)
        }
        return callbackDict!
    }
    
    private static func setRegionCallbackMapping(_ mapping: inout [AnyHashable: Any]) {
        persistentState.set(mapping, forKey: Constants.GEOFENCE_CALLBACK_DICT_KEY)
    }
    
    static func setRegionAwaitingInitialState(id: String) {
        var mapping = getRegionAwaitingInitialStateMapping()
        mapping[id] = NSNumber(value: Date().timeIntervalSince1970)
        persistentState.set(mapping, forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_DICT_KEY)
    }
    
    /// Returns since when the geofence has been awaiting its initial state, or nil if it isn't.
    static func getRegionAwaitingInitialStateSince(id: String) -> Date? {
        guard let timestamp = getRegionAwaitingInitialStateMapping()[id] as? NSNumber else { return nil }
        return Date(timeIntervalSince1970: timestamp.doubleValue)
    }
    
    static func removeRegionAwaitingInitialState(id: String) {
        var mapping = getRegionAwaitingInitialStateMapping()
        guard mapping.removeValue(forKey: id) != nil else { return }
        persistentState.set(mapping, forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_DICT_KEY)
    }
    
    private static func getRegionAwaitingInitialStateMapping() -> [String: Any] {
        return persistentState.dictionary(forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_DICT_KEY) ?? [:]
    }
}
