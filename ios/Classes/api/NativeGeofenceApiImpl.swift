import CoreLocation
import Flutter
import OSLog
import UIKit

public class NativeGeofenceApiImpl: NSObject, NativeGeofenceApi {
    let log = Logger(subsystem: "com.chunkytofustudios.native_geofence", category: "LocationManagerDelegate")
    
    let _registerPlugins: FlutterPluginRegistrantCallback
    let _initialized: Bool
    var _backgroundIsolateRun: Bool
    
    let _locationManager: CLLocationManager
    let _locationManagerDelegate: LocationManagerDelegate
    let _headlessRunner: FlutterEngine
    let _persistentState: UserDefaults
    let _eventQueue: [AnyHashable]
    
    init(registerPlugins: FlutterPluginRegistrantCallback) {
        _registerPlugins = registerPlugins
        _initialized = false
        _backgroundIsolateRun = false
        
        _locationManager = CLLocationManager()
        _locationManager.allowsBackgroundLocationUpdates = true
        
        _locationManagerDelegate = LocationManagerDelegate()
        _locationManager.delegate = _locationManagerDelegate
        
        _headlessRunner = FlutterEngine(name: "GeofencingIsolate", project: nil, allowHeadlessExecution: true)
        
        _persistentState = UserDefaults.standard
        
        _eventQueue = [AnyHashable]()
    }
    
    func initialize(callbackDispatcherHandle: Int64) throws {
        setCallbackDispatcherHandle(callbackDispatcherHandle)
        guard let info = FlutterCallbackCache.lookupCallbackInformation(callbackDispatcherHandle) else {
            throw PigeonError(code: String(NativeGeofenceErrorCode.invalidArguments.rawValue), message: "Callback dispatcher not found.", details: nil)
        }
        let entrypoint = info.callbackName
        let uri = info.callbackLibraryPath
        _headlessRunner.run(withEntrypoint: entrypoint, libraryURI: uri)
        
        // Once our headless runner has been started, we need to register the application's plugins
        // with the runner in order for them to work on the background isolate. `registerPlugins` is
        // a callback set from AppDelegate in the main application. This callback should register
        // all relevant plugins (excluding those which require UI).
        if !_backgroundIsolateRun {
            _registerPlugins(_headlessRunner)
        }
        _backgroundIsolateRun = true
    }
    
    func createGeofence(geofence: GeofenceWire, completion: @escaping (Result<Void, any Error>) -> Void) {
        let region = CLCircularRegion(
            center: CLLocationCoordinate2DMake(geofence.location.latitude, geofence.location.longitude),
            radius: geofence.radiusMeters,
            identifier: geofence.id)
        region.notifyOnEntry = geofence.triggers.contains(.enter)
        region.notifyOnExit = geofence.triggers.contains(.exit)

        setRegionCallbackHandle(id: geofence.id, handle: geofence.callbackHandle)
                
        _locationManager.startMonitoring(for: region)
        _locationManager.requestState(for: region)
        
        completion(.success(()))
    }
    
    func reCreateAfterReboot() throws {
        log.info("Re-create after reboot called. Not doing anything.")
    }
    
    func getGeofenceIds() throws -> [String] {
        var geofenceIds: [String] = []
        for region in _locationManager.monitoredRegions {
            geofenceIds.append(region.identifier)
        }
        return geofenceIds
    }
    
    func getGeofences() throws -> [GeofenceWire] {
        <#code#>
    }
    
    func removeGeofenceById(id: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        for region in _locationManager.monitoredRegions {
            if region.identifier == id {
                _locationManager.stopMonitoring(for: region)
                removeRegionCallbackHandle(id: region.identifier)
            }
        }
        completion(.success(()))
    }
    
    func removeAllGeofences(completion: @escaping (Result<Void, any Error>) -> Void) {
        for region in _locationManager.monitoredRegions {
            _locationManager.stopMonitoring(for: region)
            removeRegionCallbackHandle(id: region.identifier)
        }
        completion(.success(()))
    }
    
    private func setCallbackDispatcherHandle(_ handle: Int64) {
        _persistentState.set(
            NSNumber(value: handle),
            forKey: Constants.CALLBACK_DISPATCHER_KEY)
    }
    
    private func getRegionCallbackMapping() -> [AnyHashable: Any] {
        var callbackDict = _persistentState.dictionary(forKey: Constants.GEOFENCE_CALLBACK_DICT_KEY)
        if callbackDict == nil {
            callbackDict = [:]
            _persistentState.set(callbackDict, forKey: Constants.GEOFENCE_CALLBACK_DICT_KEY)
        }
        return callbackDict!
    }
    
    private func setRegionCallbackMapping(_ mapping: inout [AnyHashable: Any]) {
        _persistentState.set(mapping, forKey: Constants.GEOFENCE_CALLBACK_DICT_KEY)
    }
    
    private func setRegionCallbackHandle(id: String, handle: Int64) {
        var mapping = getRegionCallbackMapping()
        mapping[id] = NSNumber(value: handle)
        setRegionCallbackMapping(&mapping)
    }
    
    private func removeRegionCallbackHandle(id: String) {
        var mapping = getRegionCallbackMapping()
        mapping.removeValue(forKey: id)
        setRegionCallbackMapping(&mapping)
    }
}
