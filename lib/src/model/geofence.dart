import 'package:native_geofence/src/model/android_geofence_settings.dart';
import 'package:native_geofence/src/model/geofence_event.dart';
import 'package:native_geofence/src/model/location.dart';

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

  /// Android specific settings.
  final AndroidGeofenceSettings androidSettings;

  Geofence({
    required this.id,
    required this.location,
    required this.radiusMeters,
    required this.triggers,
    required this.androidSettings,
  });

  @override
  String toString() {
    return 'Geofence(id: $id, location: $location, '
        'radiusMeters: $radiusMeters, triggers: $triggers, '
        'androidSettings: $androidSettings)';
  }
}
