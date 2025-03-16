import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  int randomId = Random().nextInt(1000);

  // Initialization
  Future<void> initNotification() async {
    if (_isInitialized) return; // prevent re-initialization

    // prepare android initialization
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    const initSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // prepare iOS initialization
    const initSettingsIOs = DarwinInitializationSettings(
        defaultPresentBanner: false
    );

    // init settings
    const initializationSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOs,
    );

    // finally initialize the plugin
    await notificationPlugin.initialize(initializationSettings);
  }

  // Notification Detail Setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
          'Geofence Triggered',
          'Daily Notification',
          channelDescription: 'Geofence Event Triggered',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          // IMPORTANT : add this icon declaration for notification initialization safety :)
          icon: '@mipmap/ic_launcher'
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

}