import 'package:native_geofence/src/native_geofence.dart';

// Internal.
List<dynamic> platformSettingsToArgs(AndroidGeofenceSettings s) => s._toArgs();

class AndroidGeofenceSettings {
  List<GeofenceEvent> initialTrigger;
  int expirationDuration;
  int loiteringDelay;
  int notificationResponsiveness;

  AndroidGeofenceSettings(
      {this.initialTrigger = const <GeofenceEvent>[GeofenceEvent.enter],
      this.loiteringDelay = 0,
      this.expirationDuration = -1,
      this.notificationResponsiveness = 0});

  List<dynamic> _toArgs() {
    final int initTriggerMask = initialTrigger.fold(
        0, (int trigger, GeofenceEvent e) => (geofenceEventToInt(e) | trigger));
    return <dynamic>[
      initTriggerMask,
      expirationDuration,
      loiteringDelay,
      notificationResponsiveness
    ];
  }
}
