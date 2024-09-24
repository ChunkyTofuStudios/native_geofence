import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:native_geofence/native_geofence.dart';

@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint(
      'Fences: ${params.geofences} Location ${params.location} Event: ${params.event}');
  final SendPort? send =
      IsolateNameServer.lookupPortByName('native_geofence_send_port');
  send?.send(params.event.name);

  try {
    final plugin = FlutterLocalNotificationsPlugin();
    if (!(await plugin.initialize(InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        )) ??
        false)) {
      debugPrint('Failed to initialize notifications plugin.');
      return;
    }
    final message = 'Geofences:\n'
        '${params.geofences.map((e) => '• ID: ${e.id}, '
            'Radius=${e.radiusMeters.toStringAsFixed(0)}m, '
            'Triggers=${e.triggers.map((e) => e.name).join(',')}').join('\n')}\n'
        'Event: ${params.event.name}\n'
        'Location: ${params.location?.latitude.toStringAsFixed(5)}, '
        '${params.location?.longitude.toStringAsFixed(5)}';
    await plugin.show(
      Random().nextInt(100000),
      'Geofence ${capitalize(params.event.name)}: ${params.geofences.map((e) => e.id).join(', ')}',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'geofence_triggers',
          'Geofence Triggers',
          styleInformation: BigTextStyleInformation(message),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'item x',
    );
    debugPrint('Notification sent.');
  } catch (e, s) {
    debugPrint('Failed to send notification: $e');
    debugPrintStack(stackTrace: s);
  }

  await Future.delayed(Duration(seconds: 1));
}

String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
