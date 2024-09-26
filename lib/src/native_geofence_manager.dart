import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:native_geofence/src/callback_dispatcher.dart';
import 'package:native_geofence/src/generated/platform_bindings.g.dart';
import 'package:native_geofence/src/model/model.dart';
import 'package:native_geofence/src/model/model_mapper.dart';
import 'package:native_geofence/src/model/native_geofence_exception.dart';
import 'package:native_geofence/src/typedefs.dart';

class NativeGeofenceManager {
  /// Cached instance of [NativeGeofenceManager]
  static NativeGeofenceManager? _instance;

  static NativeGeofenceManager get instance {
    _instance ??= NativeGeofenceManager._();
    return _instance!;
  }

  final NativeGeofenceApi _api;

  NativeGeofenceManager._() : _api = NativeGeofenceApi();

  /// Initialize the plugin.
  Future<void> initialize() async {
    final CallbackHandle? callback =
        PluginUtilities.getCallbackHandle(callbackDispatcher);
    if (callback == null) {
      throw NativeGeofenceException.internal(
          message: 'Callback dispatcher is invalid.');
    }
    return _api
        .initialize(callbackDispatcherHandle: callback.toRawHandle())
        .catchError(NativeGeofenceExceptionMapper.catchError<void>);
  }

  /// Register for geofence events for a [Geofence].
  ///
  /// [region] is the geofence region to register with the system.
  /// [callback] is the method to be called when a geofence event associated
  /// with [region] occurs.
  Future<void> createGeofence(
      Geofence geofence, GeofenceCallback callback) async {
    if (geofence.triggers.isEmpty) {
      throw NativeGeofenceException.invalidArgument(
          message: 'Geofence triggers cannot be empty.');
    }
    if (Platform.isIOS &&
        geofence.triggers.length == 1 &&
        geofence.triggers[0] == GeofenceEvent.dwell) {
      throw NativeGeofenceException.invalidArgument(
          message: 'iOS does not support "GeofenceEvent.dwell".');
    }
    final callbackHandle = PluginUtilities.getCallbackHandle(callback);
    if (callbackHandle == null) {
      throw NativeGeofenceException.invalidArgument(
          message: 'Callback is invalid.');
    }
    return _api
        .createGeofence(geofence: geofence.toWire(callbackHandle.toRawHandle()))
        .catchError(NativeGeofenceExceptionMapper.catchError<void>);
  }

  /// Re-register geofences after reboot.
  ///
  /// This function can be called when the autostart feature is not working as
  /// it should. This way you can handle that case from the app.
  Future<void> reCreateAfterReboot() async => _api
      .reCreateAfterReboot()
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);

  /// Get all registered [Geofence] IDs.
  ///
  /// If there are no geofences registered it returns an empty list.
  Future<List<String>> getRegisteredGeofenceIds() async => _api
      .getGeofenceIds()
      .catchError(NativeGeofenceExceptionMapper.catchError<List<String>>);

  /// Get all [Geofence] regions and their properties.
  ///
  /// If there are no geofences registered it returns an empty list.
  Future<List<ActiveGeofence>> getRegisteredGeofences() async => _api
      .getGeofences()
      .then((value) => value.map((e) => e.fromWire()).toList())
      .catchError(NativeGeofenceExceptionMapper.catchError<List<Geofence>>);

  /// Stop receiving geofence events for a given [Geofence].
  Future<void> removeGeofence(Geofence region) async =>
      removeGeofenceById(region.id);

  /// Stop receiving geofence events for an identifier associated with a
  /// geofence region.
  Future<void> removeGeofenceById(String id) async => _api
      .removeGeofenceById(id: id)
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);

  /// Stop receiving geofence events for all registered geofences.
  Future<void> removeAllGeofences() async => _api
      .removeAllGeofences()
      .catchError(NativeGeofenceExceptionMapper.catchError<void>);
}
