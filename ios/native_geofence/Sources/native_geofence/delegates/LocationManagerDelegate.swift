import CoreLocation
import Flutter
import OSLog

// Singleton class
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    // A single CLLocationManager (and delegate) is shared by all Flutter engines to avoid duplicate triggers. It is
    // created at app launch by NativeGeofencePlugin.setPluginRegistrantCallback, so that geofence events which launch
    // the app in the background are delivered even if no Flutter engine is created (e.g. no UI scene is connected).
    static let shared = LocationManagerDelegate()
    
    // Only a geofence's first state reported within this time after its creation is treated as its
    // initial state. A later first state is a boundary crossing (e.g. the initial state never came).
    private static let initialStateTimeout: TimeInterval = 30
    
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "LocationManagerDelegate")
    
    var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback? = nil
    let locationManager: CLLocationManager
    
    private var headlessFlutterEngine: FlutterEngine? = nil
    private var nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl? = nil
    
    private override init() {
        locationManager = CLLocationManager()
        
        super.init()
        locationManager.delegate = self
        
        log.debug("LocationManagerDelegate created.")
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
        
        // Shutdown the engine once the Geofence event is handled
        func cleanup() {
            nativeGeofenceBackgroundApi = nil
            headlessFlutterEngine?.destroyContext()
            headlessFlutterEngine = nil
            log.debug("Flutter engine cleanup complete.")
        }
        
        nativeGeofenceBackgroundApi!.geofenceTriggered(params: params, cleanup: cleanup)
        log.debug("Geofence trigger event sent.")
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

        return nativeGeofenceBackgroundApi
    }
}
