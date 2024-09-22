import 'dart:isolate';
import 'dart:ui';

import 'package:native_geofence/native_geofence.dart';

@pragma('vm:entry-point')
void geofenceTriggered(
    List<String> ids, Location location, GeofenceEvent event) async {
  print('Fences: $ids Location $location Event: $event');
  final SendPort? send =
      IsolateNameServer.lookupPortByName('native_geofence_send_port');
  send?.send(event.name);
}
