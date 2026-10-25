import CoreLocation
import Flutter
import OSLog

class NativeGeofenceBackgroundApiImpl: NativeGeofenceBackgroundApi {
    // Queued events stop waiting for a geofence callback that has not completed after this long. For reference, iOS
    // only gives apps ~10-30 seconds of background time per geofence event.
    private static let callbackTimeout: TimeInterval = 60
    
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceBackgroundApiImpl")
    
    private let binaryMessenger: FlutterBinaryMessenger
    
    private var eventQueue: [GeofenceCallbackParamsWire] = .init()
    // The Dart geofence callback that queued events wait for, nil if none. Only one callback runs at a time; events
    // received in the meantime (e.g. triggered by geofences created within the callback) wait in the queue.
    private var awaitedCallbackId: UUID? = nil
    // Dart callbacks that have not completed yet, including ones no longer waited for. The engine must outlive them.
    private var callbacksInFlight: Int = 0
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
    
    private func processQueue() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if isClosed {
            log.error("NativeGeofenceBackgroundApi already closed, ignoring additional events.")
            return
        }
        
        if awaitedCallbackId != nil {
            log.debug("A geofence callback is still running, \(self.eventQueue.count) event(s) queued.")
            return
        }
        
        if !eventQueue.isEmpty {
            let params = eventQueue.removeFirst()
            log.debug("Queue dispatch: sending geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))].")
            callGeofenceTriggerApi(params: params)
            return
        }
        
        // Now that the event queue is empty and all callbacks have completed we can cleanup and de-allocate this class.
        if callbacksInFlight == 0 {
            cleanup?()
            isClosed = true
        }
    }
    
    private func callGeofenceTriggerApi(params: GeofenceCallbackParamsWire) {
        guard let api = nativeGeoFenceTriggerApi else {
            log.error("NativeGeofenceTriggerApi was nil, this should not happen.")
            return
        }
        log.debug("Calling Dart callback to process geofence trigger for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] event=\(String(describing: params.event)).")
        let callbackId = UUID()
        awaitedCallbackId = callbackId
        callbacksInFlight += 1
        // Don't let a callback that never completes (e.g. it awaits a Future that never completes) block the queue
        // forever. Wall time keeps counting while the device sleeps, so this also fires once a suspended app resumes
        // (changing the system clock shifts it though).
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + NativeGeofenceBackgroundApiImpl.callbackTimeout) { [weak self] in
            guard let self else { return }
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            if self.awaitedCallbackId == callbackId {
                self.log.error("Geofence callback for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] has not completed after \(Int(NativeGeofenceBackgroundApiImpl.callbackTimeout)) seconds, no longer waiting for it.")
                self.awaitedCallbackId = nil
                self.processQueue()
            }
        }
        api.geofenceTriggered(params: params, completion: { result in
            if case .success = result {
                self.log.debug("Geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] processed successfully.")
            } else {
                self.log.error("Geofence trigger event for IDs=[\(NativeGeofenceBackgroundApiImpl.geofenceIds(params))] failed.")
            }
            objc_sync_enter(self)
            self.callbacksInFlight -= 1
            if self.awaitedCallbackId == callbackId {
                self.awaitedCallbackId = nil
            }
            objc_sync_exit(self)
            // Now that the callback is complete we can process the next item in the queue, if any.
            self.processQueue()
        })
    }
    
    private static func geofenceIds(_ params: GeofenceCallbackParamsWire) -> String {
        let ids: [String] = params.geofences.map(\.id)
        return ids.joined(separator: ",")
    }
}
