import CoreLocation
import Flutter
import OSLog

class NativeGeofenceBackgroundApiImpl: NativeGeofenceBackgroundApi {
    private let log = Logger(subsystem: "com.chunkytofustudios.native_geofence", category: "NativeGeofenceBackgroundApiImpl")
    
    private let binaryMessenger: FlutterBinaryMessenger
    
    private var nativeGeoFenceTriggerApi: NativeGeofenceTriggerApi? = nil
    private var eventQueue: [GeofenceCallbackParams] = .init()
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
    }
    
    func triggerApiInitialized() throws {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        nativeGeoFenceTriggerApi = NativeGeofenceTriggerApi(binaryMessenger: binaryMessenger)
        log.info("NativeGeofenceTriggerApi setup complete.")
        
        while !eventQueue.isEmpty {
            let params = eventQueue.removeFirst()
            log.debug("Queue dispatch: sending geofence trigger event for \(params.geofences.first?.id ?? "N/A").")
            callGeofenceTriggerApi(params: params)
        }
    }
    
    func promoteToForeground() throws {
        // Do nothing.
    }
    
    func demoteToBackground() throws {
        // Do nothing.
    }
    
    func geofenceTriggered(params: GeofenceCallbackParams) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if nativeGeoFenceTriggerApi != nil {
            log.debug("NativeGeofenceTriggerApi is ready, sending geofence trigger event for \(params.geofences.first?.id ?? "N/A") immediately.")
            callGeofenceTriggerApi(params: params)
        } else {
            log.debug("NativeGeofenceTriggerApi is not ready, queuing geofence trigger event \(params.geofences.first?.id ?? "N/A").")
            eventQueue.append(params)
        }
    }
    
    private func callGeofenceTriggerApi(params: GeofenceCallbackParams) {
        guard let api = nativeGeoFenceTriggerApi else {
            log.error("NativeGeofenceTriggerApi was nil.")
            return
        }
        api.geofenceTriggered(params: params, completion: { result in
            if case .success = result {
                self.log.debug("Geofence trigger event for \(params.geofences.first?.id ?? "N/A") sent successfully.")
            } else {
                self.log.error("Geofence trigger event for \(params.geofences.first?.id ?? "N/A") failed to send.")
            }
        })
    }
}
