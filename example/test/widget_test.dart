import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:native_geofence_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Fake the native side of the plugin calls made on startup. The
    // notifications plugin isn't available in widget tests either; the app
    // logs that error and carries on.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = StandardMessageCodec();
    const api = 'dev.flutter.pigeon.native_geofence.NativeGeofenceApi';
    messenger.setMockMessageHandler(
      '$api.initialize',
      (_) async => codec.encodeMessage(<Object?>[null]),
    );
    messenger.setMockMessageHandler(
      '$api.getGeofenceIds',
      (_) async => codec.encodeMessage(<Object?>[<String>[]]),
    );
  });

  testWidgets('Renders the geofence form', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Native Geofence'), findsOneWidget);
    expect(find.text('Current state: N/A'), findsOneWidget);
    expect(find.text('Active Geofences: []'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Unregister'), findsOneWidget);
  });
}
