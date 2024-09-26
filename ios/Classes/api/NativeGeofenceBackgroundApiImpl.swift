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
            nativeGeoFenceTriggerApi?.geofenceTriggered(params: params, completion: { _ in })
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
        
        if let nativeGeoFenceTriggerApi {
            log.debug("NativeGeofenceTriggerApi is ready, sending geofence trigger event for \(params.geofences.first?.id ?? "N/A") immediately.")
            nativeGeoFenceTriggerApi.geofenceTriggered(params: params, completion: { _ in })
        } else {
            log.debug("NativeGeofenceTriggerApi is not ready, queuing geofence trigger event \(params.geofences.first?.id ?? "N/A").")
            eventQueue.append(params)
        }
    }
}
