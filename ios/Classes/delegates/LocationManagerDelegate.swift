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

        // Enqueue processing to ensure serialized execution with 500ms spacing.
        GeofenceEventQueue.shared.enqueue { [weak self] done in
            guard let self = self else { return }
            guard let (backgroundApi, engine) = self.createFlutterEngine(onProcessingComplete: {
                // Signal the queue to continue after iOS receives processingComplete from Dart.
                done()
            }, onRetry: { [weak self] retryParams in
                guard let self = self else { return }
                guard let (retryApi, retryEngine) = self.createFlutterEngine(onProcessingComplete: {
                    done()
                }, onRetry: { params in
                    // Chain retries if needed; this will continue recreating engines every watchdog cycle.
                    GeofenceEventQueue.shared.enqueue { [weak self] innerDone in
                        guard let self = self else { return }
                        guard let (api2, engine2) = self.createFlutterEngine(onProcessingComplete: {
                            innerDone()
                        }, onRetry: nil) else {
                            innerDone()
                            return
                        }
                        func cleanup2() {
                            engine2.destroyContext()
                            self.log.debug("Flutter engine cleanup complete (chained retry).")
                        }
                        api2.geofenceTriggered(params: params, cleanup: cleanup2)
                        self.log.debug("Geofence trigger CHAINED RETRY sent.")
                    }
                }) else {
                    // If engine creation fails, still release the queue slot.
                    done()
                    return
                }
                func retryCleanup() {
                    retryEngine.destroyContext()
                    self.log.debug("Flutter engine cleanup complete (retry).")
                }
                retryApi.geofenceTriggered(params: retryParams, cleanup: retryCleanup)
                self.log.debug("Geofence trigger RETRY sent.")
            }) else {
                // If engine creation fails, still release the queue slot.
                done()
                return
            }

            // Let the background API handle its own lifecycle
            func cleanup() {
                engine.destroyContext()
                self.log.debug("Flutter engine cleanup complete.")
            }

            backgroundApi.geofenceTriggered(params: params, cleanup: cleanup)
            self.log.debug("Geofence trigger event enqueued and sent.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: any Error) {
        log.error("monitoringDidFailFor: \(region?.identifier ?? "nil") withError: \(error)")
    }
    
    private func createFlutterEngine(onProcessingComplete: (() -> Void)? = nil, onRetry: ((GeofenceCallbackParamsWire) -> Void)? = nil) -> (NativeGeofenceBackgroundApiImpl, FlutterEngine)? {
        // Create a Flutter engine with unique name to avoid conflicts
        let engineName = "\(Constants.HEADLESS_FLUTTER_ENGINE_NAME)_\(Date().timeIntervalSince1970)_\(Int.random(in: 1000...9999))"
        let headlessFlutterEngine = FlutterEngine(name: engineName, project: nil, allowHeadlessExecution: true)
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
        headlessFlutterEngine.run(withEntrypoint: callbackDispatcherInfo.callbackName, libraryURI: callbackDispatcherInfo.callbackLibraryPath)
        // Once our headless runner has been started, we need to register the application's plugins
        // with the runner in order for them to work on the background isolate.
        // `flutterPluginRegistrantCallback` is a callback set from AppDelegate in the main application.
        // This callback should register all relevant plugins (excluding those which require UI).
        flutterPluginRegistrantCallback?(headlessFlutterEngine)
        log.debug("Flutter engine started and plugins registered.")
        
        let nativeGeofenceBackgroundApi = NativeGeofenceBackgroundApiImpl(binaryMessenger: headlessFlutterEngine.binaryMessenger, onProcessingComplete: onProcessingComplete, onRetry: onRetry)
        NativeGeofenceBackgroundApiSetup.setUp(binaryMessenger: headlessFlutterEngine.binaryMessenger, api: nativeGeofenceBackgroundApi)
        log.debug("NativeGeofenceBackgroundApi initialized.")

        // Register main API using the SAME LocationManagerDelegate instance in background context
        let nativeGeofenceMainApi = NativeGeofenceApiImpl(registerPlugins: nil, runningInBackground: true, locationManagerDelegate: self)
        NativeGeofenceApiSetup.setUp(binaryMessenger: headlessFlutterEngine.binaryMessenger, api: nativeGeofenceMainApi)
        log.debug("NativeGeofenceMainApi initialized in background context using SAME LocationManagerDelegate!")

        return (nativeGeofenceBackgroundApi, headlessFlutterEngine)
    }
}