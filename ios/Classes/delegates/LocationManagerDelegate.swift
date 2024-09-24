import CoreLocation
import OSLog

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    let log = Logger(subsystem: "com.chunkytofustudios.native_geofence", category: "LocationManagerDelegate")

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        log.debug("didDetermineState: \(state.rawValue) for region: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: any Error) {
        log.debug("monitoringDidFailFor: \(region?.identifier ?? "nil") withError: \(error)")
    }
}
