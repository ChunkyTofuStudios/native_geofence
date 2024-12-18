import 'package:pigeon/pigeon.dart';

// After modifying this file run:
// dart run pigeon --input pigeons/native_geofence_api.dart && dart format .

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/platform_bindings.g.dart',
  dartPackageName: 'native_geofence',
  swiftOut: 'ios/Classes/Generated/FlutterBindings.g.swift',
  kotlinOut:
      'android/src/main/kotlin/com/chunkytofustudios/native_geofence/generated/FlutterBindings.g.kt',
  kotlinOptions:
      KotlinOptions(package: 'com.chunkytofustudios.native_geofence.generated'),
))

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

class LocationWire {
  final double latitude;
  final double longitude;

  const LocationWire({required this.latitude, required this.longitude});
}

class IosGeofenceSettingsWire {
  final bool initialTrigger;

  const IosGeofenceSettingsWire({
    required this.initialTrigger,
  });
}

class AndroidGeofenceSettingsWire {
  final List<GeofenceEvent> initialTriggers;
  final int? expirationDurationMillis;
  final int loiteringDelayMillis;
  final int? notificationResponsivenessMillis;

  const AndroidGeofenceSettingsWire({
    required this.initialTriggers,
    this.expirationDurationMillis,
    required this.loiteringDelayMillis,
    this.notificationResponsivenessMillis,
  });
}

class GeofenceWire {
  final String id;
  final LocationWire location;
  final double radiusMeters;
  final List<GeofenceEvent> triggers;
  final IosGeofenceSettingsWire iosSettings;
  final AndroidGeofenceSettingsWire androidSettings;
  final int callbackHandle;

  const GeofenceWire({
    required this.id,
    required this.location,
    required this.radiusMeters,
    required this.triggers,
    required this.iosSettings,
    required this.androidSettings,
    required this.callbackHandle,
  });
}

class ActiveGeofenceWire {
  final String id;
  final LocationWire location;
  final double radiusMeters;
  final List<GeofenceEvent> triggers;

  final AndroidGeofenceSettingsWire? androidSettings;

  const ActiveGeofenceWire({
    required this.id,
    required this.location,
    required this.radiusMeters,
    required this.triggers,
    required this.androidSettings,
  });
}

class GeofenceCallbackParamsWire {
  final List<ActiveGeofenceWire> geofences;
  final GeofenceEvent event;
  final LocationWire? location;
  final int callbackHandle;

  const GeofenceCallbackParamsWire({
    required this.geofences,
    required this.event,
    required this.location,
    required this.callbackHandle,
  });
}

/// Errors that can occur when interacting with the native geofence API.
enum NativeGeofenceErrorCode {
  unknown,

  /// A plugin internal error. Please report these as bugs on GitHub.
  pluginInternal,

  /// The arguments passed to the method are invalid.
  invalidArguments,

  /// An error occurred while communicating with the native platform.
  channelError,

  /// The required location permission was not granted.
  ///
  /// On Android we need: `ACCESS_FINE_LOCATION`
  /// On iOS we need: `NSLocationWhenInUseUsageDescription`
  ///
  /// Please use an external permission manager such as "permission_handler" to
  /// request the permission from the user.
  missingLocationPermission,

  /// The required background location permission was not granted.
  ///
  /// On Android we need: `ACCESS_BACKGROUND_LOCATION` (for API level 29+)
  /// On iOS we need: `NSLocationAlwaysAndWhenInUseUsageDescription`
  ///
  /// Please use an external permission manager such as "permission_handler" to
  /// request the permission from the user.
  missingBackgroundLocationPermission,

  /// The geofence deletion failed because the geofence was not found.
  /// This is safe to ignore.
  geofenceNotFound,

  /// The specified geofence callback was not found.
  /// This can happen for old geofence callback functions that were
  /// moved/renamed. Please re-create those geofences.
  callbackNotFound,

  /// The specified geofence callback function signature is invalid.
  /// This can happen if the callback function signature has changed or due to
  /// plugin contract changes.
  callbackInvalid,
}

@HostApi()
abstract class NativeGeofenceApi {
  void initialize({required int callbackDispatcherHandle});

  @async
  void createGeofence({required GeofenceWire geofence});

  void reCreateAfterReboot();

  List<String> getGeofenceIds();

  List<ActiveGeofenceWire> getGeofences();

  @async
  void removeGeofenceById({required String id});

  @async
  void removeAllGeofences();
}

@HostApi()
abstract class NativeGeofenceBackgroundApi {
  void triggerApiInitialized();

  void promoteToForeground();

  void demoteToBackground();
}

@FlutterApi()
abstract class NativeGeofenceTriggerApi {
  @async
  void geofenceTriggered(GeofenceCallbackParamsWire params);
}
