import Flutter
import native_geofence
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, @preconcurrency FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Used by plugin: native_geofence
        // Must be called here, not in didInitializeImplicitFlutterEngine: geofence events that launch the app in the
        // background are only delivered if this is called during app launch.
        NativeGeofencePlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }

        // Used by plugin: flutter_local_notifications
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
