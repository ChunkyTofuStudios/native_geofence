import 'dart:async';

import 'package:flutter/material.dart';

import 'package:native_geofence/src/api/native_geofence_trigger_impl.dart';
import 'package:native_geofence/src/generated/platform_bindings.g.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Create the NativeGeofenceBackgroundApi so the platform can call us.
  final _backgroundApi = NativeGeofenceBackgroundApi();
  // Setup connection between platform and Flutter.
  WidgetsFlutterBinding.ensureInitialized();
  // Create the NativeGeofenceTriggerApi.
  NativeGeofenceTriggerImpl();
  // Inform platform that NativeGeofenceTriggerApi is ready.
  unawaited(_backgroundApi.triggerApiInitialized());
}
