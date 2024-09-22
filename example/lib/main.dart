// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:native_geofence/native_geofence.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String geofenceState = 'N/A';
  List<String> registeredGeofences = [];
  double latitude = 50.00187;
  double longitude = 36.23866;
  double radius = 200.0;
  ReceivePort port = ReceivePort();
  final List<GeofenceEvent> triggers = <GeofenceEvent>[
    GeofenceEvent.enter,
    GeofenceEvent.exit
  ];
  final AndroidGeofenceSettings androidSettings = AndroidGeofenceSettings(
    initialTrigger: <GeofenceEvent>[
      GeofenceEvent.enter,
      GeofenceEvent.exit,
    ],
    loiteringDelay: Duration.zero,
    notificationResponsiveness: Duration.zero,
  );

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'native_geofence_send_port',
    );
    port.listen((dynamic data) {
      print('Event: $data');
      setState(() {
        geofenceState = data;
      });
    });
    initPlatformState();
  }

  void registerGeofence() async {
    final firstPermission = await Permission.locationWhenInUse.request();
    final secondPermission = await Permission.locationAlways.request();
    if (firstPermission.isGranted && secondPermission.isGranted) {
      await NativeGeofenceManager.registerGeofence(
        Geofence(
          id: 'mtv',
          location: Location(latitude, longitude),
          radiusMeters: radius,
          triggers: triggers,
          androidSettings: androidSettings,
        ),
        callback,
      );
      final registeredIds =
          await NativeGeofenceManager.getRegisteredGeofenceIds();
      setState(() {
        registeredGeofences = registeredIds;
      });
    }
  }

  void unregisteGeofence() async {
    await NativeGeofenceManager.removeGeofenceById('mtv');
    final registeredIds =
        await NativeGeofenceManager.getRegisteredGeofenceIds();
    setState(() {
      registeredGeofences = registeredIds;
    });
  }

  @pragma('vm:entry-point')
  static void callback(List<String> ids, Location l, GeofenceEvent e) async {
    print('Fences: $ids Location $l Event: $e');
    final SendPort? send =
        IsolateNameServer.lookupPortByName('native_geofence_send_port');
    send?.send(e.toString());
  }

  Future<void> initPlatformState() async {
    print('Initializing...');
    await NativeGeofenceManager.initialize();
    print('Initialization done');
  }

  String numberValidator(String value) {
    final num? a = num.tryParse(value);
    if (a == null) {
      return '"$value" is not a valid number';
    }
    return a.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('CloudAlert Geofencing'),
          ),
          body: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Current state: $geofenceState'),
                    Center(
                      child: TextButton(
                        child: const Text('Register'),
                        onPressed: registerGeofence,
                      ),
                    ),
                    Text('Registered Geofences: $registeredGeofences'),
                    Center(
                      child: TextButton(
                        child: const Text('Unregister'),
                        onPressed: unregisteGeofence,
                      ),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Latitude',
                      ),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: latitude.toString()),
                      onChanged: (String s) {
                        latitude = double.tryParse(s)!;
                      },
                    ),
                    TextField(
                        decoration:
                            const InputDecoration(hintText: 'Longitude'),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(text: longitude.toString()),
                        onChanged: (String s) {
                          longitude = double.tryParse(s)!;
                        }),
                    TextField(
                        decoration: const InputDecoration(hintText: 'Radius'),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(text: radius.toString()),
                        onChanged: (String s) {
                          radius = double.tryParse(s)!;
                        }),
                  ]))),
    );
  }
}
