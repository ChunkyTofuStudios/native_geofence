## 1.5.0

* iOS: Allow calling `NativeGeofenceManager` methods (e.g. create or remove geofences) within geofence callbacks: [#26](https://github.com/ChunkyTofuStudios/native_geofence/issues/26)
  * Re-lands the 1.1.0 change without the regression fixed in 1.2.0 by re-using the existing `LocationManagerDelegate`, as proposed by [Mako-L](https://github.com/Mako-L) in [#34](https://github.com/ChunkyTofuStudios/native_geofence/pull/34)
* iOS: Fixes a geofence event that arrives while a callback is running from terminating that callback: [#30](https://github.com/ChunkyTofuStudios/native_geofence/issues/30)
  * Callbacks now run one at a time, as on Android. Events queued behind a callback that hasn't completed after 60 seconds no longer wait for it.

## 1.4.0

* Adds `GeofenceCallbackParams.triggeredAt`: the time the geofence event was triggered, which can be earlier than when the callback runs (by [SardorbekAbdulabbozov](https://github.com/SardorbekAbdulabbozov)) [#56](https://github.com/ChunkyTofuStudios/native_geofence/pull/56)
  * Only set on Android, as iOS does not provide this information
* iOS: Respects `IosGeofenceSettings.initialTrigger = false`: no event is triggered when the geofence is created while already inside it (by [Zataxo](https://github.com/Zataxo)) [#39](https://github.com/ChunkyTofuStudios/native_geofence/pull/39)

## 1.3.1

* Improves AGP 9 support (by [doug-shontz](https://github.com/doug-shontz))

## 1.3.0

* Adds Swift Package Manager support (by [doug-shontz](https://github.com/doug-shontz))
* Adds AGP 9 support for Flutter 3.44+ (by [doug-shontz](https://github.com/doug-shontz))

## 1.2.2

* Upgrade dependencies
* Update README to clarify Android minSDKVersion

## 1.2.1

* Upgrade dependencies
* Add new optional step to Android setup instructions

## 1.2.0

* iOS: Fixes regression: geofences callbacks not being executed after their first trigger
  * Reverts 1.1.0 change which had enabled calling GeofenceManager methods in geofence callbacks
* iOS: Do not call Dart callback for unrequested geofence triggers: [#37](https://github.com/ChunkyTofuStudios/native_geofence/pull/37) by [slaci](https://github.com/slaci)
* Upgrade dependencies

## 1.1.0

* Upgrade pub.dev dependencies
* Upgrade Android Gradle dependencies
* Downgrade Android minSdkVersion to 23 (thanks [AzarouAmine](https://github.com/AzarouAmine)!)
* Allow calling GeofenceManager methods in geofence callbacks (thanks [Mako-L](https://github.com/Mako-L)!)
* Example App: refactor notification logic into a NotificationsRepository (thanks [fadelfffar](https://github.com/fadelfffar)!)

## 1.0.9

* Minor visibility fix: Make `NativeGeofenceException` visible to library users.

## 1.0.8

* Make plugin compatible with Flutter apps using Kotlin 2+.

## 1.0.7

* Fixes a bug with Android 30 and older. [#9](https://github.com/ChunkyTofuStudios/native_geofence/issues/9)
* Improve documentation.

## 1.0.6

* iOS: Improved background isolate spawning & cleanup routine.
* iOS: Fixes rare bug that may cause the goefence to triggering twice.

## 1.0.5

* Android: Specify Kotlin package when using Pigeon.

## 1.0.4

* Android: Use custom error class name to avoid naming conflicts ("Type FlutterError is defined multiple times") at build time.

## 1.0.3

* iOS: Removes `UIBackgroundModes.location` which was not required. Thanks @cbrauchli.

## 1.0.2

* iOS and Android: Process geofence callbacks sequentially; as opposed to in parallel.
* README changes.

## 1.0.1

* WASM support.
* Better documentation.
* Formatting fixes.

## 1.0.0

* Initial release.
