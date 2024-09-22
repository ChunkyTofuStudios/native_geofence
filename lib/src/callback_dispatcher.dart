import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:native_geofence/src/model/converters/geofence_event_mapper.dart';
import 'package:native_geofence/src/model/converters/location_mapper.dart';
import 'package:native_geofence/src/model/geofence_event.dart';
import 'package:native_geofence/src/model/location.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  const MethodChannel _backgroundChannel = MethodChannel(
      'native_geofence.chunkytofustudios.com/native_geofence_plugin_background');
  WidgetsFlutterBinding.ensureInitialized();

  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    final List<dynamic> args = call.arguments;
    final Function? callback = PluginUtilities.getCallbackFromHandle(
        CallbackHandle.fromRawHandle(args[0]));
    assert(callback != null);
    final List<String> triggeringGeofences = args[1].cast<String>();
    final List<double> locationList = <double>[];
    // 0.0 becomes 0 somewhere during the method call, resulting in wrong
    // runtime type (int instead of double). This is a simple way to get
    // around casting in another complicated manner.
    args[2]
        .forEach((dynamic e) => locationList.add(double.parse(e.toString())));
    final Location triggeringLocation = LocationMapper.fromList(locationList);
    final GeofenceEvent event = GeofenceEventMapper.fromId(args[3]);
    callback?.call(triggeringGeofences, triggeringLocation, event);
  });
  _backgroundChannel.invokeMethod('NativeGeofenceService.initialized');
}
