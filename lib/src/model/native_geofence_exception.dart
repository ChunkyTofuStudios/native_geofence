import 'package:native_geofence/src/generated/platform_bindings.g.dart';

/// All exceptions thrown by native_geofence will be of this type.
class NativeGeofenceException implements Exception {
  final NativeGeofenceErrorCode code;
  final String? message;
  final dynamic details;
  final String? stacktrace;

  NativeGeofenceException({
    required this.code,
    this.message,
    this.details,
    this.stacktrace,
  });

  NativeGeofenceException.internal({
    required String this.message,
    this.details,
  })  : code = NativeGeofenceErrorCode.pluginInternal,
        stacktrace = StackTrace.current.toString();

  NativeGeofenceException.invalidArgument({
    required String this.message,
    this.details,
  })  : code = NativeGeofenceErrorCode.invalidArguments,
        stacktrace = StackTrace.current.toString();

  @override
  String toString() =>
      'NativeGeofenceException(${code.name}, message=$message, '
      'details=$details, stacktrace=$stacktrace)';
}
