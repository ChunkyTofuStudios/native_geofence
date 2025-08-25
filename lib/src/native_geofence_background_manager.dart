import 'dart:async';

import 'package:native_geofence/src/generated/platform_bindings.g.dart';
import 'package:native_geofence/src/model/model_mapper.dart';
import 'package:native_geofence/src/model/native_geofence_exception.dart';

class NativeGeofenceBackgroundManager {
  static NativeGeofenceBackgroundManager? _instance;

  /// The singleton instance of [NativeGeofenceBackgroundManager].
  ///
  /// WARNING: Can only be accessed within Geofence callbacks. Trying to access
  /// this anywhere else will throw an [AssertionError].
  static NativeGeofenceBackgroundManager get instance {
    assert(
        _instance != null,
        'NativeGeofenceBackgroundManager has not been initialized yet; '
        'Are you running within a Geofence callback?');
    return _instance!;
  }

  final NativeGeofenceBackgroundApi _api;

  NativeGeofenceBackgroundManager._(this._api);

  /// Promote the geofence callback to an Android foreground service.
  ///
  /// Android only, has no effect on iOS (but is safe to call).
  ///
  /// Throws [NativeGeofenceException].
  Future<void> promoteToForeground() async => _api
      .promoteToForeground()
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);

  /// Demote the geofence service from an Android foreground service to a
  /// background service.
  ///
  /// Android only, has no effect on iOS (but is safe to call).
  ///
  /// Throws [NativeGeofenceException].
  Future<void> demoteToBackground() async => _api
      .demoteToBackground()
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);

  /// Signal that processing of the current geofence event is complete.
  /// iOS only
  Future<void> processingComplete() async => _api
      .processingComplete()
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);
}

/// Private method internal to plugin, do not use.
Future<void> createNativeGeofenceBackgroundManagerInstance() async {
  final api = NativeGeofenceBackgroundApi();
  NativeGeofenceBackgroundManager._instance =
      NativeGeofenceBackgroundManager._(api);
  await api.triggerApiInitialized();
}
