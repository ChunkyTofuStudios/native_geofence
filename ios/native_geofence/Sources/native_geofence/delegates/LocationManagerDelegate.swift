import CoreLocation
import Flutter
import OSLog

// Singleton class
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    // Prevent multiple instances of CLLocationManager to avoid duplicate triggers.
    private static var sharedLocationManager: CLLocationManager?
    
    // Only a geofence's first state reported within this time after its creation is treated as its
    // initial state. A later first state is a boundary crossing (e.g. the initial state never came).
    private static let initialStateTimeout: TimeInterval = 30
    
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "LocationManagerDelegate")
    
    private let flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    let locationManager: CLLocationManager
    
    private var headlessFlutterEngine: FlutterEngine? = nil
    private var nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl? = nil
    
    init(flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?) {
        self.flutterPluginRegistrantCallback = flutterPluginRegistrantCallback
        locationManager = LocationManagerDelegate.sharedLocationManager ?? CLLocationManager()
        LocationManagerDelegate.sharedLocationManager = locationManager
        
        super.init()
        locationManager.delegate = self
        
        log.debug("LocationManagerDelegate created with instance ID=\(Int.random(in: 1 ... 1000000)).")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        log.debug("didDetermineState: \(String(describing: state)) for geofence ID: \(region.identifier)")
        
        guard let event: GeofenceEvent = switch state {
        case .unknown: nil
        case .inside: .enter
        case .outside: .exit
        } else {
            log.error("Unknown CLRegionState: \(String(describing: state))")
            return
        }
        
        guard let activeGeofence = ActiveGeofenceWires.fromRegion(region) else {
            log.error("Unknown CLRegion type: \(String(describing: type(of: region)))")
            return
        }

        // Ignore the initial state iOS reports when monitoring starts. This must happen before the
        // triggers check, otherwise an initial state that isn't a trigger wouldn't clear the flag.
        if let awaitingSince = NativeGeofencePersistence.getRegionAwaitingInitialStateSince(id: activeGeofence.id) {
            NativeGeofencePersistence.removeRegionAwaitingInitialState(id: activeGeofence.id)
            let elapsed = Date().timeIntervalSince(awaitingSince)
            if (0..<LocationManagerDelegate.initialStateTimeout).contains(elapsed) {
                log.debug("Ignoring initial state for geofence ID=\(activeGeofence.id) since initialTrigger is disabled.")
                return
            }
            log.debug("First state for geofence ID=\(activeGeofence.id) came after \(Int(elapsed))s, handling it as a boundary crossing.")
        }

        if !activeGeofence.triggers.contains(event) {
            return
        }
        
        guard let callbackHandle = NativeGeofencePersistence.getRegionCallbackHandle(id: activeGeofence.id) else {
            log.error("Callback handle for region \(activeGeofence.id) not found.")
            return
        }
        
        // iOS does not provide the location or time of the geofence trigger.
        let params = GeofenceCallbackParamsWire(geofences: [activeGeofence], event: event, location: nil, callbackHandle: callbackHandle, triggerTimestampMillis: nil)
        
        guard let backgroundApi = nativeGeofenceBackgroundApi ?? createFlutterEngine() else {
            return
        }
        
        backgroundApi.geofenceTriggered(params: params, cleanup: cleanupFlutterEngine)
        log.debug("Geofence trigger event sent.")
        
        // The engine may be stuck, e.g. a callback never completed. Since the app may have just resumed from
        // suspension, give an in-progress callback a moment to complete before replacing the engine.
        if backgroundApi.isStuck() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.HEADLESS_FLUTTER_ENGINE_GRACE_SECONDS) { [weak self] in
                self?.replaceFlutterEngineIfStuck(backgroundApi)
            }
        }
    }
    
    // Replaces a stuck headless Flutter engine with a new one, re-sending the events it had not processed yet.
    // The stuck callback is not re-run.
    private func replaceFlutterEngineIfStuck(_ backgroundApi: NativeGeofenceBackgroundApiImpl) {
        guard backgroundApi === nativeGeofenceBackgroundApi, backgroundApi.isStuck() else {
            return
        }
        log.error("Headless Flutter engine has been busy for over \(Constants.HEADLESS_FLUTTER_ENGINE_TIMEOUT_SECONDS) seconds, replacing it.")
        
        let pendingEvents = backgroundApi.close()
        cleanupFlutterEngine()
        if pendingEvents.isEmpty {
            return
        }
        
        guard let newBackgroundApi = createFlutterEngine() else {
            return
        }
        for eventParams in pendingEvents {
            newBackgroundApi.geofenceTriggered(params: eventParams, cleanup: cleanupFlutterEngine)
        }
    }
    
    // Shutdown the engine once the Geofence events are handled
    private func cleanupFlutterEngine() {
        nativeGeofenceBackgroundApi = nil
        headlessFlutterEngine?.destroyContext()
        headlessFlutterEngine = nil
        log.debug("Flutter engine cleanup complete.")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: any Error) {
        log.error("monitoringDidFailFor: \(region?.identifier ?? "nil") withError: \(error)")
    }
    
    private func createFlutterEngine() -> NativeGeofenceBackgroundApiImpl? {
        // Create a Flutter engine
        headlessFlutterEngine = FlutterEngine(name: Constants.HEADLESS_FLUTTER_ENGINE_NAME, project: nil, allowHeadlessExecution: true)
        log.debug("A new headless Flutter engine has been created.")
        
        guard let callbackDispatcherHandle = NativeGeofencePersistence.getCallbackDispatcherHandle() else {
            log.error("Callback dispatcher not found in UserDefaults.")
            return nil
        }
        
        guard let callbackDispatcherInfo = FlutterCallbackCache.lookupCallbackInformation(callbackDispatcherHandle) else {
            log.error("Callback dispatcher not found.")
            return nil
        }
        
        // Start the engine at the specified callback method.
        headlessFlutterEngine!.run(withEntrypoint: callbackDispatcherInfo.callbackName, libraryURI: callbackDispatcherInfo.callbackLibraryPath)
        // Once our headless runner has been started, we need to register the application's plugins
        // with the runner in order for them to work on the background isolate.
        // `flutterPluginRegistrantCallback` is a callback set from AppDelegate in the main application.
        // This callback should register all relevant plugins (excluding those which require UI).
        flutterPluginRegistrantCallback?(headlessFlutterEngine!)
        log.debug("Flutter engine started and plugins registered.")
        
        nativeGeofenceBackgroundApi = NativeGeofenceBackgroundApiImpl(binaryMessenger: headlessFlutterEngine!.binaryMessenger)
        NativeGeofenceBackgroundApiSetup.setUp(binaryMessenger: headlessFlutterEngine!.binaryMessenger, api: nativeGeofenceBackgroundApi)
        log.debug("NativeGeofenceBackgroundApi initialized.")

        // Also expose the main API so geofence callbacks can create/remove geofences. The plugin registrant above
        // does not do this since NativeGeofencePlugin only registers once, for the main Flutter engine.
        NativeGeofenceApiSetup.setUp(binaryMessenger: headlessFlutterEngine!.binaryMessenger, api: NativeGeofenceApiImpl(locationManagerDelegate: self))
        log.debug("NativeGeofenceApi initialized for the headless Flutter engine.")

        return nativeGeofenceBackgroundApi
    }
}
