## 1.6.0

* Android: Raises `minSdkVersion` from 23 to 24, Flutter's default. Apps that set 23 need to raise it.
* Android: Fixes geofence callbacks failing on Android 7 (API 24-25), where the plugin called notification and foreground service APIs that only exist on Android 8+ (found in the forks of [danqulogy](https://github.com/danqulogy) and [yarith28](https://github.com/yarith28))
* Android: Fixes a failed geofence callback (e.g. one whose callback dispatcher can't be found) causing every later callback to be skipped, until no geofence event arrived for about a day (found in the fork of [yarith28](https://github.com/yarith28))
* Android: Fixes geofences created with different callbacks all running the callback of the most recently created geofence (found in the fork of [yarith28](https://github.com/yarith28))
* Adds `NativeGeofenceErrorCode.geofenceLimitExceeded`, which `createGeofence` throws when the app already has the maximum number of geofences: 20 regions per app on iOS, including those of other plugins or SDKs, and 100 geofences on Android.
* iOS: `createGeofence` now waits for iOS to start monitoring the geofence, and throws a `NativeGeofenceException` if iOS can't monitor it, e.g. `geofenceLimitExceeded`. Previously it always succeeded.
* Android: Expired geofences are no longer returned by `getRegisteredGeofenceIds()` and `getRegisteredGeofences()`, and re-creating geofences after a reboot or with `reCreateAfterReboot()` keeps their expiration instead of restarting it. Applies to geofences created with 1.6.0 or later (found in the fork of [yarith28](https://github.com/yarith28))
* Android: Fixes geofences no longer triggering after the app is updated, until the device rebooted or the app called `reCreateAfterReboot()`. Play services removes an app's geofences when the app is updated, and `NativeGeofenceRebootBroadcastReceiver` now re-creates them.
  * Add the `android.intent.action.MY_PACKAGE_REPLACED` action to its intent filter in your `AndroidManifest.xml` (see the README).
  * It now ignores broadcasts other than `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED`, which only the system can send, so other apps can no longer make it re-create geofences.
* Android: Documents that `AndroidGeofenceSettings.initialTriggers` fire again when geofences are re-created after a reboot or an app update, or with `reCreateAfterReboot()`.
* Android: Removes the unused `play-services-maps` dependency (found in the fork of [thebigtank](https://github.com/thebigtank))
* Android: Fixes a geofence callback that never completes, e.g. because its function was renamed or moved in an app update, blocking every later callback for up to 10 minutes. As on iOS, events stop waiting for a callback that has not completed after 60 seconds.
* Removes force unwraps (`!`) from the plugin. `NativeGeofenceBackgroundManager.instance` now throws its documented `AssertionError` outside of geofence callbacks in release builds too, instead of a null check error.

## 1.5.1

* iOS: Fixes geofence events that launch the app being lost with the [UIScene life cycle](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) [#45](https://github.com/ChunkyTofuStudios/native_geofence/issues/45)
  * Keep calling `NativeGeofencePlugin.setPluginRegistrantCallback` in `application(_:didFinishLaunchingWithOptions:)`

## 1.5.0

* Updates the minimum supported SDK version to Flutter 3.44/Dart 3.12.
* Android: Migrates to built-in Kotlin, so Flutter no longer warns on AGP 9 that this plugin applies the Kotlin Gradle Plugin.
* iOS: Allow calling `NativeGeofenceManager` methods (e.g. create or remove geofences) within geofence callbacks: [#26](https://github.com/ChunkyTofuStudios/native_geofence/issues/26)
  * Re-lands the 1.1.0 change without the regression fixed in 1.2.0 by re-using the existing `LocationManagerDelegate`, as proposed by [Mako-L](https://github.com/Mako-L) in [#34](https://github.com/ChunkyTofuStudios/native_geofence/pull/34)
* iOS: Fixes a geofence event that arrives while a callback is running from terminating that callback: [#30](https://github.com/ChunkyTofuStudios/native_geofence/issues/30)
  * Callbacks now run one at a time, as on Android. Events queued behind a callback that hasn't completed after 60 seconds no longer wait for it.
* Android: `demoteToBackground()` now releases the foreground service's wake lock; previously it stayed held until its 5 minute timeout (reported by [delightweaver](https://github.com/delightweaver)) [#55](https://github.com/ChunkyTofuStudios/native_geofence/issues/55)
* Android: The foreground service is no longer restarted by the system after the app process is killed; previously the restarted service crashed the app
* Android: Documents the manifest entries `promoteToForeground()` needs on Android 14+: the `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION` permissions, and `android:foregroundServiceType="location"` on `NativeGeofenceForegroundService`. Without them the app crashes with `MissingForegroundServiceTypeException` [#61](https://github.com/ChunkyTofuStudios/native_geofence/pull/61)

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
