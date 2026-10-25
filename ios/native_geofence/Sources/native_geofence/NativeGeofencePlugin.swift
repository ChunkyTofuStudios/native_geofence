import Flutter
import OSLog
import UIKit

public class NativeGeofencePlugin: NSObject, FlutterPlugin {
    private static let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofencePlugin")
    
    /// Called from the Flutter plugins AppDelegate.swift, within `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// `callback` registers the app's plugins with the headless Flutter engine that runs geofence callbacks. This also
    /// starts listening for geofence events, which must happen during app launch: when a geofence event launches the
    /// app in the background there might be no Flutter engine to register this plugin with (e.g. with the UIScene life
    /// cycle, when no UI scene is connected).
    public static func setPluginRegistrantCallback(_ callback: FlutterPluginRegistrantCallback) {
        LocationManagerDelegate.shared.flutterPluginRegistrantCallback = callback
        log.debug("registerPlugins updated.")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        if LocationManagerDelegate.shared.flutterPluginRegistrantCallback == nil {
            log.error("registerPlugins was nil at application launch.")
            fatalError("Please ensure you have updated your ios/Runner/AppDelegate to call setPluginRegistrantCallback. See the plugin documentation for more information.")
        }
        
        // Expose the API on every Flutter engine, including the headless one running geofence callbacks so that they
        // can create/remove geofences. All engines share the LocationManagerDelegate singleton, a new one would replace
        // the CLLocationManager's (weak) delegate and get de-allocated along with its engine.
        NativeGeofenceApiSetup.setUp(binaryMessenger: registrar.messenger(), api: NativeGeofenceApiImpl())
        log.debug("NativeGeofenceApi initialized.")
    }
}
