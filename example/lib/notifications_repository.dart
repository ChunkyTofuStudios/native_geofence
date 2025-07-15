import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsRepository {
  final _plugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return; // prevent re-initialization

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOs =
        DarwinInitializationSettings(defaultPresentBanner: false);

    try {
      final success = await _plugin.initialize(InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsIOs,
      ));
      if (success != true) {
        debugPrint('Failed to initialize notifications plugin.');
      }
    } catch (e, s) {
      debugPrint(
          'Error while initializing notifications plugin: ${e.toString()}');
      debugPrintStack(stackTrace: s);
    }

    _isInitialized = true;
  }

  Future<void> showGeofenceTriggerNotification(
      String title, String message) async {
    if (!_isInitialized) {
      debugPrint('Notifications plugin is not initialized.');
      return;
    }

    try {
      await _plugin.show(
        Random().nextInt(100000),
        title,
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
      debugPrint('Failed to send notification: ${e.toString()}');
      debugPrintStack(stackTrace: s);
    }
  }
}
