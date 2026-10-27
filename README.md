# Native Geofence

Battery efficient Flutter geofencing plugin that uses native iOS and Android APIs.

<dl>
  <dt><b>What is geofencing?</b></dt>
  <dd>A way for your app to be alerted when the user enters or exits a geographical region. You might use geofences to perform location-related tasks. For example, to setup reminders when the user leaves their house.</dd>
  <dt><b>What are the plugin requirements?</b></dt>
  <dd>iOS 14+ and Android API 24+. You will also need to obtain background location permission from the user.</dd>
</dl>

## Features

* Uses [CLLocationManager](https://developer.apple.com/documentation/corelocation/cllocationmanager) on iOS and [GeofencingClient](https://developer.android.com/develop/sensors-and-location/location/geofencing) on Android
* Create geofences
* Be notified of enter/exit/dwell events
* Works when the application is:
  * In the foreground
  * In the background
  * Terminated
* Geofences are re-registered after device reboot
* Fetch currently registered geofences
* [Android] Run foreground service to handle geofence event

## How it works

Step through the [lifecycle walkthrough](https://chunkytofustudios.github.io/native_geofence/doc/lifecycle_simple.html) to see how a geofence wakes your app on iOS and Android.

## Setup

<details>
<summary>Android</summary>

### Android

1. Kotlin setup

This plugin requires Flutter 3.44+. Follow the setup that matches your app's Android Gradle Plugin (AGP) version:

- **AGP 9:** there is nothing to add, and do **not** apply the `kotlin-android` Gradle plugin in your app module. Flutter applies Kotlin itself while `android.builtInKotlin=false` (Flutter's default), and AGP provides it once built-in Kotlin is enabled, which requires Flutter 3.47+. See Flutter's [built-in Kotlin migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin).
- **AGP 8:** use the Kotlin Gradle plugin as usual, declared in your `settings.gradle` with Kotlin `2.2.0` or later (see this [guide](https://docs.flutter.dev/release/breaking-changes/kotlin-version)). Add-to-app host apps must declare it too. The latest Kotlin version can be found [here](https://mvnrepository.com/artifact/org.jetbrains.kotlin.android/org.jetbrains.kotlin.android.gradle.plugin).

The [example app](https://github.com/ChunkyTofuStudios/native_geofence/tree/main/example/android) demonstrates the AGP 8 setup, with comments in its Gradle files noting the AGP 9 difference.

NOTE: You may also need Gradle 8+ to use this plugin. See this [issue](https://github.com/ChunkyTofuStudios/native_geofence/issues/4).

2. Set your `minSdkVersion` to `24` or above.

*Explanation: If you need to support prior Android builds it might be possible to accommodate this. Please send a PR or file a bug.*

See the [example plugin](https://github.com/ChunkyTofuStudios/native_geofence/blob/main/example/android/app/src/main/AndroidManifest.xml) for a full demonstration.

3. In your `AndroidManifest.xml` add the following lines right before `</application>`:

```xml
<!-- Used by plugin: native_geofence -->
<receiver android:name="com.chunkytofustudios.native_geofence.receivers.NativeGeofenceBroadcastReceiver"
          android:exported="true"/>
<receiver android:name="com.chunkytofustudios.native_geofence.receivers.NativeGeofenceRebootBroadcastReceiver"
          android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"></action>
    </intent-filter>
</receiver>
<service android:name="com.chunkytofustudios.native_geofence.NativeGeofenceForegroundService"
          android:foregroundServiceType="location"
          android:permission="android.permission.BIND_JOB_SERVICE" android:exported="true"/>
```

*Explanation: The `NativeGeofenceBroadcastReceiver` is used to listen for geofence events the Android OS sends. The `NativeGeofenceRebootBroadcastReceiver` runs after device reboot and re-registers geofences (this is required since Android doesn't retain them). Finally, `NativeGeofenceForegroundService` is utilized when you want to run a foreground service when handling a geofence callback. Its `foregroundServiceType` is required on Android 14+ (see [Foreground work](#android-only-foreground-work)).*

4. In the same file declare the neccesary permissions before the `<application ...` line:

```xml
<!-- Used by plugin: native_geofence -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
```

*Explanation: The coarse and fine locations are required to create a geofence. The background location permission is [also required](https://developer.android.com/develop/sensors-and-location/location/geofencing#RequestGeofences) for geofence creation on Android API level 29+. The boot completed permission is required to re-register geofences after reboot. The wake lock and foreground service permissions are only required if you need to run foreground services to respond to geofence events.*

5. Optional: Disable battery optimization

If you want to perform any heavy work when a Geofence triggers (within the Geofence callback), such as calling a backend API, you will need to ask the user to disable battery optimization for your app.

You can do so by using the [disable_battery_optimization package](https://pub.dev/packages/disable_battery_optimization). You can find a code sample [here](https://gist.github.com/orkun1675/5803f43f897b22365651bdf9561ca4f4).

</details>

<details>
<summary>iOS</summary>
 
### iOS

1. Migrate your app to Swift

If your app is using Objective-C you will need to migrate to Swift. [Here is a guide](https://medium.com/@serge_shkurko/50-shades-of-pain-or-how-to-migrate-a-flutter-project-from-objective-c-to-swift-76ada31ab0e3) you can follow.

2. In your `Info.plist` add the following key-value pairs:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>USER_VISIBLE_STRING__DESCRIBE_HOW_YOUR_APP_USES_LOCATION.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>USER_VISIBLE_STRING__DESCRIBE_HOW_YOUR_APP_USES_BACKGROUND_LOCATION.</string>
```

*Explanation: The in-use location permission is required to create geofences. The always location permission is [required](https://dwirandyh.medium.com/deep-dive-into-core-location-in-ios-geofencing-region-monitoring-7846802c968e) if you want to be notified of geofence events when your app isn't running.*

3. Update your AppDelegate to call `NativeGeofencePlugin`:

<details>
<summary>Swift</summary>

#### Swift

In your `AppDelegate.swift` file import the plugin:

```swift
import native_geofence
```

and add the following near the top of the `application(_:didFinishLaunchingWithOptions:)` function:

```swift
// Used by plugin: native_geofence
NativeGeofencePlugin.setPluginRegistrantCallback { registry in
    GeneratedPluginRegistrant.register(with: registry)
}
```

Keep this call there even if your app uses the [UIScene life cycle](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate), don't move it to `didInitializeImplicitFlutterEngine(_:)`.

*Explanation: A geofence event can launch your app in the background without a UI scene, in which case `didInitializeImplicitFlutterEngine(_:)` isn't called.*

</details>

<details>
<summary>Objective-C</summary>

#### Objective-C

In your `AppDelegate.m` file import the plugin and define the `registerPlugins` function:

```objc
@import native_geofence;

void registerPlugins(NSObject<FlutterPluginRegistry>* registry) {
  [GeneratedPluginRegistrant registerWithRegistry:registry];
}
```

and add the following within the `application(_:didFinishLaunchingWithOptions:)` function:

```objc
// Used by plugin: native_geofence
[NativeGeofencePlugin setPluginRegistrantCallback:registerPlugins];
```

</details>

<br>

3. Set your iOS version to `14.0` or above.

You can do so in your `Podfile` by adding the line `platform :ios, '14.0'`.

*Explanation: If you need to support prior iOS builds it might be possible to accommodate this. Please send a PR or file a bug.*

See the [example plugin](https://github.com/ChunkyTofuStudios/native_geofence/tree/main/example/ios/Runner) for a full demonstration.

</details>

## Usage

### Initialize the plugin

Before accesing any methods ensure you initialize the plugin:

```dart
await NativeGeofenceManager.instance.initialize();
```

### Obtain permissions

This plugin does not deal with obtaining permissions from the user. Please use a 3rd party plugin, such as [permission_handler](https://pub.dev/packages/permission_handler) for that.

As noted in the setup section you will need to obtain the following permissions:

* `Permission.location`
* `Permission.locationAlways`: if you want to be notified of geofence events when your app isn't running

### Create geofence

First, define your geofence parameters using the `Geofence` class, for example:

*Note: The ID must be unqiue. Please see the API reference for details.*

```dart
final zone1 = Geofence(
  id: 'zone1',
  location: Location(latitude: 40.75798, longitude: -73.98554), // Times Square
  radiusMeters: 500,
  triggers: {
    GeofenceEvent.enter,
    GeofenceEvent.exit,
    GeofenceEvent.dwell,
  },
  iosSettings: IosGeofenceSettings(
    initialTrigger: true,
  ),
  androidSettings: AndroidGeofenceSettings(
    initialTriggers: {GeofenceEvent.enter},
    expiration: const Duration(days: 7),
    loiteringDelay: const Duration(minutes: 5),
    notificationResponsiveness: const Duration(minutes: 5),
  ),
);
```

Next, create a top-level function that has the `@pragma('vm:entry-point')` annotation; this will act as your geofence callback/handler:

*Note: You can (optional) specify a unique callback function for each geofence.*

```dart
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint('Geofence triggered with params: $params');
}
```

Finally, create the geofence:

```dart
await NativeGeofenceManager.instance.createGeofence(zone1, geofenceTriggered);
```

*Note: You can also call `NativeGeofenceManager` methods (e.g. to create or remove geofences) within a geofence callback. Callbacks are processed one at a time, so events triggered while a callback is running will be delivered after it completes. Events stop waiting for a callback that has not completed 60 seconds after it started (on iOS including time the app spent suspended), so make sure your callbacks always complete, e.g. by using timeouts for network requests. On Android, run callbacks that take longer as a [foreground service](#android-only-foreground-work).*

#### [Android only] Foreground work

If you need to access certain APIs or run a long job in your geofence callback you can promote the runner to a foreground service. You have access to the following functions when running within a geofence callback:

```dart
NativeGeofenceBackgroundManager.instance.promoteToForeground();
// Do a lot of work or access live location?
NativeGeofenceBackgroundManager.instance.demoteToBackground();
```

*Note: Most tasks that complete in a few seconds, such as sending a notification, don't require your callback to run in a foreground service.*

*Warning: This functionality is not well tested. Please report any bugs you find.*

On Android 14+ the foreground service needs a [foreground service type](https://developer.android.com/develop/background-work/services/fgs/service-types) and that type's permission, or your app crashes when you call `promoteToForeground()`. The [Android setup](#android) steps use `location`, which fits geofencing apps because they already hold the location permissions it requires. To use a different type, change `android:foregroundServiceType` and replace `FOREGROUND_SERVICE_LOCATION` with that type's permission. Google Play also requires you to [declare your foreground service types](https://support.google.com/googleplay/android-developer/answer/13392821) in the Play Console.

### Get registered geofences

You can see which geofences are currently active using:

```dart
final List<ActiveGeofence> myGeofences = await NativeGeofenceManager.instance.getRegisteredGeofences();
print('There are ${myGeofences.length} active geofences.')
```

### Remove geofence

You have multiple options to stop listenning for geofence events:

```dart
// Remove a single geofence:
await NativeGeofenceManager.instance.removeGeofenceById('zone1');
// Remove all geofences:
await NativeGeofenceManager.instance.removeAllGeofences();
```

## Error handling

All errors thrown by this plugin are wrapped in `NativeGeofenceException`.

Each exception will contain an error code, please see the API reference a description of each of them.

Ensure you catch this exception and take the neccesary action. For example you might:

```dart
try {
  await NativeGeofenceManager.instance.createGeofence(zone1, geofenceTriggered);
} on NativeGeofenceException catch (e) {
  if (e.code == NativeGeofenceErrorCode.missingLocationPermission) {
    print('Did the user grant us the location permission yet?')
    return
  }
  if (e.code == NativeGeofenceErrorCode.pluginInternal) {
    print('Some internal error occured: message=${e.message}, detail=${e.details}, stackTrace=${e.stacktrace}')
    return
  }
  // Handle other cases.
}
```

## Example

The provided example app demonstrates how to request permissions, register geofences, and send notifications when geofence events occur.

## Prior art

This plugin is based off of [bkonyi/FlutterGeofencing](https://github.com/bkonyi/FlutterGeofencing) and uses code snippets from [flutter_workmanager](https://github.com/fluttercommunity/flutter_workmanager). It was inspired by 525k.io's [geofence_foreground_service](https://pub.dev/packages/geofence_foreground_service) plugin.

## Contributing

Please file any issues, bugs, or feature requests at [GitHub](https://github.com/ChunkyTofuStudios/native_geofence/issues).

Pull requests are welcome.

### Lifecycle reference

[`doc/lifecycle.html`](doc/lifecycle.html) is the detailed reference for how the plugin's lifecycle works on iOS and Android, with each step traced to the code: which Flutter engine and isolate runs a geofence callback, how events are queued, what is stored where, and what changes when the app is in the foreground, suspended, terminated or the device reboots. Read it before changing lifecycle code, and keep it up to date; its diagram data is the JSON block near the end of the file.

### Future work

* **Android:** Allow customizing the notification shown when a geofence callback upgrades to a foreground service.
* **Android:** Allow customizing the wake lock duration when foreground service is launched.
* Other ideas?

## Known Issues

* **iOS:** After reboot, the first geofence event is triggered twice, one immediatly after the other. We recommend checking the last trigger time of a geofence in your app to discard duplicates.
* **Android:** Geofences are re-created after reboot, and when calling `reCreateAfterReboot()`, which applies their `initialTriggers` again: e.g. with `initialTriggers: {GeofenceEvent.enter}` you get another enter event for each geofence the user is already inside.
* **Android:** The emulator does not trigger geofence events if there are no apps accessing the device location. This is an [emulator issue](https://www.b4x.com/android/forum/threads/solved-sanity-check-does-the-android-emulator-work-with-geofences.139196/page-2#post-881415). As a workaround you can open Google Maps to get a location fix which will in turn trigger the geofence.

## Author

This plugin is developed by [Chunky Tofu Studios](https://chunkytofustudios.com).

You can support us by checking out our apps!

For commercial support please reach out to hello@chunkytofustudios.com.
