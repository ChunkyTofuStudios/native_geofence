// Autogenerated from Pigeon (v22.4.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Error class for passing custom error details to Dart side.
final class PigeonError: Error {
  let code: String
  let message: String?
  let details: Any?

  init(code: String, message: String?, details: Any?) {
    self.code = code
    self.message = message
    self.details = details
  }

  var localizedDescription: String {
    return
      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
      }
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let pigeonError = error as? PigeonError {
    return [
      pigeonError.code,
      pigeonError.message,
      pigeonError.details,
    ]
  }
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details,
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)",
  ]
}

private func createConnectionError(withChannelName channelName: String) -> PigeonError {
  return PigeonError(code: "channel-error", message: "Unable to establish connection on channel: '\(channelName)'.", details: "")
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

/// Geofencing events.
///
/// See the helpful illustration at:
/// https://developer.android.com/develop/sensors-and-location/location/geofencing
enum GeofenceEvent: Int {
  case enter = 0
  case exit = 1
  /// Not supported on iOS.
  case dwell = 2
}

/// Errors that can occur when interacting with the native geofence API.
enum NativeGeofenceErrorCode: Int {
  case unknown = 0
  case pluginInternal = 1
  case invalidArguments = 2
  case channelError = 3
  case missingLocationPermission = 4
  case missingBackgroundLocationPermission = 5
  case geofenceNotFound = 6
  case callbackNotFound = 7
}

/// Generated class from Pigeon that represents data sent in messages.
struct LocationWire {
  var latitude: Double
  var longitude: Double



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> LocationWire? {
    let latitude = pigeonVar_list[0] as! Double
    let longitude = pigeonVar_list[1] as! Double

    return LocationWire(
      latitude: latitude,
      longitude: longitude
    )
  }
  func toList() -> [Any?] {
    return [
      latitude,
      longitude,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct AndroidGeofenceSettingsWire {
  var initialTriggers: [GeofenceEvent]
  var expirationDurationMillis: Int64? = nil
  var loiteringDelayMillis: Int64
  var notificationResponsivenessMillis: Int64? = nil



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> AndroidGeofenceSettingsWire? {
    let initialTriggers = pigeonVar_list[0] as! [GeofenceEvent]
    let expirationDurationMillis: Int64? = nilOrValue(pigeonVar_list[1])
    let loiteringDelayMillis = pigeonVar_list[2] as! Int64
    let notificationResponsivenessMillis: Int64? = nilOrValue(pigeonVar_list[3])

    return AndroidGeofenceSettingsWire(
      initialTriggers: initialTriggers,
      expirationDurationMillis: expirationDurationMillis,
      loiteringDelayMillis: loiteringDelayMillis,
      notificationResponsivenessMillis: notificationResponsivenessMillis
    )
  }
  func toList() -> [Any?] {
    return [
      initialTriggers,
      expirationDurationMillis,
      loiteringDelayMillis,
      notificationResponsivenessMillis,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct GeofenceWire {
  var id: String
  var location: LocationWire
  var radiusMeters: Double
  var triggers: [GeofenceEvent]
  var androidSettings: AndroidGeofenceSettingsWire
  var callbackHandle: Int64



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> GeofenceWire? {
    let id = pigeonVar_list[0] as! String
    let location = pigeonVar_list[1] as! LocationWire
    let radiusMeters = pigeonVar_list[2] as! Double
    let triggers = pigeonVar_list[3] as! [GeofenceEvent]
    let androidSettings = pigeonVar_list[4] as! AndroidGeofenceSettingsWire
    let callbackHandle = pigeonVar_list[5] as! Int64

    return GeofenceWire(
      id: id,
      location: location,
      radiusMeters: radiusMeters,
      triggers: triggers,
      androidSettings: androidSettings,
      callbackHandle: callbackHandle
    )
  }
  func toList() -> [Any?] {
    return [
      id,
      location,
      radiusMeters,
      triggers,
      androidSettings,
      callbackHandle,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct ActiveGeofenceWire {
  var id: String
  var location: LocationWire
  var radiusMeters: Double
  var triggers: [GeofenceEvent]
  var androidSettings: AndroidGeofenceSettingsWire? = nil



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> ActiveGeofenceWire? {
    let id = pigeonVar_list[0] as! String
    let location = pigeonVar_list[1] as! LocationWire
    let radiusMeters = pigeonVar_list[2] as! Double
    let triggers = pigeonVar_list[3] as! [GeofenceEvent]
    let androidSettings: AndroidGeofenceSettingsWire? = nilOrValue(pigeonVar_list[4])

    return ActiveGeofenceWire(
      id: id,
      location: location,
      radiusMeters: radiusMeters,
      triggers: triggers,
      androidSettings: androidSettings
    )
  }
  func toList() -> [Any?] {
    return [
      id,
      location,
      radiusMeters,
      triggers,
      androidSettings,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct GeofenceCallbackParams {
  var geofences: [ActiveGeofenceWire]
  var event: GeofenceEvent
  var location: LocationWire? = nil
  var callbackHandle: Int64



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> GeofenceCallbackParams? {
    let geofences = pigeonVar_list[0] as! [ActiveGeofenceWire]
    let event = pigeonVar_list[1] as! GeofenceEvent
    let location: LocationWire? = nilOrValue(pigeonVar_list[2])
    let callbackHandle = pigeonVar_list[3] as! Int64

    return GeofenceCallbackParams(
      geofences: geofences,
      event: event,
      location: location,
      callbackHandle: callbackHandle
    )
  }
  func toList() -> [Any?] {
    return [
      geofences,
      event,
      location,
      callbackHandle,
    ]
  }
}

private class FlutterBindingsPigeonCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
    case 129:
      let enumResultAsInt: Int? = nilOrValue(self.readValue() as! Int?)
      if let enumResultAsInt = enumResultAsInt {
        return GeofenceEvent(rawValue: enumResultAsInt)
      }
      return nil
    case 130:
      let enumResultAsInt: Int? = nilOrValue(self.readValue() as! Int?)
      if let enumResultAsInt = enumResultAsInt {
        return NativeGeofenceErrorCode(rawValue: enumResultAsInt)
      }
      return nil
    case 131:
      return LocationWire.fromList(self.readValue() as! [Any?])
    case 132:
      return AndroidGeofenceSettingsWire.fromList(self.readValue() as! [Any?])
    case 133:
      return GeofenceWire.fromList(self.readValue() as! [Any?])
    case 134:
      return ActiveGeofenceWire.fromList(self.readValue() as! [Any?])
    case 135:
      return GeofenceCallbackParams.fromList(self.readValue() as! [Any?])
    default:
      return super.readValue(ofType: type)
    }
  }
}

private class FlutterBindingsPigeonCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? GeofenceEvent {
      super.writeByte(129)
      super.writeValue(value.rawValue)
    } else if let value = value as? NativeGeofenceErrorCode {
      super.writeByte(130)
      super.writeValue(value.rawValue)
    } else if let value = value as? LocationWire {
      super.writeByte(131)
      super.writeValue(value.toList())
    } else if let value = value as? AndroidGeofenceSettingsWire {
      super.writeByte(132)
      super.writeValue(value.toList())
    } else if let value = value as? GeofenceWire {
      super.writeByte(133)
      super.writeValue(value.toList())
    } else if let value = value as? ActiveGeofenceWire {
      super.writeByte(134)
      super.writeValue(value.toList())
    } else if let value = value as? GeofenceCallbackParams {
      super.writeByte(135)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class FlutterBindingsPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return FlutterBindingsPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return FlutterBindingsPigeonCodecWriter(data: data)
  }
}

class FlutterBindingsPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = FlutterBindingsPigeonCodec(readerWriter: FlutterBindingsPigeonCodecReaderWriter())
}


/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol NativeGeofenceApi {
  func initialize(callbackDispatcherHandle: Int64) throws
  func createGeofence(geofence: GeofenceWire, completion: @escaping (Result<Void, Error>) -> Void)
  func reCreateAfterReboot() throws
  func getGeofenceIds() throws -> [String]
  func getGeofences() throws -> [ActiveGeofenceWire]
  func removeGeofenceById(id: String, completion: @escaping (Result<Void, Error>) -> Void)
  func removeAllGeofences(completion: @escaping (Result<Void, Error>) -> Void)
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class NativeGeofenceApiSetup {
  static var codec: FlutterStandardMessageCodec { FlutterBindingsPigeonCodec.shared }
  /// Sets up an instance of `NativeGeofenceApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: NativeGeofenceApi?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    let initializeChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceApi.initialize\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      initializeChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let callbackDispatcherHandleArg = args[0] as! Int64
        do {
          try api.initialize(callbackDispatcherHandle: callbackDispatcherHandleArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      initializeChannel.setMessageHandler(nil)
    }
    let createGeofenceChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceApi.createGeofence\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      createGeofenceChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let geofenceArg = args[0] as! GeofenceWire
        api.createGeofence(geofence: geofenceArg) { result in
          switch result {
          case .success:
            reply(wrapResult(nil))
          case .failure(let error):
            reply(wrapError(error))
          }
        }
      }
    } else {
      createGeofenceChannel.setMessageHandler(nil)
    }
    let reCreateAfterRebootChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceApi.reCreateAfterReboot\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      reCreateAfterRebootChannel.setMessageHandler { _, reply in
        do {
          try api.reCreateAfterReboot()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      reCreateAfterRebootChannel.setMessageHandler(nil)
    }
    let getGeofenceIdsChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceApi.getGeofenceIds\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      getGeofenceIdsChannel.setMessageHandler { _, reply in
        do {
          let result = try api.getGeofenceIds()
          reply(wrapResult(result))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      getGeofenceIdsChannel.setMessageHandler(nil)
    }
    let getGeofencesChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceApi.getGeofences\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      getGeofencesChannel.setMessageHandler { _, reply in
        do {
          let result = try api.getGeofences()
          reply(wrapResult(result))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      getGeofencesChannel.setMessageHandler(nil)
    }
    let removeGeofenceByIdChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceApi.removeGeofenceById\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      removeGeofenceByIdChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let idArg = args[0] as! String
        api.removeGeofenceById(id: idArg) { result in
          switch result {
          case .success:
            reply(wrapResult(nil))
          case .failure(let error):
            reply(wrapError(error))
          }
        }
      }
    } else {
      removeGeofenceByIdChannel.setMessageHandler(nil)
    }
    let removeAllGeofencesChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceApi.removeAllGeofences\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      removeAllGeofencesChannel.setMessageHandler { _, reply in
        api.removeAllGeofences { result in
          switch result {
          case .success:
            reply(wrapResult(nil))
          case .failure(let error):
            reply(wrapError(error))
          }
        }
      }
    } else {
      removeAllGeofencesChannel.setMessageHandler(nil)
    }
  }
}
/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol NativeGeofenceBackgroundApi {
  func triggerApiInitialized() throws
  func promoteToForeground() throws
  func demoteToBackground() throws
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class NativeGeofenceBackgroundApiSetup {
  static var codec: FlutterStandardMessageCodec { FlutterBindingsPigeonCodec.shared }
  /// Sets up an instance of `NativeGeofenceBackgroundApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: NativeGeofenceBackgroundApi?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    let triggerApiInitializedChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceBackgroundApi.triggerApiInitialized\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      triggerApiInitializedChannel.setMessageHandler { _, reply in
        do {
          try api.triggerApiInitialized()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      triggerApiInitializedChannel.setMessageHandler(nil)
    }
    let promoteToForegroundChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceBackgroundApi.promoteToForeground\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      promoteToForegroundChannel.setMessageHandler { _, reply in
        do {
          try api.promoteToForeground()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      promoteToForegroundChannel.setMessageHandler(nil)
    }
    let demoteToBackgroundChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.native_geofence.NativeGeofenceBackgroundApi.demoteToBackground\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      demoteToBackgroundChannel.setMessageHandler { _, reply in
        do {
          try api.demoteToBackground()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      demoteToBackgroundChannel.setMessageHandler(nil)
    }
  }
}
/// Generated protocol from Pigeon that represents Flutter messages that can be called from Swift.
protocol NativeGeofenceTriggerApiProtocol {
  func geofenceTriggered(params paramsArg: GeofenceCallbackParams, completion: @escaping (Result<Void, PigeonError>) -> Void)
}
class NativeGeofenceTriggerApi: NativeGeofenceTriggerApiProtocol {
  private let binaryMessenger: FlutterBinaryMessenger
  private let messageChannelSuffix: String
  init(binaryMessenger: FlutterBinaryMessenger, messageChannelSuffix: String = "") {
    self.binaryMessenger = binaryMessenger
    self.messageChannelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
  }
  var codec: FlutterBindingsPigeonCodec {
    return FlutterBindingsPigeonCodec.shared
  }
  func geofenceTriggered(params paramsArg: GeofenceCallbackParams, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.native_geofence.NativeGeofenceTriggerApi.geofenceTriggered\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([paramsArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
}
