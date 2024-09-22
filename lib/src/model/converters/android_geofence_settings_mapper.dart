import 'package:native_geofence/src/model/android_geofence_settings.dart';
import 'package:native_geofence/src/model/converters/geofence_event_mapper.dart';
import 'package:native_geofence/src/model/geofence_event.dart';

extension AndroidGeofenceSettingsMapper on AndroidGeofenceSettings {
  List<dynamic> toArgs() {
    final int initTriggerMask = initialTrigger.fold(
        0, (int trigger, GeofenceEvent e) => (e.id | trigger));
    return <dynamic>[
      initTriggerMask,
      expiration?.inMilliseconds,
      loiteringDelay.inMilliseconds,
      notificationResponsiveness?.inMilliseconds,
    ];
  }
}
