import CoreLocation
import Flutter
import UIKit

public class NativeGeofenceApiImpl: NSObject, NativeGeofenceApi {
    let _locationManager: CLLocationManager
    let _locationManagerDelegate: LocationManagerDelegate
    let _headlessRunner: FlutterEngine
    let _persistentState: UserDefaults
    let _eventQueue: [AnyHashable]
    
    override init() {
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
    }
    
    func createGeofence(geofence: GeofenceWire, completion: @escaping (Result<Void, any Error>) -> Void) {
        <#code#>
    }
    
    func reCreateAfterReboot() throws {
        <#code#>
    }
    
    func getGeofenceIds() throws -> [String] {
        <#code#>
    }
    
    func getGeofences() throws -> [GeofenceWire] {
        <#code#>
    }
    
    func removeGeofenceById(id: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        <#code#>
    }
    
    func removeAllGeofences(completion: @escaping (Result<Void, any Error>) -> Void) {
        <#code#>
    }
    
    private func setCallbackDispatcherHandle(_ handle: Int64) {
        _persistentState.set(
            NSNumber(value: handle),
            forKey: Constants.CALLBACK_DISPATCHER_KEY)
    }
}
