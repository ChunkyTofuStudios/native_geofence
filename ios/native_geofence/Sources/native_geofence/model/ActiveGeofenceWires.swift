import CoreLocation

class ActiveGeofenceWires {
    static func fromRegion(_ region: CLRegion) -> ActiveGeofenceWire? {
        guard let circularRegion = region as? CLCircularRegion else { return nil }
        return ActiveGeofenceWire(
            id: circularRegion.identifier,
            location: LocationWire(
                latitude: circularRegion.center.latitude,
                longitude: circularRegion.center.longitude
            ),
            radiusMeters: circularRegion.radius,
            triggers: [
                circularRegion.notifyOnEntry ? .enter : nil,
                circularRegion.notifyOnExit ? .exit : nil
            ].compactMap { $0 }
        )
    }
}
