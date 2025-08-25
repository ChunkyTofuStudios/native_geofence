import CoreLocation
import Flutter
import OSLog

class NativeGeofenceBackgroundApiImpl: NativeGeofenceBackgroundApi {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceBackgroundApiImpl")
    private let binaryMessenger: FlutterBinaryMessenger
    private var nativeGeoFenceTriggerApi: NativeGeofenceTriggerApi?
    private var cleanup: (() -> Void)?
    private var geofenceId: String?
    private var onProcessingComplete: (() -> Void)?
    private var onRetry: ((GeofenceCallbackParamsWire) -> Void)?
    private let watchdogQueue = DispatchQueue(label: "\(Constants.PACKAGE_NAME).watchdog")
    private var watchdogTimer: DispatchSourceTimer?
    private var lastParams: GeofenceCallbackParamsWire?
    private var retryCount: Int = 0
    
    init(binaryMessenger: FlutterBinaryMessenger, onProcessingComplete: (() -> Void)? = nil, onRetry: ((GeofenceCallbackParamsWire) -> Void)? = nil) {
        self.binaryMessenger = binaryMessenger
        self.onProcessingComplete = onProcessingComplete
        self.onRetry = onRetry
    }
    
    func geofenceTriggered(params: GeofenceCallbackParamsWire, cleanup: @escaping () -> Void) {
        objc_sync_enter(self)
        self.cleanup = cleanup
        let geofenceId = params.geofences.first?.id ?? ""
        self.geofenceId = geofenceId
        self.lastParams = params
        self.retryCount = 0
        
        GeofenceCallbackHandlerManager.shared.startTracking(handler: self, forGeofenceId: geofenceId)
        
        if nativeGeoFenceTriggerApi == nil {
            nativeGeoFenceTriggerApi = NativeGeofenceTriggerApi(binaryMessenger: binaryMessenger)
        }
        callGeofenceTriggerApi(params: params)
        scheduleWatchdog(seconds: 10.0)
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
            // Do not cleanup here; Dart signals completion explicitly via processingComplete().
        }
    }

    func processingComplete() throws {
        log.debug("processingComplete received from Dart.")
        cancelWatchdog()
        // Perform cleanup and release queue slot.
        cleanup?()
        if let geofenceId = geofenceId {
            GeofenceCallbackHandlerManager.shared.stopTracking(forGeofenceId: geofenceId)
        }
        onProcessingComplete?()
        // Reset to avoid accidental double-calls.
        cleanup = nil
        geofenceId = nil
        onProcessingComplete = nil
        lastParams = nil
        retryCount = 0
    }

    private func scheduleWatchdog(seconds: TimeInterval) {
        cancelWatchdog()
        let timer = DispatchSource.makeTimerSource(queue: watchdogQueue)
        timer.schedule(deadline: .now() + seconds, repeating: seconds)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let paramsToRetry = self.lastParams
            DispatchQueue.main.async {
                if let paramsToRetry {
                    self.retryCount += 1
                    self.log.error("Watchdog fired (attempt \(self.retryCount)). Restarting engine and rerunning trigger for ID=[\(self.geofenceId ?? "")].")
                    // Stop repeating further for this instance; the new instance will own its own watchdog.
                    self.cancelWatchdog()
                    // Destroy the current engine context before retrying.
                    self.cleanup?()
                    // Ask delegate to recreate engine and retry from the beginning.
                    self.onRetry?(paramsToRetry)
                    // Ensure this instance doesn't perform further actions.
                    self.cleanup = nil
                }
            }
        }
        watchdogTimer = timer
        timer.resume()
    }

    private func cancelWatchdog() {
        watchdogTimer?.setEventHandler {}
        watchdogTimer?.cancel()
        watchdogTimer = nil
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
