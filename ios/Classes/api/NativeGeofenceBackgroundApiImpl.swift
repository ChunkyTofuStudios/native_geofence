import CoreLocation
import Flutter
import OSLog

class NativeGeofenceBackgroundApiImpl: NativeGeofenceBackgroundApi {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceBackgroundApiImpl")
    private let binaryMessenger: FlutterBinaryMessenger
    private var nativeGeoFenceTriggerApi: NativeGeofenceTriggerApi?
    private var cleanup: (() -> Void)?
    private var geofenceId: String?
    // A timeout work item to ensure cleanup happens even if the Dart side never responds.
    private var timeoutWorkItem: DispatchWorkItem?

    /// Timeout (in seconds) after which the callback is force-cleaned up if no response is
    /// received from the Dart isolate. Adjust if needed.
    private static let callbackTimeout: TimeInterval = 10
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
    }
    
    func geofenceTriggered(params: GeofenceCallbackParamsWire, cleanup: @escaping () -> Void) {
        self.cleanup = cleanup
        let geofenceId = params.geofences.first?.id ?? ""
        self.geofenceId = geofenceId
        
        GeofenceCallbackHandlerManager.shared.startTracking(handler: self, forGeofenceId: geofenceId)
        
        if nativeGeoFenceTriggerApi == nil {
            nativeGeoFenceTriggerApi = NativeGeofenceTriggerApi(binaryMessenger: binaryMessenger)
        }

        // Schedule a fallback cleanup in case the Dart side never replies.
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.log.error("Geofence trigger for ID=[\(self.geofenceId ?? "")] timed out after \(Self.callbackTimeout)s. Forcing cleanup.")
            self.cleanup?()
            if let geofenceId = self.geofenceId {
                GeofenceCallbackHandlerManager.shared.stopTracking(forGeofenceId: geofenceId)
            }
        }
        self.timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.callbackTimeout, execute: workItem)

        callGeofenceTriggerApi(params: params)
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

            // Cancel timeout since we received a response.
            self.timeoutWorkItem?.cancel()
            self.timeoutWorkItem = nil
            
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
