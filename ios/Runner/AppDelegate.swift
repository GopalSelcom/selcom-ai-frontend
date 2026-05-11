import Flutter
import UIKit
import GoogleMaps
import PushKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CXProviderDelegate {
  // MARK: - Channels
  private var appGroupChannel: FlutterMethodChannel?
  private var voipChannel: FlutterMethodChannel?

  // MARK: - VoIP / CallKit
  private var pushRegistry: PKPushRegistry?
  private var callProvider: CXProvider?
  private let callController = CXCallController()
  /// Pending VoIP events queued before the Flutter side has attached the
  /// method-call handler (e.g. cold-start from a VoIP push). Drained when
  /// `consumePendingVoipEvents` is invoked from Dart.
  private var pendingVoipEvents: [[String: Any]] = []
  /// rideId → CallKit UUID, to keep CXEnd actions aligned with reportNewIncomingCall.
  private var callsByRideId: [String: UUID] = [:]
  private var ridesByCallId: [UUID: String] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDUQgp46JDap_b1isDkCV371GSmH355qPg")
    GeneratedPluginRegistrant.register(with: self)
    guard let registrar = self.registrar(forPlugin: "SelcomGoVoipBridge") else {
      NSLog("[VOIP_NATIVE] registrar unavailable; skipping channel bootstrap")
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let messenger = registrar.messenger()

    // Existing app-group bridge (unchanged).
    appGroupChannel = FlutterMethodChannel(
      name: "com.selcom.go/app_group",
      binaryMessenger: messenger
    )
    appGroupChannel?.setMethodCallHandler { (call, result) in
      if call.method == "getAppGroupDirectory" {
        if let url = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: "group.com.selcom.go"
        ) {
          result(url.path)
        } else {
          result(FlutterError(code: "UNAVAILABLE",
                              message: "App group container not found",
                              details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // VoIP bridge — used by the Dart-side `VoipCallkitBridgeService` and the
    // Agora calling package to receive PushKit incoming-call events and the
    // VoIP push token. Per brain/docs/AGORA-FRONTEND-GUIDE.md § 6.5.
    voipChannel = FlutterMethodChannel(
      name: "com.selcom.go/voip",
      binaryMessenger: messenger
    )
    voipChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { result(FlutterMethodNotImplemented); return }
      switch call.method {
      case "consumePendingVoipEvents":
        let drained = self.pendingVoipEvents
        self.pendingVoipEvents.removeAll()
        result(drained)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    configureCallKit()
    configurePushKit()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - PushKit setup

  private func configurePushKit() {
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    self.pushRegistry = registry
    NSLog("[VOIP_NATIVE] PKPushRegistry configured, requested types=[.voIP]")
  }

  private func configureCallKit() {
    let cfg = CXProviderConfiguration(localizedName: "Selcom Go")
    cfg.supportsVideo = false
    cfg.maximumCallsPerCallGroup = 1
    cfg.maximumCallGroups = 1
    cfg.supportedHandleTypes = [.generic]
    cfg.includesCallsInRecents = true
    let provider = CXProvider(configuration: cfg)
    provider.setDelegate(self, queue: nil)
    self.callProvider = provider
  }

  // MARK: - PushKit delegate

  func pushRegistry(_ registry: PKPushRegistry,
                    didUpdate pushCredentials: PKPushCredentials,
                    for type: PKPushType) {
    guard type == .voIP else { return }
    let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    // Log a short prefix only — never the full token, but enough to verify a
    // token actually came in and to compare against the value the backend
    // stores. If you NEVER see this line in Xcode console, the device is not
    // receiving a VoIP push token (no Push capability, no APNs auth, or no
    // network). Without it the backend cannot deliver a VoIP push.
    let prefix = String(token.prefix(8))
    NSLog("[VOIP_NATIVE] PKPushRegistry didUpdate VoIP token len=\(token.count) prefix=\(prefix)…")
    emitVoipEvent(method: "onVoipToken", arguments: ["token": token])
  }

  func pushRegistry(_ registry: PKPushRegistry,
                    didInvalidatePushTokenFor type: PKPushType) {
    guard type == .voIP else { return }
    NSLog("[VOIP_NATIVE] PKPushRegistry didInvalidatePushTokenFor VoIP")
    emitVoipEvent(method: "onVoipToken", arguments: ["token": ""])
  }

  /// Called even when the app is killed. Apple requires that we ALWAYS report
  /// a new incoming call to CallKit on this code path or iOS will terminate
  /// the app on subsequent VoIP pushes.
  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType,
                    completion: @escaping () -> Void) {
    NSLog("[VOIP_NATIVE] didReceiveIncomingPushWith type=\(type.rawValue) payload=\(payload.dictionaryPayload)")
    guard type == .voIP else { completion(); return }
    let raw = normalizePayload(payload.dictionaryPayload)
    let pushType = (raw["type"] as? String)?
      .lowercased()
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if let pushType, !pushType.isEmpty, pushType != "incoming_call" {
      NSLog("[VOIP_NATIVE] dropping VoIP push — unsupported type=\(pushType)")
      completion()
      return
    }

    // Per brain doc: PushKit pushes are ONLY incoming_call.
    // Drop pushes that are missing ride_id — contract violation.
    guard let rideId = (raw["ride_id"] as? String).flatMap({ $0.isEmpty ? nil : $0 })
    else {
      NSLog("[VOIP_NATIVE] dropping VoIP push — no ride_id in payload")
      completion()
      return
    }

    let callerName = callerDisplayLabel(from: raw)
    NSLog("[VOIP_NATIVE] reporting incoming call rideId=\(rideId) caller=\(callerName)")

    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: callerName)
    update.localizedCallerName = callerName
    update.hasVideo = false
    update.supportsHolding = false
    update.supportsGrouping = false
    update.supportsUngrouping = false
    update.supportsDTMF = false

    let uuid = UUID()
    callsByRideId[rideId] = uuid
    ridesByCallId[uuid] = rideId

    callProvider?.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
      defer { completion() }
      if let error = error {
        NSLog("[VOIP_NATIVE] reportNewIncomingCall FAILED rideId=\(rideId) error=\(error.localizedDescription)")
        self?.callsByRideId.removeValue(forKey: rideId)
        self?.ridesByCallId.removeValue(forKey: uuid)
        return
      }
      NSLog("[VOIP_NATIVE] reportNewIncomingCall OK rideId=\(rideId) uuid=\(uuid.uuidString)")
      var args: [String: Any] = raw
      args["call_id"] = uuid.uuidString
      self?.emitVoipEvent(method: "onVoipIncomingCall", arguments: args)
    }
  }

  // MARK: - CXProvider delegate

  func providerDidReset(_ provider: CXProvider) {
    callsByRideId.removeAll()
    ridesByCallId.removeAll()
  }

  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    if let rideId = ridesByCallId[action.callUUID] {
      emitVoipEvent(method: "onVoipCallAccepted", arguments: ["ride_id": rideId])
    }
    action.fulfill()
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    if let rideId = ridesByCallId[action.callUUID] {
      emitVoipEvent(method: "onVoipCallCancelled", arguments: ["ride_id": rideId])
      callsByRideId.removeValue(forKey: rideId)
    }
    ridesByCallId.removeValue(forKey: action.callUUID)
    action.fulfill()
  }

  // MARK: - Helpers

  private func emitVoipEvent(method: String, arguments: Any) {
    if let channel = voipChannel {
      NSLog("[VOIP_NATIVE] emit method=\(method) (channel ready)")
      channel.invokeMethod(method, arguments: arguments)
    } else {
      NSLog("[VOIP_NATIVE] queue method=\(method) (channel not ready — will drain on Dart consume)")
      pendingVoipEvents.append(["method": method, "arguments": arguments])
    }
  }

  /// Normalises a PushKit dictionary into `[String: Any]` with safe string
  /// fields for the keys we care about.
  private func normalizePayload(_ raw: [AnyHashable: Any]) -> [String: Any] {
    var out: [String: Any] = [:]
    for (k, v) in raw {
      if let key = k as? String {
        out[key] = v
      }
    }
    if let aps = out["aps"] as? [String: Any] {
      // Some payloads put the data block inside "aps".
      for (k, v) in aps where out[k] == nil { out[k] = v }
    }
    return out
  }

  /// Prefers `caller_name` from the push; falls back to a role-based label.
  private func callerDisplayLabel(from data: [String: Any]) -> String {
    if let name = data["caller_name"] as? String, !name.isEmpty { return name }
    if let role = (data["caller_role"] as? String)?.lowercased() {
      switch role {
      case "rider":  return "Your Rider"
      case "driver": return "Your Driver"
      default: break
      }
    }
    return "Caller"
  }
}
