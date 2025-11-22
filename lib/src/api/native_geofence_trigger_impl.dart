import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:native_geofence/src/generated/platform_bindings.g.dart';
import 'package:native_geofence/src/model/model_mapper.dart';
import 'package:native_geofence/src/model/native_geofence_exception.dart';
import 'package:native_geofence/src/typedefs.dart';

class NativeGeofenceTriggerImpl implements NativeGeofenceTriggerApi {
  /// Cached instance of [NativeGeofenceTriggerImpl]
  static NativeGeofenceTriggerImpl? _instance;

  static void ensureInitialized() {
    _instance ??= NativeGeofenceTriggerImpl._();
  }

  NativeGeofenceTriggerImpl._() {
    NativeGeofenceTriggerApi.setUp(this);
  }

  @override
  Future<void> geofenceTriggered(GeofenceCallbackParamsWire params) async {
    final Function? callback = PluginUtilities.getCallbackFromHandle(
        CallbackHandle.fromRawHandle(params.callbackHandle));
    if (callback == null) {
      throw NativeGeofenceException(
          code: NativeGeofenceErrorCode.callbackNotFound);
    }
    if (callback is! GeofenceCallback) {
      throw NativeGeofenceException(
          code: NativeGeofenceErrorCode.callbackInvalid,
          message: 'Invalid callback type: ${callback.runtimeType.toString()}',
          details: 'Expected: GeofenceCallback');
    }
    await callback(params.fromWire());
    debugPrint('Geofence trigger callback completed.');
  }
}
