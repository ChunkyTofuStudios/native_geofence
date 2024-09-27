import CoreLocation
import OSLog

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    private let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "LocationManagerDelegate")

    private let nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl
    let instanceId: Int

    init(nativeGeofenceBackgroundApi: NativeGeofenceBackgroundApiImpl) {
        self.nativeGeofenceBackgroundApi = nativeGeofenceBackgroundApi
        instanceId = Int.random(in: 1 ... 1000000)
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
        nativeGeofenceBackgroundApi.geofenceTriggered(params: params)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: any Error) {
        log.error("monitoringDidFailFor: \(region?.identifier ?? "nil") withError: \(error)")
    }
}
