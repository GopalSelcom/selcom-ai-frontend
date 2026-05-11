# Selcom Go — `agora_calling_package` integration guide (v0.2.4)

This document is the **single source of truth** for wiring the **rider (Selcom Go)** app to the shared calling package after you copy the `agora_calling_package/` folder into the Selcom Go repo (or add it as a path / git submodule dependency).

Use **§ Prompt for AI** as the instruction block you paste into Cursor along with `@agora_calling_package/` when you want an assistant to apply the same steps in the Selcom Go codebase.

---

## Prompt for AI (paste with `@agora_calling_package/`)

```text
Integrate agora_calling_package v0.2.4 into the Selcom Go (rider) Flutter app.

Follow every step in agora_calling_package/SELCOM_GO_INTEGRATION_GUIDE.md exactly:
- pubspec path dependency + flutter pub get
- AgoraCallingBootstrap (rider CallEndpoints, CallParticipantRole.rider, appName, iosCallKitIconName, callKitCallIdNamespace, getAuthHeaders)
- main.dart: Firebase.initializeApp in background handler, FirebaseMessaging.onBackgroundMessage with AgoraCallingNotificationService.firebaseBackgroundHandler passing the SAME three constants as bootstrap; call AgoraCallingBootstrap.init() before runApp; initialize VoipCallkitBridgeService and wire setOnVoipTokenChanged / setOnIncomingCall
- getPages: spread AgoraCalling.routes()
- VoipCallkitBridgeService: MethodChannel name MUST match ios/Runner/AppDelegate.swift exactly (Selcom Go typically com.selcom.go/voip)
- After login / session restore: call VoipCallkitBridgeService.instance.syncCachedTokenToBackend() (same pattern as guide UserController snippet)
- iOS: Assets.xcassets image for iosCallKitIconName if non-empty; UIBackgroundModes voip + audio; PushKit in AppDelegate if used

Do not skip the FCM background handler parameters — the background isolate cannot read AgoraCallingConfig.

Adapt imports and user/session types to Selcom Go’s project structure; keep endpoint paths and roles as in the guide for the rider app.
```

---

## 1. What this package version includes (already in the folder)

You do **not** re-implement these in Selcom Go — they live inside `agora_calling_package/`:

| Area | Behavior |
|------|----------|
| **CallKit / FCM** | Stable UUID for `CallKitParams.id` (UUID v5 from `ride_id` + `callKitCallIdNamespace`). Optional `iosCallKitIconName`. |
| **FCM background** | `firebaseBackgroundHandler(message, { iosCallKitIconName, callKitCallIdNamespace, backgroundCallKitAppName })` — must match config (isolate cannot read `GetX`). |
| **VoIP PATCH** | Sends auth headers + `access_token` in body; skips PATCH if token empty (pre-login). |
| **iOS incoming UI** | In-app `IncomingCallScreen` + CallKit; ring timer `incomingRingSeconds`; resume sync from `FlutterCallkitIncoming.activeCalls()` when returning from background. |
| **Active call UI** | `Obx` on `connectedSeconds` so in-call `mm:ss` updates after answer. |
| **Agora** | Existing controller flow (mint, join, token refresh, cancel, dedupe). |

---

## 2. Dependency (`pubspec.yaml` in Selcom Go)

Add a **path** (or git) dependency to the copied package:

```yaml
dependencies:
  agora_calling_package:
    path: ../agora_calling_package   # adjust relative path to where the package folder lives
```

Then:

```bash
flutter pub get
cd ios && pod install && cd ..
```

**Transitive deps** (package already declares them): `get`, `dio`, `firebase_messaging`, `flutter_callkit_incoming`, `agora_rtc_engine`, `uuid`, etc. Resolve any version conflicts with `dependency_overrides` only if needed.

---

## 3. Rider backend paths & role (`AgoraCallingBootstrap`)

Create (or replace) something like `lib/core/services/agora_calling_bootstrap.dart` in **Selcom Go**.

**Replace:**

- `YOUR_SELCOM_GO_APP_NAME` — shown in CallKit (e.g. `Selcom Go`).
- `YOUR_AGORA_APP_ID` — same App ID you use today.
- `your_app_package` — your real Dart package import for headers / base URL.
- `CommonValues.headers` (or equivalent) — must return a `Map<String, String>` that includes your backend’s **`access_token`** key when the user is logged in (same as other REST calls).
- `BuildVariantService` / base URL — however Selcom Go already resolves API host.
- **`iosCallKitIconName`**: name of an image set in **`ios/Runner/Assets.xcassets`** (e.g. `CallKitLogo`). Use `''` to omit custom icon.
- **`callKitCallIdNamespace`**: keep default `'agora-call:'` unless you need isolation from another app; **must match** `main.dart` background handler.

```dart
import 'package:agora_calling_package/agora_calling_package.dart';
import 'package:your_app_package/.../common_values.dart'; // e.g. commonHeaders
import 'package:your_app_package/.../build_variant_service.dart';

class AgoraCallingBootstrap {
  AgoraCallingBootstrap._();

  /// FCM background isolate cannot read [AgoraCalling.init] — reuse these in
  /// `FirebaseMessaging.onBackgroundMessage` (see main.dart snippet below).
  static const String fcmBackgroundCallKitAppName = 'YOUR_SELCOM_GO_APP_NAME';
  static const String iosCallKitIconName = 'CallKitLogo'; // or '' to omit
  static const String callKitCallIdNamespace = 'agora-call:';

  static Future<void> init() async {
    await AgoraCalling.init(
      AgoraCallingConfig(
        appId: 'YOUR_AGORA_APP_ID',
        baseUrl: BuildVariantService.instance.baseUrl, // or your equivalent
        getAuthHeaders: () async => CommonValues.headers(), // must include access_token when logged in
        localRole: CallParticipantRole.rider,
        appName: fcmBackgroundCallKitAppName,
        iosCallKitIconName: iosCallKitIconName,
        callKitCallIdNamespace: callKitCallIdNamespace,
        endpoints: CallEndpoints(
          tokenPath: (rideId) => '/v4/go/rides/${rideId.trim()}/call/token',
          cancelPath: (rideId) => '/v4/go/rides/${rideId.trim()}/call/cancel',
          voipTokenPath: '/v4/go/user/voip-token',
        ),
        peerNameResolver: (_) => 'Your Driver',
      ),
    );
  }
}
```

> Paths above match `AgoraCallingConfig` dartdoc for **rider** (`dukadirect_backend`). If your Selcom Go backend uses different prefixes, change only `CallEndpoints` — keep the rest of the wiring.

---

## 4. `main.dart` — order matters

### 4.1 Imports (add)

```dart
import 'package:agora_calling_package/agora_calling_package.dart';
import 'package:your_app_package/core/services/agora_calling_bootstrap.dart';
import 'package:your_app_package/core/services/voip_callkit_bridge_service.dart';
```

### 4.2 Top-level FCM background handler

**Requirements:**

1. `@pragma('vm:entry-point')` on the **top-level** function registered with `FirebaseMessaging.onBackgroundMessage`.
2. First line: `await Firebase.initializeApp();` (with Selcom Go’s options / `DefaultFirebaseOptions` if you use them).
3. For calling-related `data['type']`, delegate to **`AgoraCallingNotificationService.firebaseBackgroundHandler`** with the **same three strings** as `AgoraCallingBootstrap`.

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandlerImpl(RemoteMessage message) async {
  await Firebase.initializeApp(); // use Selcom Go’s Firebase init if different

  final type = (message.data['type'] ?? '').toString().toLowerCase().trim();
  if (type == 'incoming_call' || type == 'call_joined' || type == 'call_cancelled') {
    await AgoraCallingNotificationService.firebaseBackgroundHandler(
      message,
      iosCallKitIconName: AgoraCallingBootstrap.iosCallKitIconName,
      callKitCallIdNamespace: AgoraCallingBootstrap.callKitCallIdNamespace,
      backgroundCallKitAppName: AgoraCallingBootstrap.fcmBackgroundCallKitAppName,
    );
    return;
  }

  // Existing Selcom Go background logic for other message types:
  // await yourLegacyFirebaseBackgroundHandler(message);
}
```

Register **before** `runApp`:

```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandlerImpl);
```

### 4.3 After `Firebase.initializeApp()` in `main()` (foreground isolate)

Call in this **order** (same as Delivery Agent):

```dart
  await AgoraCallingBootstrap.init();

  await VoipCallkitBridgeService.instance.initialize();
  VoipCallkitBridgeService.instance.setOnVoipTokenChanged(
    AgoraCalling.registerVoipToken,
  );
  VoipCallkitBridgeService.instance.setOnIncomingCall(
    AgoraCalling.dispatchExternalIncomingCall,
  );

  runApp(const MyApp());
```

**Why:** `AgoraCalling.init` registers `CallController` and runs `bootstrap()` before notification listeners, avoiding dropped push events on a broadcast stream.

---

## 5. GetX routes

In your `GetMaterialApp` `getPages` list, **prepend** package routes:

```dart
import 'package:agora_calling_package/agora_calling_package.dart';

final getPages = [
  ...AgoraCalling.routes(),
  // ... all existing Selcom Go GetPage entries
];
```

Routes added by the package:

- `/agora_calling/incoming` — `IncomingCallScreen`
- `/agora_calling/active` — `ActiveCallScreen`

---

## 6. VoIP bridge (`VoipCallkitBridgeService`)

Copy this file into Selcom Go (e.g. `lib/core/services/voip_callkit_bridge_service.dart`) and **only change**:

1. **Imports** — point to Selcom Go’s `StorageService` / keys.
2. **`MethodChannel` name** — must be **character-for-character** identical to `AppDelegate.swift` (rider app historically uses `com.selcom.go/voip`; confirm in your iOS project).

Full reference implementation:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart'; // ADAPT: your storage + keys

class VoipCallkitBridgeService {
  VoipCallkitBridgeService._();
  static final VoipCallkitBridgeService instance = VoipCallkitBridgeService._();

  // ADAPT: must match ios/Runner/AppDelegate.swift FlutterMethodChannel name
  static const MethodChannel _channel = MethodChannel('com.selcom.go/voip');

  bool _initialized = false;

  String? _voipToken;
  Future<void> Function(String token)? _onVoipTokenChanged;
  void Function(Map<String, dynamic> data)? _onIncomingCall;

  String get voipToken => _voipToken ?? '';

  void setOnVoipTokenChanged(Future<void> Function(String token)? handler) {
    _onVoipTokenChanged = handler;
    final cached = _voipToken;
    if (handler != null && cached != null && cached.isNotEmpty) {
      unawaited(_safeInvokeTokenHandler(cached));
    }
  }

  /// Call after login / session restore so PATCH /voip-token retries with access_token.
  Future<void> syncCachedTokenToBackend() async {
    final cached = _voipToken;
    if (cached == null || cached.isEmpty) return;
    await _safeInvokeTokenHandler(cached);
  }

  void setOnIncomingCall(void Function(Map<String, dynamic> data)? sink) {
    _onIncomingCall = sink;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _voipToken = await StorageService().read(StorageKeys.voipToken); // ADAPT
    _channel.setMethodCallHandler(_onNativeCall);
    await _consumePendingNativeEvents();
  }

  Future<void> _consumePendingNativeEvents() async {
    try {
      final dynamic raw = await _channel.invokeMethod('consumePendingVoipEvents');
      if (raw is! List) return;
      for (final dynamic item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final method = map['method']?.toString();
        final args = map['arguments'];
        if (method == null) continue;
        if (args is Map) {
          await _dispatch(method, Map<String, dynamic>.from(args));
        } else if (args is String && method == 'onVoipToken') {
          await _dispatch(method, {'token': args});
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[VOIP_BRIDGE] consume failed: $e');
    }
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    final args = call.arguments;
    if (args is Map) {
      await _dispatch(call.method, Map<String, dynamic>.from(args));
    } else if (args is String && call.method == 'onVoipToken') {
      await _dispatch(call.method, {'token': args});
    } else {
      await _dispatch(call.method, const <String, dynamic>{});
    }
    return null;
  }

  Future<void> _dispatch(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'onVoipIncomingCall':
      case 'onIncomingCall':
        final normalised = _normalizeIncoming(args);
        if (normalised == null) return;
        _onIncomingCall?.call(normalised);
        return;
      case 'onVoipToken':
        final token = args['token']?.toString() ?? '';
        if (token.isEmpty) return;
        if (token == _voipToken) return;
        _voipToken = token;
        await StorageService().write(StorageKeys.voipToken, token); // ADAPT
        await _safeInvokeTokenHandler(token);
        break;
      default:
        if (kDebugMode) debugPrint('[VOIP_BRIDGE] unhandled $method');
    }
  }

  Future<void> _safeInvokeTokenHandler(String token) async {
    final handler = _onVoipTokenChanged;
    if (handler == null) return;
    try {
      await handler(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[VOIP_BRIDGE] handler failed: $e');
    }
  }

  Map<String, dynamic>? _normalizeIncoming(Map<String, dynamic> raw) {
    final rideId = (raw['ride_id'] ?? raw['rideId'])?.toString().trim() ?? '';
    if (rideId.isEmpty) return null;
    final channel = _resolveChannelForRide(
      rawChannel: (raw['channel'] ?? raw['channel_name'])?.toString(),
      rideId: rideId,
    );
    final callerRole =
        (raw['caller_role'] ?? raw['callerRole'])?.toString().trim() ?? '';
    return <String, dynamic>{
      ...raw,
      'type': 'incoming_call',
      'ride_id': rideId,
      'channel': channel,
      if (callerRole.isNotEmpty) 'caller_role': callerRole.toLowerCase(),
    };
  }

  String _resolveChannelForRide({
    required String? rawChannel,
    required String rideId,
  }) {
    final trimmed = rawChannel?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final sanitized = rideId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return sanitized.isEmpty ? 'ride_unknown' : 'ride_$sanitized';
  }
}
```

**iOS `AppDelegate`** must implement the same channel name and support `consumePendingVoipEvents` if you buffer native events before Flutter attaches (see Delivery Agent `ios/Runner/AppDelegate.swift` as reference).

---

## 7. Session / VoIP token retry (fresh install & relaunch)

After **login** or **restoring user from disk**, call:

```dart
await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
```

**Pattern** (adapt class names to Selcom Go):

```dart
// After persisting user session (e.g. saveUserData):
await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();

// After loading cached user on cold start (e.g. getUserData restored model):
await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
```

This replays the PushKit token through `AgoraCalling.registerVoipToken` → `CallApiService.registerVoipToken` once `getAuthHeaders()` includes `access_token`.

---

## 8. iOS checklist (Selcom Go target)

| Item | Action |
|------|--------|
| **Assets** | If `iosCallKitIconName` is non-empty, add `Imageset` in `Runner/Assets.xcassets` with that name. |
| **Info.plist** | `UIBackgroundModes`: `audio`, `voip` (and push-related keys per Apple docs). |
| **Entitlements** | Push / VoIP as required; **production** builds need correct `aps-environment` for TestFlight/App Store. |
| **Method channel** | Dart `VoipCallkitBridgeService` ↔ Swift `FlutterMethodChannel` name must match. |
| **PushKit** | If you use native `CXProvider` + PushKit in `AppDelegate`, keep payload contract (`ride_id`, `channel`, `caller_role`, `type: incoming_call`) aligned with backend. |

---

## 9. Native iOS template patch (`ios/Runner/AppDelegate.swift`)

Use this as a **base template** for Selcom Go native VoIP handling.  
Adapt only the marked placeholders.

### 9.1 Replace placeholders first

- `YOUR_APP_NAME` -> e.g. `Selcom Go`
- `YOUR_VOIP_CHANNEL_NAME` -> must match Dart `VoipCallkitBridgeService` exactly (e.g. `com.selcom.go/voip`)
- Ensure your payload carries `ride_id` (required), and ideally `type: incoming_call`

### 9.2 Full template

```swift
import UIKit
import Flutter
import Firebase
import PushKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CXProviderDelegate {
    private var voipChannel: FlutterMethodChannel?
    private var pushRegistry: PKPushRegistry?
    private var callProvider: CXProvider?
    private let callController = CXCallController()

    // Buffer native events until Dart registers method handler.
    private var pendingVoipEvents: [[String: Any]] = []

    // ride_id <-> call UUID mapping for CallKit actions.
    private var callsByRideId: [String: UUID] = [:]
    private var ridesByCallId: [UUID: String] = [:]

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        voipChannel = FlutterMethodChannel(
            name: "YOUR_VOIP_CHANNEL_NAME",
            binaryMessenger: controller.binaryMessenger
        )
        voipChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterMethodNotImplemented)
                return
            }

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

    // MARK: - Setup

    private func configurePushKit() {
        let registry = PKPushRegistry(queue: .main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.pushRegistry = registry
    }

    private func configureCallKit() {
        let cfg = CXProviderConfiguration(localizedName: "YOUR_APP_NAME")
        cfg.supportsVideo = false
        cfg.maximumCallsPerCallGroup = 1
        cfg.maximumCallGroups = 1
        cfg.supportedHandleTypes = [.generic]
        cfg.includesCallsInRecents = true // set false if product/privacy wants no recents

        let provider = CXProvider(configuration: cfg)
        provider.setDelegate(self, queue: nil)
        self.callProvider = provider
    }

    // MARK: - PushKit token lifecycle

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
        didInvalidatePushTokenFor type: PKPushType
    ) {
        guard type == .voIP else { return }
        // Keep empty token emission so Dart can decide unregister behavior.
        emitVoipEvent(method: "onVoipToken", arguments: ["token": ""])
    }

    // MARK: - Incoming VoIP push

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        guard type == .voIP else {
            completion()
            return
        }

        let raw = normalizePayload(payload.dictionaryPayload)
        let pushType = (raw["type"] as? String)?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let pushType, !pushType.isEmpty, pushType != "incoming_call" {
            completion()
            return
        }

        guard let rideId = (raw["ride_id"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !rideId.isEmpty else {
            completion()
            return
        }

        let callerName = callerDisplayLabel(from: raw)

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
            guard let self = self else { return }

            if error != nil {
                self.callsByRideId.removeValue(forKey: rideId)
                self.ridesByCallId.removeValue(forKey: uuid)
                return
            }

            var args = raw
            args["call_id"] = uuid.uuidString
            self.emitVoipEvent(method: "onVoipIncomingCall", arguments: args)
        }
    }

    // MARK: - CXProviderDelegate

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
            channel.invokeMethod(method, arguments: arguments)
        } else {
            pendingVoipEvents.append(["method": method, "arguments": arguments])
        }
    }

    private func normalizePayload(_ raw: [AnyHashable: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in raw {
            if let key = k as? String {
                out[key] = v
            }
        }
        if let aps = out["aps"] as? [String: Any] {
            for (k, v) in aps where out[k] == nil {
                out[k] = v
            }
        }
        return out
    }

    private func callerDisplayLabel(from data: [String: Any]) -> String {
        if let name = data["caller_name"] as? String, !name.isEmpty {
            return name
        }
        if let role = (data["caller_role"] as? String)?.lowercased() {
            switch role {
            case "rider":
                return "Your Rider"
            case "driver":
                return "Your Driver"
            default:
                break
            }
        }
        return "Caller"
    }
}
```

### 9.3 Native sanity checklist after patch

- `MethodChannel` name in Swift == Dart (`VoipCallkitBridgeService._channel`).
- `consumePendingVoipEvents` works (events received even when app wakes from kill state).
- `onVoipToken`, `onVoipIncomingCall`, `onVoipCallAccepted`, `onVoipCallCancelled` reach Dart.
- Accept from lock screen triggers app-side call accept flow.
- End/decline clears maps and emits cancellation event.

---

## 10. FCM payload contract (backend)

For **`incoming_call`** (data message):

- `type`: `incoming_call`
- `ride_id` (or `rideId`)
- `channel` (optional; package can derive `ride_*` channel)
- `caller_role` / `caller_name` as per your brain doc

For **`call_cancelled`** / **`call_joined`**: same `type` strings the package already handles.

---

## 11. Outgoing call from UI (example)

Where Selcom Go starts a ride call to the driver:

```dart
import 'package:agora_calling_package/agora_calling_package.dart';

await AgoraCalling.controller.placeCall(
  rideId: ride.id,
  peerDisplayName: ride.driverName, // or resolved label
);
```

---

## 12. Verification checklist (manual QA)

Use **two physical devices** where possible (iOS Simulator has limited PushKit behavior).

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Rider logged in, iOS, foreground incoming FCM | CallKit + in-app incoming; `Ringing • mm:ss` ticks. |
| 2 | Same, **Accept** from CallKit | Joins channel; **active** screen `mm:ss` ticks (`connectedSeconds`). |
| 3 | Incoming while app **backgrounded** | Native ring; open app → in-app incoming appears (resume sync). |
| 4 | Fresh install, PushKit token before login | No VoIP PATCH timeout spam; after login, VoIP PATCH succeeds (sync replay). |
| 5 | `firebaseBackgroundHandler` params | Match `AgoraCallingBootstrap` constants — otherwise CallKit id mismatch / wrong app name in BG. |
| 6 | Android | CallStyle / Telecom path still works; routes present. |

---

## 13. Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| CallKit crash on show | `CallKitParams.id` must be UUID — handled in package; do not bypass with raw `ride_id`. |
| No in-app screen after background ring | FCM BG isolate doesn’t push Flutter routes — resume sync + foreground `onMessage` path; ensure `bootstrap()` ran. |
| VoIP PATCH timeout / hang | Missing `access_token` in `getAuthHeaders()` or wrong base URL; use `syncCachedTokenToBackend` after login. |
| Method channel silent | String mismatch between Dart and Swift. |
| In-call timer frozen | Fixed in package via `Obx` on `connectedSeconds` — ensure you’re on **v0.2.4+** of this folder. |

---

## 14. Optional: pin package version in docs

In Selcom Go `pubspec.yaml` you can add a comment:

```yaml
  # agora_calling_package: aligned with SELCOM_GO_INTEGRATION_GUIDE.md (v0.2.4)
  agora_calling_package:
    path: ../agora_calling_package
```

---

## 15. Questions to confirm with your team before go-live

1. **Exact** rider REST paths — still `/v4/go/rides/:id/call/token` and `/v4/go/user/voip-token`?
Answer:- these are the paths of my endpoints
 endpoints: CallEndpoints(
          tokenPath: (rideId) => '/v4/go/rides/$rideId/call/token',
          cancelPath: (rideId) => '/v4/go/rides/$rideId/call/cancel',
          voipTokenPath: '/v4/go/user/voip-token',
        ),

2. **Auth header** key for JWT — still `access_token` in headers map (and sometimes body)?
Answer:- yes,

3. **Selcom Go iOS bundle** and **MethodChannel** string for VoIP?
Answer:- Yes,
4. Will **both** FCM data `incoming_call` and **PushKit** deliver for the same ring on iOS? If yes, plan dedupe on backend or accept package dedupe windows.
Answer:- Keep It Later

---

*End of guide. Copy the `agora_calling_package` directory and this file together into Selcom Go’s repo or monorepo so integrators always have the prompt + code in one place.*
