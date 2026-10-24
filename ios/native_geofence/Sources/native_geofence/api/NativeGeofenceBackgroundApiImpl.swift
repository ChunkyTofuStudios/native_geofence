import CoreLocation
import Flutter
import OSLog

class NativeGeofenceBackgroundApiImpl: NativeGeofenceBackgroundApi {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceBackgroundApiImpl")
    
    private let binaryMessenger: FlutterBinaryMessenger
    
    private var eventQueue: [GeofenceCallbackParamsWire] = .init()
    // True while a Dart geofence callback is running. Only one callback runs at a time; events received in the
    // meantime (e.g. triggered by geofences created within the callback) wait in the queue.
    private var isCallbackInFlight: Bool = false
    // When the Dart side last started work it has not finished yet: initializing, or running a callback.
    private var busySince: UInt64 = NativeGeofenceBackgroundApiImpl.now()
    private var isClosed: Bool = false
    private var nativeGeoFenceTriggerApi: NativeGeofenceTriggerApi? = nil
    private var cleanup: (() -> Void)? = nil
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
    }
    
    func geofenceTriggered(params: GeofenceCallbackParamsWire, cleanup: @escaping () -> Void) {
        objc_sync_enter(self)
        
        eventQueue.append(params)
        self.cleanup = cleanup
        
        objc_sync_exit(self)
        
        guard let nativeGeoFenceTriggerApi else {
            log.debug("Waiting for NativeGeofenceTriggerApi to become available...")
            return
        }
        processQueue()
    }
    
    func triggerApiInitialized() throws {
        objc_sync_enter(self)
        
        if (nativeGeoFenceTriggerApi == nil) {
            nativeGeoFenceTriggerApi = NativeGeofenceTriggerApi(binaryMessenger: binaryMessenger)
            log.debug("NativeGeofenceTriggerApi setup complete.")
        }
        
        objc_sync_exit(self)
        
       if eventQueue.isEmpty {
            log.debug("Waiting for geofence event...")
            return
        }
        processQueue()
    }
    
    func promoteToForeground() throws {
        log.info("promoteToForeground called. iOS does not distinguish between foreground and background, nothing to do here.")
    }
    
    func demoteToBackground() throws {
        log.info("demoteToBackground called. iOS does not distinguish between foreground and background, nothing to do here.")
    }
    
    /// Whether the Dart side has been busy for too long, e.g. a geofence callback is awaiting a Future that never
    /// completes. Queued events would otherwise wait forever.
    func isStuck() -> Bool {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let isBusy = nativeGeoFenceTriggerApi == nil || isCallbackInFlight
        let busySeconds = Double(NativeGeofenceBackgroundApiImpl.now() - busySince) / 1_000_000_000
        return !isClosed && isBusy && busySeconds > Constants.HEADLESS_FLUTTER_ENGINE_TIMEOUT_SECONDS
    }
    
    /// Stops processing events and returns the ones that were not sent to Dart yet.
    ///
    /// The caller is responsible for destroying the Flutter engine.
    func close() -> [GeofenceCallbackParamsWire] {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        isClosed = true
        cleanup = nil
        let pendingEvents = eventQueue
        eventQueue.removeAll()
        return pendingEvents
    }
    
    private func processQueue() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if isClosed {
            log.error("NativeGeofenceBackgroundApi already closed, ignoring additional events.")
            return
        }
        
        if isCallbackInFlight {
            log.debug("A geofence callback is still running, \(self.eventQueue.count) event(s) queued.")
            return
        }
        
        if !eventQueue.isEmpty {
            let params = eventQueue.removeFirst()
            log.debug("Queue dispatch: sending geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))].")
            callGeofenceTriggerApi(params: params)
            return
        }
        
        // Now that the event queue is empty and no callback is running we can cleanup and de-allocate this class.
        cleanup?()
        isClosed = true
    }
    
    private func callGeofenceTriggerApi(params: GeofenceCallbackParamsWire) {
        guard let api = nativeGeoFenceTriggerApi else {
            log.error("NativeGeofenceTriggerApi was nil, this should not happen.")
            return
        }
        log.debug("Calling Dart callback to process geofence trigger for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] event=\(String(describing: params.event)).")
        isCallbackInFlight = true
        busySince = NativeGeofenceBackgroundApiImpl.now()
        api.geofenceTriggered(params: params, completion: { result in
            if case .success = result {
                self.log.debug("Geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] processed successfully.")
            } else {
                self.log.error("Geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] failed.")
            }
            objc_sync_enter(self)
            self.isCallbackInFlight = false
            objc_sync_exit(self)
            // Now that the callback is complete we can process the next item in the queue, if any.
            self.processQueue()
        })
    }
    
    // Monotonic time in nanoseconds; unlike Date() it is not affected by clock changes and keeps counting during sleep.
    private static func now() -> UInt64 {
        return clock_gettime_nsec_np(CLOCK_MONOTONIC)
    }
    
    private static func geofenceIds(_ params: GeofenceCallbackParamsWire) -> String {
        let ids: [String] = params.geofences.map(\.id)
        return ids.joined(separator: ",")
    }
}
