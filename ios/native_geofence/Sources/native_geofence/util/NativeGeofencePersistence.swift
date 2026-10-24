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
    
    static func addRegionAwaitingInitialState(id: String) {
        var ids = getRegionsAwaitingInitialState()
        guard !ids.contains(id) else { return }
        ids.append(id)
        persistentState.set(ids, forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_LIST_KEY)
    }
    
    static func isRegionAwaitingInitialState(id: String) -> Bool {
        return getRegionsAwaitingInitialState().contains(id)
    }
    
    static func removeRegionAwaitingInitialState(id: String) {
        var ids = getRegionsAwaitingInitialState()
        guard let index = ids.firstIndex(of: id) else { return }
        ids.remove(at: index)
        persistentState.set(ids, forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_LIST_KEY)
    }
    
    private static func getRegionsAwaitingInitialState() -> [String] {
        return persistentState.stringArray(forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_LIST_KEY) ?? []
    }
}
