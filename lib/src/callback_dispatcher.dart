import 'package:flutter/material.dart';

import 'package:native_geofence/src/native_geofence_background_manager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Setup connection between platform and Flutter.
  WidgetsFlutterBinding.ensureInitialized();
  // Create the NativeGeofenceTriggerApi.
  NativeGeofenceBackgroundManager.createInstance();
}
