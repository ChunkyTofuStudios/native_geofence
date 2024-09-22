import 'package:native_geofence/src/model/geofence_event.dart';

extension GeofenceEventMapper on GeofenceEvent {
  int get id {
    switch (this) {
      case GeofenceEvent.enter:
        return 1;
      case GeofenceEvent.exit:
        return 2;
      case GeofenceEvent.dwell:
        return 4;
    }
  }

  static GeofenceEvent fromId(int id) {
    switch (id) {
      case 1:
        return GeofenceEvent.enter;
      case 2:
        return GeofenceEvent.exit;
      case 4:
        return GeofenceEvent.dwell;
      default:
        throw UnimplementedError();
    }
  }
}
