import Flutter
import OSLog
import UIKit

public class NativeGeofencePlugin: NSObject, FlutterPlugin {
    private static let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofencePlugin")
    
    private static var registerPlugins: FlutterPluginRegistrantCallback? = nil
    private static var instance: NativeGeofencePlugin? = nil
    
    private var nativeGeofenceApi: NativeGeofenceApiImpl? = nil
    
    init(registerPlugins: FlutterPluginRegistrantCallback) {
        nativeGeofenceApi = NativeGeofenceApiImpl(registerPlugins: registerPlugins)
    }
    
    /// Called from the Flutter plugins AppDelegate.swift.
    public static func setPluginRegistrantCallback(_ callback: FlutterPluginRegistrantCallback) {
        registerPlugins = callback
        log.debug("registerPlugins updated.")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if instance == nil {
            guard let registerPlugins else {
                log.error("registerPlugins was nil at application launch.")
                fatalError("Please ensure you have updated your ios/Runner/AppDelegate to call setPluginRegistrantCallback. See the plugin documentation for more information.")
            }
            
            let plugin = NativeGeofencePlugin(registerPlugins: registerPlugins)
            registrar.addApplicationDelegate(plugin)
            instance = plugin
            
            log.debug("NativeGeofencePlugin registered.")
        }
        
        // Expose the API on every Flutter engine, including the headless one running geofence callbacks so that they
        // can create/remove geofences. All engines must share one NativeGeofenceApiImpl: a new LocationManagerDelegate
        // would replace the shared CLLocationManager's (weak) delegate and get de-allocated along with its engine,
        // causing all later geofence events to be dropped.
        NativeGeofenceApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance?.nativeGeofenceApi)
        log.debug("NativeGeofenceApi initialized.")
    }
    
    public func detachFromEngine(for registrar: any FlutterPluginRegistrar) {
        nativeGeofenceApi = nil
        NativeGeofencePlugin.instance = nil
        NativeGeofencePlugin.log.debug("NativeGeofencePlugin detached.")
    }
}
