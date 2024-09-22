/// Geofencing events.
///
/// See the helpful illustration at:
/// https://developer.android.com/develop/sensors-and-location/location/geofencing
enum GeofenceEvent {
  enter(),
  exit(),

  /// Not supported on iOS.
  dwell();
}
