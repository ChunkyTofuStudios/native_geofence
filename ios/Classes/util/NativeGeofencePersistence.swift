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
    
    static func setRegionInitialTriggerEnabled(id: String, enabled: Bool) {
        var mapping = getInitialTriggerMapping()
        mapping[id] = NSNumber(value: enabled)
        setInitialTriggerMapping(&mapping)
    }
    
    static func getRegionInitialTriggerEnabled(id: String) -> Bool? {
        guard let value = getInitialTriggerMapping()[id] else { return nil }
        return (value as? NSNumber)?.boolValue
    }
    
    static func removeRegionInitialTriggerEnabled(id: String) {
        var mapping = getInitialTriggerMapping()
        mapping.removeValue(forKey: id)
        setInitialTriggerMapping(&mapping)
    }
    
    private static func getInitialTriggerMapping() -> [AnyHashable: Any] {
        var dict = persistentState.dictionary(forKey: Constants.GEOFENCE_INITIAL_TRIGGER_DICT_KEY)
        if dict == nil {
            dict = [:]
            persistentState.set(dict, forKey: Constants.GEOFENCE_INITIAL_TRIGGER_DICT_KEY)
        }
        return dict!
    }
    
    private static func setInitialTriggerMapping(_ mapping: inout [AnyHashable: Any]) {
        persistentState.set(mapping, forKey: Constants.GEOFENCE_INITIAL_TRIGGER_DICT_KEY)
    }
    
    static func setRegionActivationTimestamp(id: String, timestampMillis: Int64) {
        var mapping = getActivationTimestampMapping()
        mapping[id] = NSNumber(value: timestampMillis)
        setActivationTimestampMapping(&mapping)
    }
    
    static func getRegionActivationTimestamp(id: String) -> Int64? {
        guard let value = getActivationTimestampMapping()[id] else { return nil }
        return (value as? NSNumber)?.int64Value
    }
    
    static func removeRegionActivationTimestamp(id: String) {
        var mapping = getActivationTimestampMapping()
        mapping.removeValue(forKey: id)
        setActivationTimestampMapping(&mapping)
    }
    
    private static func getActivationTimestampMapping() -> [AnyHashable: Any] {
        var dict = persistentState.dictionary(forKey: Constants.GEOFENCE_ACTIVATION_TS_DICT_KEY)
        if dict == nil {
            dict = [:]
            persistentState.set(dict, forKey: Constants.GEOFENCE_ACTIVATION_TS_DICT_KEY)
        }
        return dict!
    }
    
    private static func setActivationTimestampMapping(_ mapping: inout [AnyHashable: Any]) {
        persistentState.set(mapping, forKey: Constants.GEOFENCE_ACTIVATION_TS_DICT_KEY)
    }
    
    static func setRegionAwaitingInitialState(id: String, enabled: Bool) {
        var mapping = getAwaitingInitialStateMapping()
        mapping[id] = NSNumber(value: enabled)
        setAwaitingInitialStateMapping(&mapping)
    }
    
    static func getRegionAwaitingInitialState(id: String) -> Bool? {
        guard let value = getAwaitingInitialStateMapping()[id] else { return nil }
        return (value as? NSNumber)?.boolValue
    }
    
    static func removeRegionAwaitingInitialState(id: String) {
        var mapping = getAwaitingInitialStateMapping()
        mapping.removeValue(forKey: id)
        setAwaitingInitialStateMapping(&mapping)
    }
    
    private static func getAwaitingInitialStateMapping() -> [AnyHashable: Any] {
        var dict = persistentState.dictionary(forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_DICT_KEY)
        if dict == nil {
            dict = [:]
            persistentState.set(dict, forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_DICT_KEY)
        }
        return dict!
    }
    
    private static func setAwaitingInitialStateMapping(_ mapping: inout [AnyHashable: Any]) {
        persistentState.set(mapping, forKey: Constants.GEOFENCE_AWAITING_INITIAL_STATE_DICT_KEY)
    }
    
    static func setRegionIgnoreIfAlreadyInside(id: String, enabled: Bool) {
        var mapping = getIgnoreIfAlreadyInsideMapping()
        mapping[id] = NSNumber(value: enabled)
        setIgnoreIfAlreadyInsideMapping(&mapping)
    }
    
    static func getRegionIgnoreIfAlreadyInside(id: String) -> Bool? {
        guard let value = getIgnoreIfAlreadyInsideMapping()[id] else { return nil }
        return (value as? NSNumber)?.boolValue
    }
    
    static func removeRegionIgnoreIfAlreadyInside(id: String) {
        var mapping = getIgnoreIfAlreadyInsideMapping()
        mapping.removeValue(forKey: id)
        setIgnoreIfAlreadyInsideMapping(&mapping)
    }
    
    private static func getIgnoreIfAlreadyInsideMapping() -> [AnyHashable: Any] {
        var dict = persistentState.dictionary(forKey: Constants.GEOFENCE_IGNORE_IF_ALREADY_INSIDE_DICT_KEY)
        if dict == nil {
            dict = [:]
            persistentState.set(dict, forKey: Constants.GEOFENCE_IGNORE_IF_ALREADY_INSIDE_DICT_KEY)
        }
        return dict!
    }
    
    private static func setIgnoreIfAlreadyInsideMapping(_ mapping: inout [AnyHashable: Any]) {
        persistentState.set(mapping, forKey: Constants.GEOFENCE_IGNORE_IF_ALREADY_INSIDE_DICT_KEY)
    }
}
