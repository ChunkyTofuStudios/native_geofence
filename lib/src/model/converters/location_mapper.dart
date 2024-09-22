import 'package:native_geofence/src/model/location.dart';

extension LocationMapper on Location {
  static Location fromList(List<double> l) {
    assert(l.length == 2);
    return Location(latitude: l[0], longitude: l[1]);
  }
}
