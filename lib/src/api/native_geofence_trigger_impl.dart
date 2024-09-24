import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:native_geofence/src/generated/platform_bindings.g.dart';
import 'package:native_geofence/src/model/native_geofence_exception.dart';

class NativeGeofenceTriggerImpl implements NativeGeofenceTriggerApi {
  NativeGeofenceTriggerImpl() {
    NativeGeofenceTriggerApi.setUp(this);
  }

  @override
  Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
    debugPrint('NativeGeofenceTriggerImpl: geofenceTriggered called.');
    debugPrint('NativeGeofenceTriggerImpl: params=$params');
    final Function? callback = PluginUtilities.getCallbackFromHandle(
        CallbackHandle.fromRawHandle(params.callbackHandle));
    if (callback == null) {
      debugPrint('NativeGeofenceTriggerImpl: callback was null.');
      throw NativeGeofenceException(
          code: NativeGeofenceErrorCode.callbackNotFound);
    }
    debugPrint('NativeGeofenceTriggerImpl: callback calling...');
    await callback(params);
    debugPrint('NativeGeofenceTriggerImpl: callback done.');
  }
}
