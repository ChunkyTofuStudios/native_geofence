import CoreLocation
import Flutter
import OSLog

// Singleton class
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    // Prevent multiple instances of CLLocationManager to avoid duplicate triggers.
    private static var sharedLocationManager: CLLocationManager?
    
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "LocationManagerDelegate")
    
    private let flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    let locationManager: CLLocationManager
    
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
        
        guard let callbackHandle = NativeGeofencePersistence.getRegionCallbackHandle(id: activeGeofence.id) else {
            log.error("Callback handle for region \(activeGeofence.id) not found.")
            return
        }
        
        let params = GeofenceCallbackParamsWire(geofences: [activeGeofence], event: event, callbackHandle: callbackHandle)
        
        guard let (backgroundApi, engine) = createFlutterEngine() else {
            return
        }
        
        // Shutdown the engine once the Geofence event is handled
        func cleanup() {
            engine.destroyContext()
            log.debug("Flutter engine cleanup complete.")
        }
        
        backgroundApi.geofenceTriggered(params: params, cleanup: cleanup)
        log.debug("Geofence trigger event sent.")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: any Error) {
        log.error("monitoringDidFailFor: \(region?.identifier ?? "nil") withError: \(error)")
    }
    
    private func createFlutterEngine() -> (NativeGeofenceBackgroundApiImpl, FlutterEngine)? {
        // Create a Flutter engine - use unique name with timestamp to avoid conflicts
        let engineName = "\(Constants.HEADLESS_FLUTTER_ENGINE_NAME)_\(Date().timeIntervalSince1970)"
        let engine = FlutterEngine(name: engineName, project: nil, allowHeadlessExecution: true)
        log.debug("A new headless Flutter engine has been created with name: \(engineName).")
        
        guard let callbackDispatcherHandle = NativeGeofencePersistence.getCallbackDispatcherHandle() else {
            log.error("Callback dispatcher not found in UserDefaults.")
            return nil
        }
        
        guard let callbackDispatcherInfo = FlutterCallbackCache.lookupCallbackInformation(callbackDispatcherHandle) else {
            log.error("Callback dispatcher not found.")
            return nil
        }
        
        // Start the engine at the specified callback method.
        engine.run(withEntrypoint: callbackDispatcherInfo.callbackName, libraryURI: callbackDispatcherInfo.callbackLibraryPath)
        // Once our headless runner has been started, we need to register the application's plugins
        // with the runner in order for them to work on the background isolate.
        // `flutterPluginRegistrantCallback` is a callback set from AppDelegate in the main application.
        // This callback should register all relevant plugins (excluding those which require UI).
        flutterPluginRegistrantCallback?(engine)
        log.debug("Flutter engine started and plugins registered.")
        
        let backgroundApi = NativeGeofenceBackgroundApiImpl(binaryMessenger: engine.binaryMessenger)
        NativeGeofenceBackgroundApiSetup.setUp(binaryMessenger: engine.binaryMessenger, api: backgroundApi)
        log.debug("NativeGeofenceBackgroundApi initialized.")

        // Also register the main NativeGeofenceApi in background context
        let nativeGeofenceMainApi = NativeGeofenceApiImpl(registerPlugins: flutterPluginRegistrantCallback!)
        NativeGeofenceApiSetup.setUp(binaryMessenger: engine.binaryMessenger, api: nativeGeofenceMainApi)
        log.debug("NativeGeofenceMainApi also initialized in background context.")

        return (backgroundApi, engine)
    }
}
