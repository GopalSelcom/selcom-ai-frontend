import Flutter
import UIKit
import GoogleMaps
import PushKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CXProviderDelegate {
  private var appGroupChannel: FlutterMethodChannel?
  private var voipChannel: FlutterMethodChannel?
  private var pushRegistry: PKPushRegistry?
  private var callProvider: CXProvider?
  private let callController = CXCallController()
  private var callByRideId: [String: UUID] = [:]
  private var payloadByCallId: [UUID: [String: Any]] = [:]
  private let pendingVoipEventsKey = "pending_voip_events"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDUQgp46JDap_b1isDkCV371GSmH355qPg")
    GeneratedPluginRegistrant.register(with: self)
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    appGroupChannel = FlutterMethodChannel(name: "com.selcom.go/app_group",
                                      binaryMessenger: controller.binaryMessenger)
    appGroupChannel?.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if (call.method == "getAppGroupDirectory") {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.selcom.go") {
            result(url.path)
        } else {
            result(FlutterError(code: "UNAVAILABLE",
                              message: "App group container not found",
                              details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    voipChannel = FlutterMethodChannel(
      name: "com.selcom.go/voip",
      binaryMessenger: controller.binaryMessenger
    )
    voipChannel?.setMethodCallHandler({ [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "consumePendingVoipEvents":
        let events = self.consumePendingVoipEvents()
        result(events)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    configureCallKit()
    configurePushKit()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configurePushKit() {
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    pushRegistry = registry
  }

  private func configureCallKit() {
    let config = CXProviderConfiguration(localizedName: "Selcom Go")
    config.supportsVideo = false
    config.maximumCallsPerCallGroup = 1
    config.maximumCallGroups = 1
    config.supportedHandleTypes = [.generic]
    callProvider = CXProvider(configuration: config)
    callProvider?.setDelegate(self, queue: nil)
  }

  private func emitVoipEvent(method: String, arguments: [String: Any]) {
    guard let channel = voipChannel else {
      queuePendingVoipEvent(method: method, arguments: arguments)
      return
    }
    channel.invokeMethod(method, arguments: arguments)
  }

  private func queuePendingVoipEvent(method: String, arguments: [String: Any]) {
    var events = UserDefaults.standard.array(forKey: pendingVoipEventsKey) as? [[String: Any]] ?? []
    events.append([
      "method": method,
      "arguments": arguments,
    ])
    UserDefaults.standard.set(events, forKey: pendingVoipEventsKey)
  }

  private func consumePendingVoipEvents() -> [[String: Any]] {
    let events = UserDefaults.standard.array(forKey: pendingVoipEventsKey) as? [[String: Any]] ?? []
    UserDefaults.standard.removeObject(forKey: pendingVoipEventsKey)
    return events
  }

  private func payload(from dictionary: [AnyHashable: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in dictionary {
      guard let k = key as? String else { continue }
      result[k] = value
    }
    return result
  }

  /// Backend contract requires `ride_id` on every VoIP push; we never
  /// fabricate one because doing so would break dedupe between clients.
  private func extractRideId(from payload: [String: Any]) -> String? {
    if let rid = payload["ride_id"] as? String,
       !rid.trimmingCharacters(in: .whitespaces).isEmpty {
      return rid
    }
    if let rid = payload["rideId"] as? String,
       !rid.trimmingCharacters(in: .whitespaces).isEmpty {
      return rid
    }
    return nil
  }

  /// Display name for the system CallKit UI. Backend contract carries
  /// `caller_name` on `incoming_call` pushes; fall back to a role-based label
  /// only when the field is absent.
  private func callerDisplayName(from payload: [String: Any]) -> String {
    if let name = payload["caller_name"] as? String,
       !name.trimmingCharacters(in: .whitespaces).isEmpty {
      return name
    }
    let role = (payload["caller_role"] as? String ?? "").lowercased()
    return role == "driver" ? "Your Driver" : "Your Rider"
  }

  private func endCall(for rideId: String) {
    guard let uuid = callByRideId[rideId] else { return }
    let action = CXEndCallAction(call: uuid)
    let transaction = CXTransaction(action: action)
    callController.request(transaction) { [weak self] _ in
      guard let self = self else { return }
      self.callByRideId.removeValue(forKey: rideId)
      self.payloadByCallId.removeValue(forKey: uuid)
    }
  }

  // MARK: - PushKit
  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else { return }
    let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    emitVoipEvent(method: "onVoipToken", arguments: ["token": token])
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith pushPayload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }
    let map = payload(from: pushPayload.dictionaryPayload)
    let pushType = (map["type"] as? String ?? "").lowercased()
    guard let rideId = extractRideId(from: map) else {
      completion()
      return
    }

    if pushType == "call_cancelled" {
      endCall(for: rideId)
      emitVoipEvent(method: "onVoipCallCancelled", arguments: map)
      completion()
      return
    }

    guard pushType == "incoming_call" else {
      completion()
      return
    }

    let callId = callByRideId[rideId] ?? UUID()
    callByRideId[rideId] = callId
    payloadByCallId[callId] = map

    let callerName = callerDisplayName(from: map)
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: callerName)
    update.localizedCallerName = callerName
    update.hasVideo = false

    callProvider?.reportNewIncomingCall(with: callId, update: update) { [weak self] error in
      if error == nil {
        var args = map
        args["call_uuid"] = callId.uuidString
        self?.emitVoipEvent(method: "onVoipIncomingCall", arguments: args)
      }
      completion()
    }
  }

  // MARK: - CallKit delegate
  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    if var payload = payloadByCallId[action.callUUID] {
      payload["call_uuid"] = action.callUUID.uuidString
      emitVoipEvent(method: "onVoipCallAccepted", arguments: payload)
    }
    action.fulfill()
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    if var payload = payloadByCallId[action.callUUID] {
      payload["call_uuid"] = action.callUUID.uuidString
      emitVoipEvent(method: "onVoipCallCancelled", arguments: payload)
    }
    if let ridePair = callByRideId.first(where: { $0.value == action.callUUID }) {
      callByRideId.removeValue(forKey: ridePair.key)
    }
    payloadByCallId.removeValue(forKey: action.callUUID)
    action.fulfill()
  }

  func providerDidReset(_ provider: CXProvider) {
    callByRideId.removeAll()
    payloadByCallId.removeAll()
  }
}
