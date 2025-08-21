import CoreLocation
import Flutter
import OSLog

class NativeGeofenceBackgroundApiImpl: NativeGeofenceBackgroundApi {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceBackgroundApiImpl")
    private let binaryMessenger: FlutterBinaryMessenger
    private var nativeGeoFenceTriggerApi: NativeGeofenceTriggerApi?
    private var cleanup: (() -> Void)?
    private var geofenceId: String?
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
    }
    
    func geofenceTriggered(params: GeofenceCallbackParamsWire, cleanup: @escaping () -> Void) {
        objc_sync_enter(self)
        self.cleanup = cleanup
        let geofenceId = params.geofences.first?.id ?? ""
        self.geofenceId = geofenceId
        
        GeofenceCallbackHandlerManager.shared.startTracking(handler: self, forGeofenceId: geofenceId)
        
        if nativeGeoFenceTriggerApi == nil {
            nativeGeoFenceTriggerApi = NativeGeofenceTriggerApi(binaryMessenger: binaryMessenger)
        }
        callGeofenceTriggerApi(params: params)  
        objc_sync_exit(self) 


    }
    
    func triggerApiInitialized() throws {
        // This is not used on iOS and can be a no-op.
    }
    
    func promoteToForeground() throws {
        log.info("promoteToForeground called. iOS does not distinguish between foreground and background, nothing to do here.")
    }
    
    func demoteToBackground() throws {
        log.info("demoteToBackground called. iOS does not distinguish between foreground and background, nothing to do here.")
    }

    private func callGeofenceTriggerApi(params: GeofenceCallbackParamsWire) {
        guard let api = nativeGeoFenceTriggerApi else {
            log.error("NativeGeofenceTriggerApi was nil, this should not happen.")
            return
        }
        
        log.debug("Calling Dart callback to process geofence trigger for IDs=[\(params.geofences.first?.id ?? "")] event=\(String(describing: params.event)).")
        
        api.geofenceTriggered(params: params) { [weak self] result in
            guard let self = self else { return }
            
            if case .success = result {
                self.log.debug("Geofence trigger event for ID=[\(self.geofenceId ?? "")] processed successfully.")
            } else {
                self.log.error("Geofence trigger event for ID=[\(self.geofenceId ?? "")] failed.")
            }
            
            self.cleanup?()
            
            if let geofenceId = self.geofenceId {
                GeofenceCallbackHandlerManager.shared.stopTracking(forGeofenceId: geofenceId)
            }
        }
    }
}

/// Tracks active background handlers so we can manage their lifecycle safely.
final class GeofenceCallbackHandlerManager {
    static let shared = GeofenceCallbackHandlerManager()
    private let lock = NSLock()
    private var handlers: [String: NativeGeofenceBackgroundApiImpl] = [:]

    private init() {}

    func startTracking(handler: NativeGeofenceBackgroundApiImpl, forGeofenceId id: String) {
        lock.lock(); defer { lock.unlock() }
        handlers[id] = handler
    }

    func stopTracking(forGeofenceId id: String) {
        lock.lock(); defer { lock.unlock() }
        handlers.removeValue(forKey: id)
    }
}
