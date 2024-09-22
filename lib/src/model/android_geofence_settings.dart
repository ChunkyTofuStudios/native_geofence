import 'package:native_geofence/src/model/geofence_event.dart';

class AndroidGeofenceSettings {
  /// Sets the geofence behavior at the moment when the geofences are added.
  /// For example, listing [GeofenceEvent.enter] here will trigger the Geofence
  /// immediately if the user is already inside the geofence.
  List<GeofenceEvent> initialTrigger;

  /// The geofence will be removed automatically after this period of time.
  /// If you don't set this the geofence will never expire.
  Duration? expiration;

  /// The delay between [GeofenceEvent.enter] and [GeofenceEvent.dwell].
  /// Only has impact if [GeofenceEvent.dwell] is one of the triggers.
  Duration loiteringDelay;

  /// The responsiveness of the geofence.
  ///
  /// Defaults to 0. Setting a big responsiveness value, for example 5 minutes,
  /// can save power significantly. However, setting a very small responsiveness
  /// value, for example 5 seconds, doesn't necessarily mean you will get
  /// notified right after the user enters or exits a geofence: internally, the
  /// OS might adjust the responsiveness value to save power when needed.
  Duration? notificationResponsiveness;

  AndroidGeofenceSettings({
    this.initialTrigger = const [GeofenceEvent.enter, GeofenceEvent.dwell],
    this.expiration = null,
    this.loiteringDelay = const Duration(minutes: 5),
    this.notificationResponsiveness = null,
  });

  @override
  String toString() {
    return 'AndroidGeofenceSettings(initialTrigger: $initialTrigger, '
        'expiration: $expiration, loiteringDelay: $loiteringDelay, '
        'notificationResponsiveness: $notificationResponsiveness)';
  }
}
