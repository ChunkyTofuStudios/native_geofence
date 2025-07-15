import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:native_geofence/native_geofence.dart';
import 'package:native_geofence_example/notifications_repository.dart';

@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint('geofenceTriggered params: $params');
  final SendPort? send =
      IsolateNameServer.lookupPortByName('native_geofence_send_port');
  send?.send(params.event.name);

  final notificationsRepository = NotificationsRepository();
  // TODO: Test to see what happens if we do not initialize the Notifications
  // plugin during callbacks.
  await notificationsRepository.init();

  final title =
      'Geofence ${capitalize(params.event.name)}: ${params.geofences.map((e) => e.id).join(', ')}';
  final message = 'Geofences:\n'
      '${params.geofences.map((e) => '• ID: ${e.id}, '
          'Radius=${e.radiusMeters.toStringAsFixed(0)}m, '
          'Triggers=${e.triggers.map((e) => e.name).join(',')}').join('\n')}\n'
      'Event: ${params.event.name}\n'
      'Location: ${params.location?.latitude.toStringAsFixed(5)}, '
      '${params.location?.longitude.toStringAsFixed(5)}';
  await notificationsRepository.showGeofenceTriggerNotification(title, message);

  await Future.delayed(const Duration(seconds: 1));
}

String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
