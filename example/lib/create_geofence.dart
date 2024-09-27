import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:native_geofence/native_geofence.dart';
import 'package:native_geofence_example/callback.dart';

class CreateGeofence extends StatefulWidget {
  @override
  _CreateGeofenceState createState() => _CreateGeofenceState();
}

class _CreateGeofenceState extends State<CreateGeofence> {
  static const Location _timesSquare =
      Location(latitude: 40.75798, longitude: -73.98554);

  List<String> activeGeofences = [];
  late Geofence data;

  @override
  void initState() {
    super.initState();
    data = Geofence(
      id: 'zone1',
      location: _timesSquare,
      radiusMeters: 500,
      triggers: {
        GeofenceEvent.enter,
        GeofenceEvent.exit,
      },
      iosSettings: IosGeofenceSettings(
        initialTrigger: true,
      ),
      androidSettings: AndroidGeofenceSettings(
        initialTriggers: {GeofenceEvent.enter},
      ),
    );
    _updateRegisteredGeofences();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Active Geofences: $activeGeofences'),
        SizedBox(height: 40),
        Form(
          child: Column(
            children: [
              Text('Create/Remove Geofence',
                  style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'ID'),
                initialValue: data.id,
                onChanged: (String value) =>
                    data = data.copyWith(id: () => value),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Latitude'),
                initialValue: data.location.latitude.toString(),
                onChanged: (String value) => data = data.copyWith(
                  location: () =>
                      data.location.copyWith(latitude: double.parse(value)),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Longitude'),
                initialValue: data.location.longitude.toString(),
                onChanged: (String value) => data = data.copyWith(
                  location: () =>
                      data.location.copyWith(longitude: double.parse(value)),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Radius (meters)'),
                initialValue: data.radiusMeters.toString(),
                onChanged: (String value) => data =
                    data.copyWith(radiusMeters: () => double.parse(value)),
              ),
              SizedBox(height: 22),
              ElevatedButton(
                onPressed: () async {
                  if (!await _checkPermissions()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lacking permissions!')),
                    );
                    return;
                  }
                  await NativeGeofenceManager.instance
                      .createGeofence(data, geofenceTriggered);
                  debugPrint('Geofence created: ${data.id}');
                  await _updateRegisteredGeofences();
                  await Future.delayed(const Duration(seconds: 1));
                  await _updateRegisteredGeofences();
                },
                child: const Text('Register'),
              ),
              SizedBox(height: 22),
              ElevatedButton(
                onPressed: () async {
                  await NativeGeofenceManager.instance.removeGeofence(data);
                  debugPrint('Geofence removed: ${data.id}');
                  await _updateRegisteredGeofences();
                  await Future.delayed(const Duration(seconds: 1));
                  await _updateRegisteredGeofences();
                },
                child: const Text('Unregister'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateRegisteredGeofences() async {
    final List<String> geofences =
        await NativeGeofenceManager.instance.getRegisteredGeofenceIds();
    setState(() {
      activeGeofences = geofences;
    });
    debugPrint('Active geofences updated.');
  }
}

Future<bool> _checkPermissions() async {
  final locationPerm = await Permission.location.request();
  final backgroundLocationPerm = await Permission.locationAlways.request();
  final notificationPerm = await Permission.notification.request();
  return locationPerm.isGranted &&
      backgroundLocationPerm.isGranted &&
      notificationPerm.isGranted;
}

extension ModifyGeofence on Geofence {
  Geofence copyWith({
    String Function()? id,
    Location Function()? location,
    double Function()? radiusMeters,
    Set<GeofenceEvent> Function()? triggers,
    IosGeofenceSettings Function()? iosSettings,
    AndroidGeofenceSettings Function()? androidSettings,
  }) {
    return Geofence(
      id: id?.call() ?? this.id,
      location: location?.call() ?? this.location,
      radiusMeters: radiusMeters?.call() ?? this.radiusMeters,
      triggers: triggers?.call() ?? this.triggers,
      iosSettings: iosSettings?.call() ?? this.iosSettings,
      androidSettings: androidSettings?.call() ?? this.androidSettings,
    );
  }
}

extension ModifyLocation on Location {
  Location copyWith({
    double? latitude,
    double? longitude,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

extension ModifyAndroidGeofenceSettings on AndroidGeofenceSettings {
  AndroidGeofenceSettings copyWith({
    Set<GeofenceEvent> Function()? initialTrigger,
    Duration Function()? expiration,
    Duration Function()? loiteringDelay,
    Duration Function()? notificationResponsiveness,
  }) {
    return AndroidGeofenceSettings(
      initialTriggers: initialTrigger?.call() ?? this.initialTriggers,
      expiration: expiration?.call() ?? this.expiration,
      loiteringDelay: loiteringDelay?.call() ?? this.loiteringDelay,
      notificationResponsiveness:
          notificationResponsiveness?.call() ?? this.notificationResponsiveness,
    );
  }
}
