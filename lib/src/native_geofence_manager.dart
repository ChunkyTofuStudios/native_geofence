import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:native_geofence/src/callback.dart';
import 'package:native_geofence/src/callback_dispatcher.dart';
import 'package:native_geofence/src/model/converters/geofence_mapper.dart';
import 'package:native_geofence/src/model/geofence.dart';
import 'package:native_geofence/src/model/geofence_event.dart';

class NativeGeofenceManager {
  static const MethodChannel _channel = MethodChannel(
      'native_geofence.chunkytofustudios.com/native_geofence_plugin');
  static const MethodChannel _background = MethodChannel(
      'native_geofence.chunkytofustudios.com/native_geofence_plugin_background');

  /// Initialize the plugin.
  static Future<void> initialize() async {
    final CallbackHandle? callback =
        PluginUtilities.getCallbackHandle(callbackDispatcher);
    if (callback != null) {
      await _channel.invokeMethod('NativeGeofencePlugin.initializeService',
          <dynamic>[callback.toRawHandle()]);
    }
  }

  /// Register for geofence events for a [Geofence].
  ///
  /// [region] is the geofence region to register with the system.
  /// [callback] is the method to be called when a geofence event associated
  /// with [region] occurs.
  static Future<void> registerGeofence(
      Geofence region, GeofenceCallback callback) async {
    if (region.triggers.isEmpty) {
      throw ArgumentError('Geofence triggers cannot be empty.');
    }
    if (Platform.isIOS &&
        region.triggers.length == 1 &&
        region.triggers[0] == GeofenceEvent.dwell) {
      throw UnsupportedError("iOS does not support 'GeofenceEvent.dwell'.");
    }
    final callbackHandle = PluginUtilities.getCallbackHandle(callback);
    if (callbackHandle == null) {
      throw ArgumentError('Callback is isvalid.');
    }
    final List<dynamic> args = <dynamic>[callbackHandle.toRawHandle()];
    args.addAll(region.toArgs());
    await _channel.invokeMethod('NativeGeofencePlugin.registerGeofence', args);
  }

  /// Re-register geofences after reboot.
  ///
  /// This function can be called when the autostart feature is not working as
  /// it should. This way you can handle that case from the app.
  static Future<void> reRegisterAfterReboot() async =>
      await _channel.invokeMethod('NativeGeofencePlugin.reRegisterAfterReboot');

  /// Get all geofence identifiers.
  static Future<List<String>> getRegisteredGeofenceIds() async =>
      List<String>.from(await _channel
          .invokeMethod('NativeGeofencePlugin.getRegisteredGeofenceIds'));

  /// Get all geofence regions and their properties.
  /// Returns a [Map] with the following keys.
  /// [id] the identifier
  /// [lat] latitude
  /// [long] longitude
  /// [radius] radius
  ///
  /// If there are no geofences registered it returns [].
  static Future<List<Map<dynamic, dynamic>>>
      getRegisteredGeofenceRegions() async =>
          List<Map<dynamic, dynamic>>.from(await _channel.invokeMethod(
              'NativeGeofencePlugin.getRegisteredGeofenceRegions'));

  /// Promote the geofencing service to a foreground service.
  ///
  /// Will throw an exception if called anywhere except for a geofencing
  /// callback.
  static Future<void> promoteToForeground() async => await _background
      .invokeMethod('NativeGeofenceService.promoteToForeground');

  /// Demote the geofencing service from a foreground service to a background
  /// service.
  ///
  /// Will throw an exception if called anywhere except for a geofencing
  /// callback.
  static Future<void> demoteToBackground() async => await _background
      .invokeMethod('NativeGeofenceService.demoteToBackground');

  /// Stop receiving geofence events for a given [Geofence].
  static Future<bool> removeGeofence(Geofence region) async =>
      await removeGeofenceById(region.id);

  /// Stop receiving geofence events for an identifier associated with a
  /// geofence region.
  static Future<bool> removeGeofenceById(String id) async => await _channel
      .invokeMethod('NativeGeofencePlugin.removeGeofence', <dynamic>[id]);

  /// Stop receiving geofence events for all registered geofences.
  static Future<bool> removeAllGeofences() async =>
      await _channel.invokeMethod('NativeGeofencePlugin.removeAllGeofences');
}
