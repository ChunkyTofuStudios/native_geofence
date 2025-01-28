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
