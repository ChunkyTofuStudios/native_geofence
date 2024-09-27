## Known Issues

* **iOS:** After reboot, the first geofence event is triggered twice, one immediatly after the other. We recommend checking the last trigger time of a geofence in your app to discard duplicates.
* **Android** The emulator does not trigger geofence events when the app is in the background/terminated. This is an [emulator issue](https://www.b4x.com/android/forum/threads/solved-sanity-check-does-the-android-emulator-work-with-geofences.139196/page-2#post-881415). As a workaround you can open Google Maps to get a location fix which will in turn trigger the geofence.

## Permissions

### iOS

* NSLocationWhenInUseUsageDescription
* NSLocationAlwaysAndWhenInUseUsageDescription

[source](https://dwirandyh.medium.com/deep-dive-into-core-location-in-ios-geofencing-region-monitoring-7846802c968e)

### Android

Need to request:

* `ACCESS_FINE_LOCATION`
* `ACCESS_BACKGROUND_LOCATION` for API level 29+

[source](https://developer.android.com/develop/sensors-and-location/location/geofencing#RequestGeofences)

# Geofencing

A sample geofencing plugin with background execution support for Flutter.

## Getting Started
This plugin works on both Android and iOS. Follow the instructions in the following sections for the
platforms which are to be targeted.

### Android

Add the following lines to your `AndroidManifest.xml` to register the background service for
native_geofence:

```xml
<receiver android:name="com.chunkytofustudios.native_geofence.NativeGeofenceBroadcastReceiver"
    android:enabled="true" android:exported="true"/>

<service android:name="com.chunkytofustudios.native_geofence.NativeGeofenceService"
    android:permission="android.permission.BIND_JOB_SERVICE" android:exported="true"/>

<receiver android:name="com.chunkytofustudios.native_geofence.NativeGeofenceRebootBroadcastReceiver"
    android:enabled="true" android:exported="true" android:label="BootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

Also request the correct permissions for native_geofence:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

Finally, create either `Application.kt` or `Application.java` in the same directory as `MainActivity`.
 
For `Application.kt`, use the following:

```kotlin
class Application : FlutterApplication(), PluginRegistrantCallback {
  override fun onCreate() {
    super.onCreate();
    NativeGeofenceService.setPluginRegistrant(this);
  }

  override fun registerWith(registry: PluginRegistry) {
  }
}
```

For `Application.java`, use the following:

```java
public class Application extends FlutterApplication implements PluginRegistrantCallback {
  @Override
  public void onCreate() {
    super.onCreate();
    NativeGeofenceService.setPluginRegistrant(this);
  }

  @Override
  public void registerWith(PluginRegistry registry) {
  }
}
```

Which must also be referenced in `AndroidManifest.xml`:

```xml
    <application
        android:name=".Application"
        ...
```
 
### iOS

Add the following lines to your Info.plist:

```xml
<dict>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>YOUR DESCRIPTION HERE</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>YOUR DESCRIPTION HERE</string>
    ...
```

And request the correct permissions for native_geofence:

```xml
<dict>
    ...
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>
    ...
</dict>
```

Add this line to `Runner-Briding-Header.h`

```h
#import <native_geofence/NativeGeofencePlugin.h>
```

At the end add this line to `AppDelegate.swift`

```swift
NativeGeofencePlugin.setPluginRegistrantCallback { (registry) in GeneratedPluginRegistrant.register(with: registry) }
```

### Notes
Before register geofence request permissions for location and location always. You can use *permission_handler* package. Don't forget include this line in `Podfile`

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
          '$(inherited)',
          'PERMISSION_LOCATION=1',
        ]
      end
  end
end
```

### Need Help?

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/developing-packages/#edit-plugin-package).
