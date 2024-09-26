import 'dart:async';

import 'package:native_geofence/src/generated/platform_bindings.g.dart';
import 'package:native_geofence/src/model/model_mapper.dart';

class NativeGeofenceBackgroundManager {
  static NativeGeofenceBackgroundManager? _instance;

  /// The singleton instance of [NativeGeofenceBackgroundManager].
  /// WARNING: Can only be accessed within a Geofencing callback.
  static NativeGeofenceBackgroundManager get instance {
    assert(
        _instance != null,
        'NativeGeofenceBackgroundManager has not been initialized yet; '
        'Are you running within a Geofencing callback?');
    return _instance!;
  }

  /// Private constructor internal to plugin, do not use.
  static Future<void> createInstance() async {
    final api = NativeGeofenceBackgroundApi();
    _instance = NativeGeofenceBackgroundManager._(api);
    await api.triggerApiInitialized();
  }

  final NativeGeofenceBackgroundApi _api;

  NativeGeofenceBackgroundManager._(this._api);

  /// Promote the geofencing service to a foreground service.
  ///
  /// Android only, has no effect on iOS (but is safe to call).
  Future<void> promoteToForeground() async => _api
      .promoteToForeground()
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);

  /// Demote the geofencing service from a foreground service to a background
  /// service.
  ///
  /// Android only, has no effect on iOS (but is safe to call).
  Future<void> demoteToBackground() async => _api
      .demoteToBackground()
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);
}
