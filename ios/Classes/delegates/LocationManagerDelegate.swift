import CoreLocation
import OSLog

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    private let log = Logger(subsystem: "com.chunkytofustudios.native_geofence", category: "LocationManagerDelegate")

    private let nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl

    init(nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl) {
        self.nativeGeofenceBackgroundApi = nativeGeofenceBackgroundApi
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        log.debug("didDetermineState: \(state.rawValue) for region: \(region.identifier)")

        guard let event: GeofenceEvent = switch state {
        case .unknown: nil
        case .inside: .enter
        case .outside: .exit
        } else {
            log.error("Unknown Geofence state: \(state.rawValue)")
            return
        }

        guard let activeGeofence = ActiveGeofenceWires.fromRegion(region) else {
            log.error("Unknown region type: \(region)")
            return
        }

        guard let callbackHandle = NativeGeofencePersistence.getRegionCallbackHandle(id: activeGeofence.id) else {
            log.error("Callback handle for region \(activeGeofence.id) not found.")
            return
        }

        let params = GeofenceCallbackParamsWire(geofences: [activeGeofence], event: event, callbackHandle: callbackHandle)
        nativeGeofenceBackgroundApi.geofenceTriggered(params: params)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: any Error) {
        log.debug("monitoringDidFailFor: \(region?.identifier ?? "nil") withError: \(error)")
    }
}
