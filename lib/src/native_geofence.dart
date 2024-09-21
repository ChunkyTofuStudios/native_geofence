import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:native_geofence/src/callback_dispatcher.dart';
import 'package:native_geofence/src/location.dart';
import 'package:native_geofence/src/platform_settings.dart';

const int _kEnterEvent = 1;
const int _kExitEvent = 2;
const int _kDwellEvent = 4;

/// Valid geofencing events.
///
/// Note: `GeofenceEvent.dwell` is not supported on iOS.
enum GeofenceEvent { enter, exit, dwell }

// Internal.
int geofenceEventToInt(GeofenceEvent e) {
  switch (e) {
    case GeofenceEvent.enter:
      return _kEnterEvent;
    case GeofenceEvent.exit:
      return _kExitEvent;
    case GeofenceEvent.dwell:
      return _kDwellEvent;
    default:
      throw UnimplementedError();
  }
}

// Internal.
GeofenceEvent intToGeofenceEvent(int e) {
  switch (e) {
    case _kEnterEvent:
      return GeofenceEvent.enter;
    case _kExitEvent:
      return GeofenceEvent.exit;
    case _kDwellEvent:
      return GeofenceEvent.dwell;
    default:
      throw UnimplementedError();
  }
}

/// A circular region which represents a geofence.
class GeofenceRegion {
  /// The ID associated with the geofence.
  ///
  /// This ID is used to identify the geofence and is required to delete a
  /// specific geofence.
  final String id;

  /// The location of the geofence.
  final Location location;

  /// The radius around `location` that will be considered part of the geofence.
  final double radius;

  /// The types of geofence events to listen for.
  ///
  /// Note: `GeofenceEvent.dwell` is not supported on iOS.
  final List<GeofenceEvent> triggers;

  /// Android specific settings for a geofence.
  final AndroidGeofenceSettings androidSettings;

  GeofenceRegion(
    this.id,
    double latitude,
    double longitude,
    this.radius,
    this.triggers,
    this.androidSettings,
  ) : location = Location(latitude, longitude);

  List<dynamic> _toArgs() {
    final int triggerMask = triggers.fold(
        0, (int trigger, GeofenceEvent e) => (geofenceEventToInt(e) | trigger));
    final List<dynamic> args = <dynamic>[
      id,
      location.latitude,
      location.longitude,
      radius,
      triggerMask
    ];
    if (Platform.isAndroid) {
      args.addAll(platformSettingsToArgs(androidSettings));
    }
    return args;
  }
}

class GeofencingManager {
  static const MethodChannel _channel = MethodChannel(
      'native_geofence.chunkytofustudios.com/native_geofence_plugin');
  static const MethodChannel _background = MethodChannel(
      'native_geofence.chunkytofustudios.com/native_geofence_plugin_background');

  /// Initialize the plugin and request relevant permissions from the user.
  static Future<void> initialize() async {
    final CallbackHandle? callback =
        PluginUtilities.getCallbackHandle(callbackDispatcher);
    if (callback != null) {
      await _channel.invokeMethod('NativeGeofencePlugin.initializeService',
          <dynamic>[callback.toRawHandle()]);
    }
  }

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

  /// Register for geofence events for a [GeofenceRegion].
  ///
  /// `region` is the geofence region to register with the system.
  /// `callback` is the method to be called when a geofence event associated
  /// with `region` occurs.
  ///
  /// Note: `GeofenceEvent.dwell` is not supported on iOS. If the
  /// `GeofenceRegion` provided only requests notifications for a
  /// `GeofenceEvent.dwell` trigger on iOS, `UnsupportedError` is thrown.
  static Future<void> registerGeofence(
      GeofenceRegion region,
      void Function(List<String> id, Location location, GeofenceEvent event)
          callback) async {
    if (Platform.isIOS &&
        region.triggers.contains(GeofenceEvent.dwell) &&
        (region.triggers.length == 1)) {
      throw UnsupportedError("iOS does not support 'GeofenceEvent.dwell'");
    }
    final List<dynamic> args = <dynamic>[
      PluginUtilities.getCallbackHandle(callback)!.toRawHandle()
    ];
    args.addAll(region._toArgs());
    await _channel.invokeMethod('NativeGeofencePlugin.registerGeofence', args);
  }

  /// reRegister geofences after reboot.
  /// This function can be called when the autostart feature is not working
  /// as it should. This way you can handle that case from the app.
  static Future<void> reRegisterAfterReboot() async =>
      await _channel.invokeMethod('NativeGeofencePlugin.reRegisterAfterReboot');

  /// get all geofence identifiers
  static Future<List<String>> getRegisteredGeofenceIds() async =>
      List<String>.from(await _channel
          .invokeMethod('NativeGeofencePlugin.getRegisteredGeofenceIds'));

  /// get all geofence regions and their properties
  /// returns a [Map] with the following keys
  /// [id] the identifier
  /// [lat] latitude
  /// [long] longitude
  /// [radius] radius
  ///
  /// if there are no geofences registered it returns []
  static Future<List<Map<dynamic, dynamic>>>
      getRegisteredGeofenceRegions() async =>
          List<Map<dynamic, dynamic>>.from(await _channel.invokeMethod(
              'NativeGeofencePlugin.getRegisteredGeofenceRegions'));

  /// Stop receiving geofence events for a given [GeofenceRegion].
  static Future<bool> removeGeofence(GeofenceRegion region) async =>
      await removeGeofenceById(region.id);

  /// Stop receiving geofence events for an identifier associated with a
  /// geofence region.
  static Future<bool> removeGeofenceById(String id) async => await _channel
      .invokeMethod('NativeGeofencePlugin.removeGeofence', <dynamic>[id]);
}
