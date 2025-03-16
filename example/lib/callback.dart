import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:native_geofence/native_geofence.dart';
import 'package:native_geofence_example/notification_service.dart';

@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint('geofenceTriggered params: $params');
  final SendPort? send =
      IsolateNameServer.lookupPortByName('native_geofence_send_port');
  send?.send(params.event.name);

  try {
    final plugin = FlutterLocalNotificationsPlugin();
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
        iOS: DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.active),
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
