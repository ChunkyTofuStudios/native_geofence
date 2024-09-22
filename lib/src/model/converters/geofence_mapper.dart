import 'dart:io';

import 'package:native_geofence/src/model/converters/android_geofence_settings_mapper.dart';
import 'package:native_geofence/src/model/converters/geofence_event_mapper.dart';
import 'package:native_geofence/src/model/geofence.dart';
import 'package:native_geofence/src/model/geofence_event.dart';

extension GeofenceMapper on Geofence {
  List<dynamic> toArgs() {
    final int triggerMask =
        triggers.fold(0, (int trigger, GeofenceEvent e) => (e.id | trigger));
    final List<dynamic> args = <dynamic>[
      id,
      location.latitude,
      location.longitude,
      radiusMeters,
      triggerMask
    ];
    if (Platform.isAndroid) {
      args.addAll(androidSettings.toArgs());
    }
    return args;
  }
}
