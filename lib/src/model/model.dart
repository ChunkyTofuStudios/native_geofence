import 'package:native_geofence/src/generated/platform_bindings.g.dart';

/// A simple representation of a geographic location.
class Location {
  final double latitude;
  final double longitude;

  const Location({required this.latitude, required this.longitude});
}

/// iOS specific Geofence settings.
class IosGeofenceSettings {
  /// Whether a geofence event should trigger immediately when the geofence is
  /// added.
  /// For example, setting this to true will trigger an [GeofenceEvent.enter]
  /// event if the user is already inside the geofence.
  final bool initialTrigger;

  const IosGeofenceSettings({
    this.initialTrigger = false,
  });
}

/// Android specific Geofence settings.
class AndroidGeofenceSettings {
  /// Sets the geofence behavior at the moment when the geofences are added.
  /// For example, listing [GeofenceEvent.enter] here will trigger the Geofence
  /// immediately if the user is already inside the geofence.
  final List<GeofenceEvent> initialTriggers;

  /// The geofence will be removed automatically after this period of time.
  /// If you don't set this the geofence will never expire.
  final Duration? expiration;

  /// The delay between [GeofenceEvent.enter] and [GeofenceEvent.dwell].
  /// Only has impact if [GeofenceEvent.dwell] is one of the triggers.
  final Duration loiteringDelay;

  /// The responsiveness of the geofence.
  ///
  /// Defaults to 0. Setting a big responsiveness value, for example 5 minutes,
  /// can save power significantly. However, setting a very small responsiveness
  /// value, for example 5 seconds, doesn't necessarily mean you will get
  /// notified right after the user enters or exits a geofence: internally, the
  /// OS might adjust the responsiveness value to save power when needed.
  final Duration? notificationResponsiveness;

  const AndroidGeofenceSettings({
    required this.initialTriggers,
    this.expiration,
    this.loiteringDelay = const Duration(minutes: 5),
    this.notificationResponsiveness,
  });
}

/// A circular region which represents a geofence.
class Geofence {
  /// The ID associated with the geofence.
  ///
  /// This ID is used to identify the geofence and is required to delete a
  /// specific geofence.
  /// Creating two geofences with the same ID will result in the first geofence
  /// being overwritten.
  final String id;

  /// The location of the geofence.
  final Location location;

  /// The radius, in meters, around [location] that will be considered part of
  /// the geofence.
  final double radiusMeters;

  /// The types of geofence events to listen for.
  ///
  /// Note: [GeofenceEvent.dwell] is not supported on iOS.
  final List<GeofenceEvent> triggers;

  /// iOS specific settings.
  final IosGeofenceSettings iosSettings;

  /// Android specific settings.
  final AndroidGeofenceSettings androidSettings;

  const Geofence({
    required this.id,
    required this.location,
    required this.radiusMeters,
    required this.triggers,
    required this.iosSettings,
    required this.androidSettings,
  });
}

/// A Geofence that is registered and is actively being tracked.
///
/// This type is a subset of [Geofence] and is returned by the plugin/OS GET
/// APIs.
class ActiveGeofence {
  final String id;
  final Location location;
  final double radiusMeters;
  final List<GeofenceEvent> triggers;

  /// Only available on Android.
  ///
  /// The [initialTriggers] field will always be an empty list because Android
  /// does not provide this information when a Geofence triggers.
  final AndroidGeofenceSettings? androidSettings;

  const ActiveGeofence({
    required this.id,
    required this.location,
    required this.radiusMeters,
    required this.triggers,
    required this.androidSettings,
  });
}
