import Flutter
import UIKit

public class NativeGeofencePlugin: NSObject, FlutterPlugin {
    static var registerPlugins: FlutterPluginRegistrantCallback? = nil

    public static func setPluginRegistrantCallback(_ callback: FlutterPluginRegistrantCallback) {
        registerPlugins = callback
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        //    let channel = FlutterMethodChannel(name: "native_geofence", binaryMessenger: registrar.messenger())
        //    let instance = NativeGeofencePlugin()
        //    registrar.addMethodCallDelegate(instance, channel: channel)
        guard let registerPlugins else {
            fatalError("Please ensure you have updated your ios/Runner/AppDelegate to call setPluginRegistrantCallback. See the plugin documentation for more information.")
        }
        NativeGeofenceApiSetup.setUp(binaryMessenger: registrar.messenger(), api: NativeGeofenceApiImpl(registerPlugins: registerPlugins))
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
