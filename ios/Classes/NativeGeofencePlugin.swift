import Flutter
import OSLog
import UIKit

public class NativeGeofencePlugin: NSObject, FlutterPlugin {
    private static let log = Logger(subsystem: Constants.PACKAGE_NAME, category: "NativeGeofencePlugin")

    private static var registerPlugins: FlutterPluginRegistrantCallback? = nil
    private static var instance: NativeGeofencePlugin? = nil

    private var nativeGeofenceApi: NativeGeofenceApiImpl? = nil

    init(registrar: FlutterPluginRegistrar, registerPlugins: FlutterPluginRegistrantCallback) {
        nativeGeofenceApi = NativeGeofenceApiImpl(registerPlugins: registerPlugins)
        NativeGeofenceApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nativeGeofenceApi)
        NativeGeofencePlugin.log.debug("NativeGeofenceApi initialized.")
    }

    /// Called from the Flutter plugins AppDelegate.swift.
    public static func setPluginRegistrantCallback(_ callback: FlutterPluginRegistrantCallback) {
        registerPlugins = callback
        log.debug("registerPlugins updated.")
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if instance != nil { return }

        guard let registerPlugins else {
            log.error("registerPlugins was nil at application launch.")
            fatalError("Please ensure you have updated your ios/Runner/AppDelegate to call setPluginRegistrantCallback. See the plugin documentation for more information.")
        }

        let plugin = NativeGeofencePlugin(registrar: registrar, registerPlugins: registerPlugins)
        registrar.addApplicationDelegate(plugin)
        instance = plugin

        log.debug("NativeGeofencePlugin registered.")
    }

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]) -> Bool {
        // Check to see if we're being launched due to a location event.
        if launchOptions[UIApplication.LaunchOptionsKey.location] != nil {
            if let api = nativeGeofenceApi {
                // Restart the headless service.
                do {
                    try api.initializeWithCachedState()
                } catch {
                    NativeGeofencePlugin.log.error("Failed to restart headless service: \(error)")
                }
            } else {
                NativeGeofencePlugin.log.warning("Application launched but NativeGeofenceApi was never initialized.")
            }
        }

        // Note: if we return NO, this vetos the launch of the application.
        return true
    }
}
