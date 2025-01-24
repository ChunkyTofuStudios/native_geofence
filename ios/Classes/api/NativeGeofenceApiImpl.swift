import CoreLocation
import Flutter
import OSLog
import UIKit

public class NativeGeofenceApiImpl: NSObject, NativeGeofenceApi {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofenceApiImpl")
    
    private let locationManagerDelegate: LocationManagerDelegate
    
    init(registerPlugins: FlutterPluginRegistrantCallback) {
        self.locationManagerDelegate = LocationManagerDelegate(flutterPluginRegistrantCallback: registerPlugins)
    }
    
    func initialize(callbackDispatcherHandle: Int64) throws {
        NativeGeofencePersistence.setCallbackDispatcherHandle(callbackDispatcherHandle)
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
        
        locationManagerDelegate.locationManager.startMonitoring(for: region)
        if geofence.iosSettings.initialTrigger {
            locationManagerDelegate.locationManager.requestState(for: region)
        }
        
        log.debug("Created geofence ID=\(geofence.id).")
        
        completion(.success(()))
    }
    
    func reCreateAfterReboot() throws {
        log.info("Re-create after reboot called. iOS handles this automatically, nothing for us to do here.")
    }
    
    func getGeofenceIds() throws -> [String] {
        var geofenceIds: [String] = []
        for region in locationManagerDelegate.locationManager.monitoredRegions {
            geofenceIds.append(region.identifier)
        }
        log.debug("getGeofenceIds() found \(geofenceIds.count) geofence(s).")
        return geofenceIds
    }
    
    func getGeofences() throws -> [ActiveGeofenceWire] {
        var geofences: [ActiveGeofenceWire] = []
        for region in locationManagerDelegate.locationManager.monitoredRegions {
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
        for region in locationManagerDelegate.locationManager.monitoredRegions {
            if region.identifier == id {
                locationManagerDelegate.locationManager.stopMonitoring(for: region)
                NativeGeofencePersistence.removeRegionCallbackHandle(id: region.identifier)
                removedCount += 1
            }
        }
        log.debug("Removed \(removedCount) geofence(s) with ID=\(id).")
        completion(.success(()))
    }
    
    func removeAllGeofences(completion: @escaping (Result<Void, any Error>) -> Void) {
        var removedCount = 0
        for region in locationManagerDelegate.locationManager.monitoredRegions {
            locationManagerDelegate.locationManager.stopMonitoring(for: region)
            NativeGeofencePersistence.removeRegionCallbackHandle(id: region.identifier)
            removedCount += 1
        }
        log.debug("Removed \(removedCount) geofence(s).")
        completion(.success(()))
    }
}
