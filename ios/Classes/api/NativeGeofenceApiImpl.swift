import CoreLocation
import Flutter
import OSLog
import UIKit

public class NativeGeofenceApiImpl: NSObject, NativeGeofenceApi {
    private let log = Logger(subsystem: "com.chunkytofustudios.native_geofence", category: "NativeGeofenceApiImpl")
    
    private let registerPlugins: FlutterPluginRegistrantCallback
    private let initialized: Bool
    private var backgroundIsolateRun: Bool
    
    private let locationManager: CLLocationManager
    private var locationManagerDelegate: LocationManagerDelegate?
    private let nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl
    private let headlessRunner: FlutterEngine
    private let eventQueue: [AnyHashable]
    
    init(registerPlugins: FlutterPluginRegistrantCallback) {
        self.registerPlugins = registerPlugins
        initialized = false
        backgroundIsolateRun = false
        
        locationManager = CLLocationManager()
        locationManager.allowsBackgroundLocationUpdates = true
        
        headlessRunner = FlutterEngine(name: "NativeGeofenceIsolate", project: nil, allowHeadlessExecution: true)
        
        nativeGeofenceBackgroundApi = NativeGeofenceBackgroundApiImpl(binaryMessenger: headlessRunner.binaryMessenger)
        locationManagerDelegate = LocationManagerDelegate(nativeGeofenceBackgroundApi: nativeGeofenceBackgroundApi)
        locationManager.delegate = locationManagerDelegate

        eventQueue = [AnyHashable]()
    }
    
    func initializeWithCachedState() throws {
        guard let callbackDispatcherHandle = NativeGeofencePersistence.getCallbackDispatcherHandle() else {
            throw PigeonError(code: String(NativeGeofenceErrorCode.pluginInternal.rawValue), message: "Callback dispatcher not found in UserDefaults.", details: nil)
        }
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
        
        log.info("NativeGeofenceBackgroundApi initialized.")
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
        
        completion(.success(()))
    }
    
    func reCreateAfterReboot() throws {
        log.info("Re-create after reboot called. Not doing anything.")
    }
    
    func getGeofenceIds() throws -> [String] {
        var geofenceIds: [String] = []
        for region in locationManager.monitoredRegions {
            geofenceIds.append(region.identifier)
        }
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
        return geofences
    }
    
    func removeGeofenceById(id: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        for region in locationManager.monitoredRegions {
            if region.identifier == id {
                locationManager.stopMonitoring(for: region)
                NativeGeofencePersistence.removeRegionCallbackHandle(id: region.identifier)
            }
        }
        completion(.success(()))
    }
    
    func removeAllGeofences(completion: @escaping (Result<Void, any Error>) -> Void) {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
            NativeGeofencePersistence.removeRegionCallbackHandle(id: region.identifier)
        }
        completion(.success(()))
    }
}
