import CoreLocation
import Flutter
import OSLog
import UIKit

public class NativeGeofenceApiImpl: NSObject, NativeGeofenceApi {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceApiImpl")
    
    // Prevent multiple instances of CLLocationManager to avoid duplicate triggers.
    private static var sharedLocationManager: CLLocationManager?
    
    private let registerPlugins: FlutterPluginRegistrantCallback
    private let initialized: Bool
    private var backgroundIsolateRun: Bool
    
    private let locationManager: CLLocationManager
    private var locationManagerDelegate: LocationManagerDelegate
    private let nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl
    
    private let headlessRunner: FlutterEngine
    private let eventQueue: [AnyHashable]
    
    init(registerPlugins: FlutterPluginRegistrantCallback) {
        self.registerPlugins = registerPlugins
        initialized = false
        backgroundIsolateRun = false
        
        locationManager = NativeGeofenceApiImpl.sharedLocationManager ?? CLLocationManager()
        NativeGeofenceApiImpl.sharedLocationManager = locationManager
        
        headlessRunner = FlutterEngine(name: Constants.HEADLESS_FLUTTER_ENGINE_NAME, project: nil, allowHeadlessExecution: true)
        
        nativeGeofenceBackgroundApi = NativeGeofenceBackgroundApiImpl(binaryMessenger: headlessRunner.binaryMessenger)
        let delegate = LocationManagerDelegate(nativeGeofenceBackgroundApi: nativeGeofenceBackgroundApi)
        locationManagerDelegate = delegate
        locationManager.delegate = delegate
        log.debug("CLLocationManager delegate updated to instance with ID=\(delegate.instanceId).")

        eventQueue = [AnyHashable]()
    }
    
    func initializeWithCachedState() throws {
        guard let callbackDispatcherHandle = NativeGeofencePersistence.getCallbackDispatcherHandle() else {
            throw PigeonError(code: String(NativeGeofenceErrorCode.pluginInternal.rawValue), message: "Callback dispatcher not found in UserDefaults.", details: nil)
        }
        log.debug("Initializing with cached state.")
        try initialize(callbackDispatcherHandle: callbackDispatcherHandle)
    }
    
    func initialize(callbackDispatcherHandle: Int64) throws {
        NativeGeofencePersistence.setCallbackDispatcherHandle(callbackDispatcherHandle)
        guard let info = FlutterCallbackCache.lookupCallbackInformation(callbackDispatcherHandle) else {
            throw PigeonError(code: String(NativeGeofenceErrorCode.invalidArguments.rawValue), message: "Callback dispatcher not found.", details: nil)
        }
        
        let entrypoint = info.callbackName
        let uri = info.callbackLibraryPath
        headlessRunner.run(withEntrypoint: entrypoint, libraryURI: uri)
        
        // Once our headless runner has been started, we need to register the application's plugins
        // with the runner in order for them to work on the background isolate. `registerPlugins` is
        // a callback set from AppDelegate in the main application. This callback should register
        // all relevant plugins (excluding those which require UI).
        if !backgroundIsolateRun {
            registerPlugins(headlessRunner)
        }
        NativeGeofenceBackgroundApiSetup.setUp(binaryMessenger: headlessRunner.binaryMessenger, api: nativeGeofenceBackgroundApi)
        backgroundIsolateRun = true
        
        log.debug("NativeGeofenceBackgroundApi initialized.")
    }
    
    func createGeofence(geofence: GeofenceWire, completion: @escaping (Result<Void, any Error>) -> Void) {
        let region = CLCircularRegion(
            center: CLLocationCoordinate2DMake(geofence.location.latitude, geofence.location.longitude),
            radius: geofence.radiusMeters,
            identifier: geofence.id
        )
        region.notifyOnEntry = geofence.triggers.contains(.enter)
        region.notifyOnExit = geofence.triggers.contains(.exit)

        NativeGeofencePersistence.setRegionCallbackHandle(id: geofence.id, handle: geofence.callbackHandle)
                
        locationManager.startMonitoring(for: region)
        if geofence.iosSettings.initialTrigger {
            locationManager.requestState(for: region)
        }
        
        log.debug("Created geofence ID=\(geofence.id).")
        
        completion(.success(()))
    }
    
    func reCreateAfterReboot() throws {
        log.info("Re-create after reboot called. iOS handles this automatically, nothing for us to do here.")
    }
    
    func getGeofenceIds() throws -> [String] {
        var geofenceIds: [String] = []
        for region in locationManager.monitoredRegions {
            geofenceIds.append(region.identifier)
        }
        log.debug("getGeofenceIds() found \(geofenceIds.count) geofence(s).")
        return geofenceIds
    }
    
    func getGeofences() throws -> [ActiveGeofenceWire] {
        var geofences: [ActiveGeofenceWire] = []
        for region in locationManager.monitoredRegions {
            if let activeGeofence = ActiveGeofenceWires.fromRegion(region) {
                geofences.append(activeGeofence)
            } else {
                log.error("Unknown region type: \(region)")
            }
        }
        log.debug("getGeofences() found \(geofences.count) geofence(s).")
        return geofences
    }
    
    func removeGeofenceById(id: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        var removedCount = 0
        for region in locationManager.monitoredRegions {
            if region.identifier == id {
                locationManager.stopMonitoring(for: region)
                NativeGeofencePersistence.removeRegionCallbackHandle(id: region.identifier)
                removedCount += 1
            }
        }
        log.debug("Removed \(removedCount) geofence(s) with ID=\(id).")
        completion(.success(()))
    }
    
    func removeAllGeofences(completion: @escaping (Result<Void, any Error>) -> Void) {
        var removedCount = 0
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
            NativeGeofencePersistence.removeRegionCallbackHandle(id: region.identifier)
            removedCount += 1
        }
        log.debug("Removed \(removedCount) geofence(s).")
        completion(.success(()))
    }
}
