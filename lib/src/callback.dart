import 'package:native_geofence/src/model/geofence_event.dart';
import 'package:native_geofence/src/model/location.dart';

typedef GeofenceCallback = void Function(
    List<String> id, Location location, GeofenceEvent event);
