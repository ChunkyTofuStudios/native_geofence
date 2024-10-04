import CoreLocation
import Flutter
import OSLog

class NativeGeofenceBackgroundApiImpl: NativeGeofenceBackgroundApi {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceBackgroundApiImpl")
    
    private let binaryMessenger: FlutterBinaryMessenger
    
    private var nativeGeoFenceTriggerApi: NativeGeofenceTriggerApi? = nil
    private var eventQueue: [GeofenceCallbackParamsWire] = .init()
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
    }
    
    func triggerApiInitialized() throws {
        objc_sync_enter(self)
        
        nativeGeoFenceTriggerApi = NativeGeofenceTriggerApi(binaryMessenger: binaryMessenger)
        log.debug("NativeGeofenceTriggerApi setup complete.")
        
        objc_sync_exit(self)
        
        processQueue()
    }
    
    func promoteToForeground() throws {
        // Do nothing.
    }
    
    func demoteToBackground() throws {
        // Do nothing.
    }
    
    func geofenceTriggered(params: GeofenceCallbackParamsWire) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if nativeGeoFenceTriggerApi != nil {
            log.debug("NativeGeofenceTriggerApi is ready, sending geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] immediately.")
            callGeofenceTriggerApi(params: params)
        } else {
            log.debug("NativeGeofenceTriggerApi is not ready, queuing geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))].")
            eventQueue.append(params)
        }
    }
    
    private func processQueue() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if !eventQueue.isEmpty {
            let params = eventQueue.removeFirst()
            log.debug("Queue dispatch: sending geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))].")
            callGeofenceTriggerApi(params: params)
        }
    }
    
    private func callGeofenceTriggerApi(params: GeofenceCallbackParamsWire) {
        guard let api = nativeGeoFenceTriggerApi else {
            log.error("NativeGeofenceTriggerApi was nil, this should not happen.")
            return
        }
        log.debug("Calling Dart callback to process geofence trigger for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] event=\(String(describing: params.event)).")
        api.geofenceTriggered(params: params, completion: { result in
            if case .success = result {
                self.log.debug("Geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] processed successfully.")
            } else {
                self.log.error("Geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] failed.")
            }
            // Now that the callback is complete we can process the next item in the queue, if any.
            self.processQueue()
        })
    }
    
    private static func geofenceIds(_ params: GeofenceCallbackParamsWire) -> String {
        let ids: [String] = params.geofences.map(\.id)
        return ids.joined(separator: ",")
    }
}
