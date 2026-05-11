# agora_calling_package

Audio-only, ride-scoped Agora voice calling for the **Selcom Go** (rider) and
**Delivery Agent** (driver) Flutter apps. One package — both apps. Per-host
behaviour is supplied via config; nothing inside the package needs to change
between rider and driver.

> Backend contract: `brain/docs/AGORA-FRONTEND-GUIDE.md` and
> `brain/docs/backend-specs/AGORA-CALLING.md`. Anything in this README that
> appears to disagree with those docs, the docs win.

---

## What this package does

- One-shot `AgoraCalling.init(...)` wires Agora RTC, FCM listeners, local
  notifications, and `flutter_callkit_incoming`.
- Bidirectional 1:1 voice calling — same `CallController` for caller / callee.
- Foreground / background / killed-state ring on both platforms.
- Caller pre-joins the Agora channel after token mint (no setup latency
  visible to the answering party).
- `call_joined` push and Agora `onUserJoined` SDK event are deduped — whichever
  arrives first transitions UI to "Connected".
- Token refresh on `onTokenPrivilegeWillExpire` — re-mints via the same
  endpoint used at call start.
- Cancel-vs-End semantics built into the controller: hangup before connect →
  `POST /…/call/cancel`; hangup after connect → just `leaveChannel()`.
- Reactive (`Obx`) — host screens bind to `Get.find<CallController>()`.

State machine
```
idle ──placeCall──> dialing ──onUserJoined OR call_joined push (deduped)──> connected
idle ──incoming_call push──> ringing ──answer──> connecting ──onUserJoined──> connected
*    ──user_hangup / cancel push / unanswered timeout / error──> ended
```

---

## Prerequisites

- **Agora**: App ID. (App Certificate stays on the backend — never ship in any client.)
- **Firebase**: project + `firebase_messaging` already configured in the host app.
- **Backend**: implements the contract in `brain/docs/backend-specs/AGORA-CALLING.md`. The package only talks to:
  - `POST <tokenPath(rideId)>` — mint token (caller and callee both hit this).
  - `POST <cancelPath(rideId)>` — caller cancels before peer joins.
  - `PATCH <voipTokenPath>` — register the iOS PushKit token.
- **Flutter**: `>=3.16.0`. Dart `>=3.0.0 <4.0.0`.

---

## Installation

### Option A — path (recommended for monorepo / sibling layout)

```yaml
# host app pubspec.yaml
dependencies:
  agora_calling_package:
    path: ./agora_calling_package
    # or wherever you dropped the folder
```

### Option B — git (recommended for separate repos)

```yaml
dependencies:
  agora_calling_package:
    git:
      url: <your-internal-git-url>
      ref: main
```

Then:

```bash
flutter pub get
cd ios && pod install   # flutter_callkit_incoming has native pods
```

### Bundled dependencies

The package brings these in transitively. **Don't redeclare them in the host
app** unless you need a different range — duplicate constraints fight each
other:

| Concern | Package |
| --- | --- |
| RTC engine | `agora_rtc_engine` |
| State management | `get` |
| HTTP | `dio` |
| Push | `firebase_messaging` |
| Local notifications | `flutter_local_notifications` |
| iOS CallKit / Android Telecom CallStyle | `flutter_callkit_incoming` |
| Permissions | `permission_handler` |
| Audio playback | `audioplayers` |
| Vibration | `vibration` |

If a host app already pins one of these at a different version, the host's
pin wins and `pub get` will tell you about constraint conflicts.

---

## Per-app config

The only difference between **Selcom Go** and **Delivery Agent** lives in
this `AgoraCallingConfig`:

|  | Rider (Selcom Go) | Driver (Delivery Agent) |
| --- | --- | --- |
| `localRole` | `CallParticipantRole.rider` | `CallParticipantRole.driver` |
| `tokenPath` | `(id) => '/v4/go/rides/$id/call/token'` | `(id) => '/v1/app/agent/go/rides/$id/call/token'` |
| `cancelPath` | `(id) => '/v4/go/rides/$id/call/cancel'` | `(_) => '/v1/app/agent/go/rides/call/cancel'` (**no `:id`**) |
| `voipTokenPath` | `'/v4/go/user/voip-token'` | `'/v1/app/agent/go/voip-token'` |
| Auth header | `Authorization: Bearer <jwt>` | `access_token: <driverToken>` |
| Default peer label | `'Your Driver'` | `'Your Rider'` |
| iOS method channel | `com.selcom.go/voip` | `/voip` |
| `appName` | `'Selcom Go'` | `'Delivery Agent'` |

### Rider bootstrap

```dart
// lib/core/services/agora_calling_bootstrap.dart
import 'package:agora_calling_package/agora_calling_package.dart';
import '../config/app_config.dart';
import '../network/headers.dart';

class AgoraCallingBootstrap {
  AgoraCallingBootstrap._();

  static Future<void> init() async {
    await AgoraCalling.init(
      AgoraCallingConfig(
        appId: AppConfig.agoraAppId,
        baseUrl: AppConfig.baseUrl,
        getAuthHeaders: () async => commonHeaders(accessTokenRequired: true),
        localRole: CallParticipantRole.rider,
        appName: 'Selcom Go',
        endpoints: CallEndpoints(
          tokenPath:     (rideId) => '/v4/go/rides/$rideId/call/token',
          cancelPath:    (rideId) => '/v4/go/rides/$rideId/call/cancel',
          voipTokenPath: '/v4/go/user/voip-token',
        ),
        peerNameResolver: (_) => 'Your Driver',
      ),
    );
  }
}
```

### Driver bootstrap

```dart
// lib/core/services/agora_calling_bootstrap.dart
import 'package:agora_calling_package/agora_calling_package.dart';
import '../config/app_config.dart';

class AgoraCallingBootstrap {
  AgoraCallingBootstrap._();

  static Future<void> init() async {
    await AgoraCalling.init(
      AgoraCallingConfig(
        appId: AppConfig.agoraAppId,
        baseUrl: AppConfig.baseUrl,
        getAuthHeaders: () async => driverAuthHeaders(),
        localRole: CallParticipantRole.driver,
        appName: 'Delivery Agent',
        endpoints: CallEndpoints(
          tokenPath:     (rideId) => '/v1/app/agent/go/rides/$rideId/call/token',
          // Cancel intentionally ignores rideId — backend resolves from the
          // driver's current task per brain doc § 7.0.
          cancelPath:    (_)      => '/v1/app/agent/go/rides/call/cancel',
          voipTokenPath: '/v1/app/agent/go/voip-token',
        ),
        peerNameResolver: (_) => 'Your Rider',
      ),
    );
  }
}

// Minimum auth-headers helper if your driver app doesn't already have one:
Future<Map<String, String>> driverAuthHeaders() async {
  final token = await StorageService().read(StorageKeys.driverAccessToken) ?? '';
  return {
    'access_token': token,
    'Content-Type': 'application/json',
    // any device_id / app_version your driver backend expects:
    // 'device_id': await DeviceInfo.id(),
  };
}
```

---

## Wiring `main.dart`

Identical between both apps except the bootstrap reference. Steps in order:

```dart
import 'package:agora_calling_package/agora_calling_package.dart';
import 'core/services/agora_calling_bootstrap.dart';
import 'core/services/voip_callkit_bridge_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hand off Agora calling pushes to the package — it renders the incoming
  // ring via flutter_callkit_incoming (CallStyle on Android, CallKit on iOS),
  // and dismisses on `call_cancelled`.
  final type = (message.data['type'] ?? '').toString().toLowerCase();
  if (type == 'incoming_call' ||
      type == 'call_joined' ||
      type == 'call_cancelled') {
    await AgoraCallingNotificationService.firebaseBackgroundHandler(message);
    return;
  }

  // ... your existing background handling for ride updates, etc.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ... your AppConfig.init / di.init / etc.

  await AgoraCallingBootstrap.init();

  // Bridges native iOS PushKit/CallKit events into the package.
  await VoipCallkitBridgeService.instance.initialize();
  VoipCallkitBridgeService.instance.setOnVoipTokenChanged(
    AgoraCalling.registerVoipToken,
  );
  VoipCallkitBridgeService.instance.setOnIncomingCall(
    AgoraCalling.dispatchExternalIncomingCall,
  );

  runApp(const MyApp());
}
```

### Routes

```dart
// app_routes.dart
static List<GetPage> get pages => [
  ...AgoraCalling.routes(),     // <-- adds incoming + active call routes
  // ... your own pages
];
```

---

## Native: Android

Add to `android/app/src/main/AndroidManifest.xml`. The `tools` namespace on
the root `<manifest>` is **required** if you're upgrading from an older
version of this package that pulled in `flutter_background_service` — see
the troubleshooting table for the receiver-removal block you'll need.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
  <uses-permission android:name="android.permission.WAKE_LOCK"/>
  <uses-permission android:name="android.permission.VIBRATE"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  <!-- flutter_callkit_incoming registers a Telecom-based phoneCall foreground
       service; this permission is required for it on Android 14+. -->
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL"/>
  <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
</manifest>
```

`android/app/build.gradle`:
- `minSdkVersion 21` minimum (Agora RTC 6.x requirement).
- `coreLibraryDesugaringEnabled true` if not already enabled.

### Background continuity

The package does **not** start a generic foreground service for active
calls. Instead it relies on:

- The Agora RTC SDK keeping its own audio session alive while joined to the
  channel (the OS gives mic-capturing processes longer background runtime).
- `flutter_callkit_incoming`'s CallStyle ongoing notification (Telecom
  `phoneCall` foreground service) for the incoming-call ring.

This is intentional — the previous implementation used
`flutter_background_service`, which on Android 14+/16 (`targetSDK ≥ 34`)
runs into very strict FGS notification validation and trips
`CannotPostForegroundServiceNotificationException` whenever the channel,
icon, or `POST_NOTIFICATIONS` runtime permission isn't perfectly aligned.
Combined with its `WatchdogReceiver` (5-second alarm-driven respawn), any
single failure puts the app into a permanent boot-time crash loop. We
removed the dependency rather than fight it.

If you need a custom long-running call notification (for very aggressive
OEM skins like MIUI / ColorOS), call `FlutterCallkitIncoming.startCall(...)`
on `_markConnected` — that uses Telecom's `ConnectionService` which is the
right tool for the job. The package leaves that hook open without forcing it.

### Notification channels

The package creates one channel on init:

- `go_call_status` (default importance) — used by `flutter_local_notifications`
  for non-ringing call status updates (e.g. future `call_joined` toasts). It
  has no sound and is safe to mute.

`flutter_callkit_incoming` owns the **incoming-call** channel itself — it
shows up in **Settings → Apps → {your app} → Notifications** as `Incoming
Calls` (the `incomingCallNotificationChannelName` we pass via `AndroidParams`).
Don't try to create one from your host app; the plugin's native side does it.

### Battery / OEM whitelisting (Xiaomi MIUI, Realme, etc.)

For the most aggressive Android skins, users may need to whitelist the host
app for "autostart" / "battery optimisation" so an FCM data-only push wakes
the OS in killed state. There's no platform API for this — handle it with a
one-time onboarding prompt in the host app.

---

## Native: iOS

`ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>{App name} needs your microphone for in-app calls.</string>

<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>voip</string>
  <string>remote-notification</string>
</array>
```

In Xcode → Runner target → Signing & Capabilities:
- **+ Capability → Push Notifications**
- **+ Capability → Background Modes**
  - ☑ Voice over IP
  - ☑ Audio, AirPlay, and Picture in Picture
  - ☑ Remote notifications

### `AppDelegate.swift` template

The package can't take over your `AppDelegate`. Use this template — it's
identical between rider and driver except for the **two strings called out
in comments**:

```swift
import Flutter
import UIKit
import GoogleMaps  // delete if your app doesn't use Maps
import PushKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CXProviderDelegate {
  private var voipChannel: FlutterMethodChannel?
  private var pushRegistry: PKPushRegistry?
  private var callProvider: CXProvider?
  private let callController = CXCallController()
  private var pendingVoipEvents: [[String: Any]] = []
  private var callsByRideId: [String: UUID] = [:]
  private var ridesByCallId: [UUID: String] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    voipChannel = FlutterMethodChannel(
      // 🔵 RIDER:  "com.selcom.go/voip"
      // 🟠 DRIVER: "/voip"
      name: "com.selcom.go/voip",
      binaryMessenger: controller.binaryMessenger
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

  private func configurePushKit() {
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    self.pushRegistry = registry
  }

  private func configureCallKit() {
    let cfg = CXProviderConfiguration(
      // 🔵 RIDER:  "Selcom Go"
      // 🟠 DRIVER: "Delivery Agent"
      localizedName: "Selcom Go"
    )
    cfg.supportsVideo = false
    cfg.maximumCallsPerCallGroup = 1
    cfg.maximumCallGroups = 1
    cfg.supportedHandleTypes = [.generic]
    cfg.includesCallsInRecents = true
    let provider = CXProvider(configuration: cfg)
    provider.setDelegate(self, queue: nil)
    self.callProvider = provider
  }

  // MARK: - PushKit

  func pushRegistry(_ registry: PKPushRegistry,
                    didUpdate pushCredentials: PKPushCredentials,
                    for type: PKPushType) {
    guard type == .voIP else { return }
    let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    emitVoipEvent(method: "onVoipToken", arguments: ["token": token])
  }

  func pushRegistry(_ registry: PKPushRegistry,
                    didInvalidatePushTokenFor type: PKPushType) {
    guard type == .voIP else { return }
    emitVoipEvent(method: "onVoipToken", arguments: ["token": ""])
  }

  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType,
                    completion: @escaping () -> Void) {
    guard type == .voIP else { completion(); return }
    let raw = normalizePayload(payload.dictionaryPayload)
    guard let rideId = (raw["ride_id"] as? String).flatMap({ $0.isEmpty ? nil : $0 })
    else { completion(); return }

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
      if error != nil {
        self?.callsByRideId.removeValue(forKey: rideId)
        self?.ridesByCallId.removeValue(forKey: uuid)
        return
      }
      var args: [String: Any] = raw
      args["call_id"] = uuid.uuidString
      self?.emitVoipEvent(method: "onVoipIncomingCall", arguments: args)
    }
  }

  // MARK: - CXProvider

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
    for (k, v) in raw { if let key = k as? String { out[key] = v } }
    if let aps = out["aps"] as? [String: Any] {
      for (k, v) in aps where out[k] == nil { out[k] = v }
    }
    return out
  }

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
```

### `voip_callkit_bridge_service.dart` (Flutter side of the bridge)

Lives in the **host** repo (not the package), so each app can use its own
method-channel name. Drop in `lib/core/services/voip_callkit_bridge_service.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

class VoipCallkitBridgeService {
  VoipCallkitBridgeService._();
  static final VoipCallkitBridgeService instance = VoipCallkitBridgeService._();

  // 🔵 RIDER:  'com.selcom.go/voip'
  // 🟠 DRIVER: '/voip'
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

  void setOnIncomingCall(void Function(Map<String, dynamic> data)? sink) {
    _onIncomingCall = sink;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _voipToken = await StorageService().read(StorageKeys.voipToken);
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
        await StorageService().write(StorageKeys.voipToken, token);
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

Make sure your `StorageService` exposes a `voipToken` storage key. The rider
app's `StorageKeys` already has one — copy it across to the driver:

```dart
class StorageKeys {
  // ... existing keys ...
  static const String voipToken = 'voip_push_token';
}
```

---

## Placing a call (caller side)

```dart
import 'package:agora_calling_package/agora_calling_package.dart';

Future<void> onCallTapped(String rideId, String peerName, String? avatar) async {
  try {
    await AgoraCalling.controller.placeCall(
      rideId: rideId,
      peerDisplayName: peerName,
      peerAvatarUrl: avatar,
    );
  } on CallPermissionDeniedException catch (e) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Microphone permission needed'),
        content: const Text(
          'Allow microphone access in Settings to take voice calls.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          if (e.outcome == PermissionOutcome.permanentlyDenied)
            TextButton(
              onPressed: () { PermissionsHelper.openSettings(); Get.back(); },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
}
```

The package navigates to the `ActiveCallScreen` automatically. Caller pre-joins
the channel; the call flips to "Connected" the moment the peer answers.

## Receiving a call (callee side)

Nothing to wire on the host. Once `AgoraCalling.init` runs:

- **FCM `incoming_call` while app is in the foreground** → split by platform
  so you never get **two** Accept/Decline UIs at once:
  - **Android:** `IncomingCallScreen` only (full-screen in-app). The package
    does **not** also call `showCallkitIncoming` for foreground FCM — that
    used to stack a CallStyle notification on top of the in-app sheet.
  - **iOS:** `showCallkitIncoming` (CallKit) only. The package does **not**
    open `IncomingCallScreen` for the same push (CallKit is the incoming
    surface). PushKit-delivered calls use native CallKit from `AppDelegate`
    the same way — no duplicate Flutter sheet.
- **FCM `incoming_call` while app is background / killed (Android)** → the
  registered background handler shows `showCallkitIncoming` (CallStyle +
  full-screen activity). iOS background ringing is normally via VoIP → CallKit
  in the host `AppDelegate`.
- **User accepts** (notification **or** in-app, whichever is shown) →
  `Event.actionCallAccept` from `FlutterCallkitIncoming.onEvent` when the user
  used the native UI; otherwise the in-app screen calls `answer()`. Either way
  `_acceptIncoming` coalesces duplicate taps (`_acceptMutex`), pops the in-app
  sheet if it was open, calls `setCallConnected` + on Android
  `hideCallkitIncoming` to **stop the shade ring immediately**, then mints
  and joins. `ActiveCallScreen` opens after token is ready.
- **iOS killed-state APNs VoIP** → handled in `AppDelegate.swift` →
  `CXProvider.reportNewIncomingCall` natively, then forwarded to the package
  via the `voip` method channel.
- **Killed-state Accept (Android)**: when an FCM push arrived while the app
  was dead and the user taps Accept on the lock screen, the OS launches the
  app, the buffered `actionCallAccept` event is replayed once
  `CallController.bootstrap()` subscribes, and the controller reconstructs
  `currentCall` from `event.body` (`_seedIncomingFromBody`) before joining.
  No additional host wiring needed — but the FCM push **must** be data-only
  with `priority: high` so the OS hands it to the background isolate.
- **Backend pushes `call_cancelled`** if the caller hangs up first → package
  calls `FlutterCallkitIncoming.endAllCalls()` to dismiss the ring on both
  platforms.

---

## Public API

### `AgoraCalling`

| Member | Type | Purpose |
| --- | --- | --- |
| `init(config)` | `Future<void>` | Wires DI, FCM listeners, notification channel, and CallKit/CallStyle. Idempotent. |
| `routes()` | `List<GetPage>` | Register on `GetMaterialApp.getPages`. |
| `controller` | `CallController` | Convenience accessor. |
| `registerVoipToken(token)` | `Future<void>` | PATCH the iOS PushKit token. Wire to your VoIP bridge. |
| `dispatchExternalIncomingCall(data)` | `void` | Forward a PushKit-delivered payload from your bridge into the package. |

### `CallController` (GetX)

| Member | Type | Purpose |
| --- | --- | --- |
| `state` | `Rx<CallState>` | Current state machine value |
| `currentCall` | `Rxn<CallModel>` | Current call (or `null` when idle) |
| `muted` | `RxBool` | Mic muted |
| `speakerOn` | `RxBool` | Speaker route |
| `connectedSeconds` | `RxInt` | Call duration (1Hz, after `connected`) |
| `endReason` | `Rxn<CallEndReason>` | Why the last call ended |
| `errorMessage` | `RxnString` | Set when state is `error` |
| `placeCall({rideId, peerDisplayName, peerAvatarUrl})` | `Future<void>` | Outgoing |
| `answer()` | `Future<void>` | Callee accepts |
| `reject()` | `Future<void>` | Callee declines |
| `hangUp()` | `Future<void>` | Either side ends — picks `cancel` vs `leaveChannel` automatically |
| `toggleMute()` | `Future<void>` |  |
| `toggleSpeaker()` | `Future<void>` |  |

### Models

- `CallModel` — immutable, keyed by `rideId`. `peerDisplayName` / `peerAvatarUrl` flow into the UI.
- `CallState` — `idle, dialing, ringing, connecting, connected, ended, error`.
- `CallEndReason` — `localHangup, remoteHangup, remoteCancelled, unanswered, remoteOffline, disconnected, rejectedByLocal, error`.
- `CallParticipantRole` — `rider | driver`.
- `CallEndpoints` — host-supplied REST paths.
- `AgoraCallingConfig` — all knobs.

### Services (advanced)

Exported for host apps that want raw access:
- `AgoraCallingNotificationService` — `pushStream` for raw FCM/PushKit events.
- `CallApiService` — `mintToken`, `cancelCall`, `registerVoipToken`.
- `AgoraService` — direct `RtcEngine` access if you need to hook audio-volume indication or reuse the engine.

---

## Push payload contract

Sent by your backend, consumed by the package. Three types only.

### `incoming_call`

```json
{
  "data": {
    "type": "incoming_call",
    "ride_id": "ride_123",
    "channel": "ride_ride_123",
    "caller_role": "driver",
    "caller_name": "John"
  }
}
```

- Android: must be **data-only** (no top-level `notification` block) +
  `priority: high` so the OS hands it to the background isolate.
- iOS with VoIP token: must go through APNs VoIP (PushKit). The package
  receives via your `AppDelegate.swift` and the `com.selcom.{app}/voip`
  method channel.
- iOS without VoIP token: same shape via FCM; package falls back to
  `flutter_callkit_incoming` to render CallKit.

> The package never accepts an Agora token from the push payload. Token mint
> happens server-to-client on the participant's own backend call.

### `call_joined`

```json
{ "data": { "type": "call_joined", "ride_id": "ride_123" } }
```

Sent to the **caller** when the callee mints their token. Mirrors Agora SDK
`onUserJoined`; the package dedupes — whichever fires first transitions UI to
"Connected".

### `call_cancelled`

```json
{ "data": { "type": "call_cancelled", "ride_id": "ride_123" } }
```

Sent to the **callee** when the caller hangs up before connect. Package
calls `FlutterCallkitIncoming.endAllCalls()` to dismiss the ring on both
platforms.

> **iOS:** `call_cancelled` is **always FCM** — never APNs VoIP. PushKit can
> only create CallKit UIs, not dismiss them. Don't try to handle this in
> `AppDelegate.swift`.

---

## Debug logging

Every notable transition emits a `debugPrint` (only in debug builds) with a
two-letter scope tag. Filter by either tag to see the full lifecycle:

| Tag | Source | What it covers |
| --- | --- | --- |
| `[AGORA_CTRL]` | `controllers/call_controller.dart` | State machine, CallKit events, `placeCall`, accept/decline path, killed-state seeding (`_seedIncomingFromBody`), hangup, terminate |
| `[AGORA_NOTIF]` | `services/notification_service.dart` | Every FCM message we see (including unrecognised types), CallKit-show, dismiss |
| `[AGORA_API]` | `services/call_api_service.dart` | `mintToken` / `cancelCall` request paths and response status codes |

```bash
# Android
adb logcat -s flutter | grep -E '\[AGORA_(CTRL|NOTIF)\]'

# iOS (sim or attached device, lldb console)
log stream --predicate 'eventMessage CONTAINS "[AGORA_"' --level debug
```

A normal callee accept flow looks like:

```
[AGORA_NOTIF] fg push type=incoming_call data={...}
[AGORA_NOTIF] showCallkitIncoming rideId=ride_123 callerName=John
[AGORA_CTRL] callkit event=actionCallAccept body={...}
[AGORA_CTRL] seeded ringing call ride_123
[AGORA_CTRL] _acceptIncoming start state=ringing currentCall=ride_123
[AGORA_CTRL] joining channel=ride_ride_123 uid=...
[AGORA_CTRL] state -> connecting
[AGORA_CTRL] state -> connected
```

If accept / decline taps silently do nothing, look for a missing
`callkit event=actionCallAccept` line — that means the buffered CallKit
event never reached the controller (most often because `bootstrap()` ran
before the push arrived in killed state, which is fine — the plugin
replays it; if it doesn't, see the troubleshooting row below).

### Verifying that a callee actually receives the push

When the *caller* says "I tapped Call but the other side never rang", grep
both devices in parallel:

```bash
# Caller side — confirm the mint API was hit
adb logcat -s flutter | grep -E '\[AGORA_(CTRL|API)\]'
#   expect:
#   [AGORA_CTRL] placeCall rideId=... state=idle
#   [AGORA_API] POST /v4/go/rides/.../call/token (mintToken rideId=...)
#   [AGORA_API] POST /v4/go/rides/.../call/token -> 200

# Callee side — confirm the FCM `incoming_call` push actually arrived
adb logcat -s flutter | grep -E '\[AGORA_NOTIF\]'
#   expect:
#   [AGORA_NOTIF] fg push type="incoming_call" has_notification=false data={...}
#   [AGORA_NOTIF] showCallkitIncoming rideId=... peer=...
```

If the **caller** side shows `POST .../call/token -> 200` but the
**callee** side shows nothing at all, the FCM push isn't reaching that
device. That's an upstream issue — frontend code is fine. Check, in order:

1. **FCM token** — the host app sends it on every authenticated request as
   the `device_token_rider` header. If the user just logged in, force one
   round-trip API call (e.g. fetch profile) before testing, so the backend
   has the freshest token mapped to that user.
2. **Push payload shape** — confirm the backend is sending **data-only**
   (no `notification` block) for `type=incoming_call` on Android. A
   `notification` block in the payload also triggers `[AGORA_NOTIF]` logs
   (you'll see `has_notification=true`), but on Android in killed state
   the OS may swallow the data callback and only show the notification.
3. **Battery / OEM autostart** — covered in the Android section above.

If the callee logs `[AGORA_NOTIF] fg push type="incoming_call"` but the
incoming UI never appears, look for one of these on the next line:
- `_handleIncomingPush state=...` — controller saw it.
- `ignoring incoming — already in call` — a previous call left state
  stuck (we now allow `error` to be overridden, but `connected` etc. will
  still be respected — that's correct).
- *(nothing)* — the broadcast `_pushes` stream had no listener at the
  time, which is exactly the init-order race fixed in v0.2.2. If you see
  this on a recent build, file an issue.

### Verifying iOS incoming-call delivery (PushKit / VoIP)

iOS routes incoming calls **differently from Android**: the host app's
`AppDelegate.swift` registers a `PKPushRegistry`, receives the VoIP push
natively, and surfaces CallKit *before* any Dart code runs. The Dart
package only sees the call after CallKit has already been shown. So if
you see "nothing happens at all on iOS in every state", the failure is
upstream of any Dart code — either the **VoIP token isn't reaching the
backend** or the **backend isn't sending a VoIP push**.

Open Xcode → Product → Scheme → Edit Scheme → Run → Arguments → Environment
Variables (or just attach the device with `Window → Devices and Simulators`
→ select device → "Open Console") and filter on `[VOIP_NATIVE]` and
`[VOIP_BRIDGE]`:

```
# Step A — At app launch, you should see ONCE per device:
[VOIP_NATIVE] PKPushRegistry configured, requested types=[.voIP]
[VOIP_NATIVE] PKPushRegistry didUpdate VoIP token len=64 prefix=a1b2c3d4…
[VOIP_NATIVE] emit method=onVoipToken (channel ready)
[VOIP_BRIDGE] token received len=64
[AGORA_API] PATCH /v4/go/user/voip-token (registerVoipToken tokenLen=64)
[AGORA_API] PATCH /v4/go/user/voip-token -> 200
[AGORA_API] registerVoipToken OK — backend should now have a VoIP token for this user

# Step B — When DA Android places a call, you should see:
[VOIP_NATIVE] didReceiveIncomingPushWith type=PKPushType(_rawValue: PKPushTypeVoIP) payload=[ride_id: ...]
[VOIP_NATIVE] reporting incoming call rideId=... caller=Your Driver
[VOIP_NATIVE] reportNewIncomingCall OK rideId=... uuid=...
[VOIP_BRIDGE] onVoipIncomingCall received args={...}
```

Diagnose by which step is missing:

| Missing step | Diagnosis | Fix |
| --- | --- | --- |
| **No `PKPushRegistry didUpdate VoIP token`** | iOS device never got a VoIP token | Check Xcode → target → Signing & Capabilities → "Push Notifications" capability is enabled; check `Runner.entitlements` has `aps-environment`; verify device has internet at first launch; if installed via TestFlight/App Store, your `aps-environment` must be `production` (currently `development` in this repo — see entitlements file) |
| **`PATCH /v4/go/user/voip-token -> 401/403`** | Auth header missing or stale when token registered | Token registration runs at app launch *after* `commonHeaders` is built — make sure the user is logged in (a fresh install with no JWT will fail this PATCH); on next launch with a valid JWT it'll succeed |
| **`PATCH /v4/go/user/voip-token -> 404`** | Endpoint not implemented yet on backend | Backend must expose `PATCH /v4/go/user/voip-token` accepting `{ "voip_push_token": "<hex>" }`; until it does, iOS calls will not ring in background/killed |
| **`PATCH /v4/go/user/voip-token -> 200` but no `didReceiveIncomingPushWith`** | Backend has the token but is **not sending a VoIP push** for this call | Backend must use the **VoIP APNs topic** (`<bundleId>.voip`) and the **VoIP push** payload shape (`{ "ride_id": ..., "channel": ..., "caller_role": ..., "caller_name": ..., "type": "incoming_call" }`); regular APNs / FCM-to-iOS will NOT wake the app or trigger CallKit |
| **`didReceiveIncomingPushWith` arrives but no `reportNewIncomingCall OK`** | Push payload missing `ride_id`, or `CXProvider` rejected the call | Verify the payload includes `ride_id`; check that no other CallKit-using SDK (e.g. WhatsApp-style) is conflicting; ensure `Settings → Phone → Silence Unknown Callers` is OFF |
| **All native logs present but no `[VOIP_BRIDGE] onVoipIncomingCall received`** | Method channel name mismatch or Dart side not initialized | Confirm the channel is `com.selcom.go/voip` on both sides; confirm `VoipCallkitBridgeService.instance.initialize()` runs in `main()` |

**TestFlight / production build note:** `Runner.entitlements` currently
hard-codes `aps-environment = development`. APNs **silently drops** any
push whose environment doesn't match the receiving device's environment.
Before shipping to TestFlight or App Store, switch this to `production`
(or use a release-build xcconfig override) — otherwise no iOS push will
ever arrive on those builds, and the user will see exactly the symptom
"nothing happens at all in every state".

---

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Android killed-state push doesn't ring | Backend sent payload with a top-level `notification` block | Send data-only push for `type=incoming_call` |
| Incoming call push never opens ringing UI (no `_handleIncomingPush` after `[AGORA_NOTIF] … incoming_call`), especially right after app launch | `CallController.bootstrap()` subscribed to `pushStream` **after** `AgoraCallingNotificationService.initialize()` started firing FCM events — broadcast stream dropped early events | Fixed in **v0.2.2**: `AgoraCalling.init` now calls `controller.bootstrap()` **before** `notif.initialize()`. See **Debug logging → Verifying that a callee actually receives the push** |
| Next incoming call is ignored after a failed attempt (mic denied, mint error, etc.) | Prior session left `CallState.error`; old guard treated `error` like an in-flight call and dropped new `incoming_call` pushes | Fixed in **v0.2.2**: only `dialing` / `ringing` / `connecting` / `connected` block a new incoming call |
| Two Accept/Decline UIs at once (notification + full-screen incoming), or accepting one leaves the other ringing | Foreground FCM used to call `showCallkitIncoming` **and** open `IncomingCallScreen` on Android; iOS could stack CallKit + in-app sheet | Fixed in **v0.2.3**: Android foreground = in-app sheet only; iOS = CallKit / native VoIP only (no duplicate `IncomingCallScreen`). Accept path clears native ring via `hideCallkitIncoming` on Android and dedupes double-tap (`_acceptMutex`) |
| Accept on Android lock-screen / notification (background or **killed** state) launches the app but the call screen never appears, audio sometimes also drops within the same second | Two compounding bugs: (1) `actionCallAccept` reaches the controller **before** the host's `GetMaterialApp` is mounted, so `Get.toNamed(ActiveCallScreen.routeName)` is a silent no-op (no Navigator yet); (2) backend sends the FCM twice (typical "notification + data" split on Android), `_showFromBackground` calls `showCallkitIncoming` twice, then two parallel `_acceptIncoming` runs both pass `_engine != null` during `AgoraService.ensureInitialized`'s long async path → two `RtcEngine` instances → second `joinChannel` returns `-17 ERR_JOIN_CHANNEL_REJECTED` and the failure path tears the live audio down | Fixed in **v0.2.4**: ① `_openActiveCallScreen` / `_openIncomingCallScreen` poll `Get.key.currentState` every 100 ms (up to 8 s) before pushing — if the navigator attaches later we still surface the call screen, and we abort cleanly when the call ends meanwhile. ② `_showFromBackground` and `_onForegroundMessage` dedupe `(type, ride_id)` within a 10 s window. ③ `AgoraService.ensureInitialized` and `CallController._ensureAgoraReady` cache their in-flight `Future` so concurrent callers share one engine. ④ `_joinChannelFor` short-circuits if `_joinedChannelName` already matches the incoming channel. **If you see this regress:** filter logcat for `[AGORA_CTRL] navigator not ready` (confirms fix-① is engaged) and `[AGORA_NOTIF] bg push dropped — duplicate` (confirms fix-② is engaged). |
| Accept / Decline tap on the incoming UI does nothing and no `[AGORA_CTRL] callkit event=…` line is logged | Host app isn't calling `AgoraCalling.init` early enough — `FlutterCallkitIncoming.onEvent` only buffers a small backlog, and a long pre-init pipeline can drop it | Move `AgoraCallingBootstrap.init()` ahead of any heavy splash/animation/`runApp` work in `main()` |
| Accept tap is registered (`callkit event=actionCallAccept` logged), state moves `ringing → connecting`, but the call never connects and the caller's side keeps ringing as if no one answered | A self-induced `actionCallEnded` ricochet — `FlutterCallkitIncoming.endAllCalls()` was being called inside `_acceptIncoming` to dismiss the ring, which round-trips an `actionCallEnded` event back through `FlutterCallkitIncoming.onEvent` and tears down the freshly-accepted call mid-mint | Already fixed in the package as of v0.2.1 — the controller now calls `FlutterCallkitIncoming.setCallConnected(rideId)` after a successful join (which transitions the native UI cleanly without re-firing end events) and an `_acceptInProgress` guard suppresses any straggler `actionCallEnded` between Accept-tap and Join-complete. If you see this regress in a fork: do **not** call `endAllCalls()` from the accept path |
| iOS killed-state push doesn't ring | Sent through alert APNs instead of VoIP | Wire backend to APNs VoIP using the registered PushKit token |
| Phantom CallKit ring after caller cancelled | `call_cancelled` not delivered or app missed the FCM | Check FCM delivery logs; verify `_firebaseMessagingBackgroundHandler` forwards `call_cancelled` to the package |
| Mic toggle doesn't reach peer | A custom Agora engine is overriding `muteLocalAudioStream` | Don't override `AgoraService` — let the package own the engine |
| Call connects but no audio | Token role on the backend is not `PUBLISHER` | Backend must mint with `RtcRole.PUBLISHER` for both parties (see brain doc) |
| `state` stays `dialing` indefinitely | Backend never pushed `incoming_call` to peer (or peer's FCM token is stale) | Inspect backend FCM/APNs delivery logs; rotate device token on next login |
| Token-refresh thrashing | Backend issuing tokens with TTL shorter than typical call duration | Increase `AGORA_TOKEN_TTL_SECONDS` server-side (24 h recommended) |
| App crashes opening Active Call screen | Routes not registered | Ensure `...AgoraCalling.routes()` is spread into `GetMaterialApp.getPages` |
| Android crashes with `CannotPostForegroundServiceNotificationException: Bad notification for startForeground` after upgrading from an older version of this package | A `flutter_background_service` `WatchdogReceiver` from a previous install is still scheduled in `AlarmManager` and tries to respawn the no-longer-declared service | Add `<receiver android:name="id.flutter.flutter_background_service.WatchdogReceiver" tools:node="remove" />` and the same for `BootReceiver` to your manifest. After installing once with that change, the alarm is cleared on the next reboot |

---

## Testing checklist

Run against **two physical devices** (iOS Simulator does not deliver PushKit
reliably).

**Both platforms:**
- [ ] Caller (foreground) → callee (foreground) → connected → caller hangs up
- [ ] Caller hangs up while `dialing` → callee's ringing UI dismisses
- [ ] Callee declines → caller's UI ends within 1s (or unanswered timeout)
- [ ] Caller's network drops mid-call → both transition to `ended` (`disconnected`)
- [ ] Mic permission denied first time → friendly "Open Settings" dialog
- [ ] Token refresh fires on `onTokenPrivilegeWillExpire` without audio gap
- [ ] Cancel button shown before `onUserJoined`; End Call after
- [ ] `call_joined` push and `onUserJoined` both observed without double UI flip

**Android:**
- [ ] CallStyle heads-up notification with Accept / Decline buttons when app is foreground
- [ ] Full-screen lock-screen incoming UI (`CallkitIncomingActivity`) when app is background or device locked
- [ ] Notification channel **Incoming Calls** (owned by `flutter_callkit_incoming`) visible under Settings → Apps → {your app} → Notifications
- [ ] Killed-state Accept on the lock screen: app launches, buffered CallKit event replays, `[AGORA_CTRL]` logs show `_seedIncomingFromBody` followed by `_acceptIncoming` → join
- [ ] `call_cancelled` FCM received in background dismisses the CallStyle heads-up

**iOS — both apps:**
- [ ] VoIP token registered with backend after login
      (`PATCH /v4/go/user/voip-token` for rider /
       `PATCH /v1/app/agent/go/voip-token` for driver → 200)
- [ ] Incoming call rings on locked screen via CallKit
- [ ] Declining on CallKit does NOT join the Agora channel
- [ ] `NSMicrophoneUsageDescription` prompt appears on first call
- [ ] `call_cancelled` FCM dismisses CallKit (no phantom ringing)

---

## Audio assets

The package references these defaults; drop your tracks under
`assets/sounds/` before release (or override paths via `AgoraCallingConfig`):

- `ringback.mp3` — caller hears while waiting for callee.
- `ringtone.mp3` — callee hears while ringing.
- `call_end.mp3` — short tone on terminate.

Missing files don't crash — the audio helpers wrap each play in try/catch.

---

## Cross-app reuse — quick reference

Everything you need to flip a fresh app from rider to driver — top-down:

1. Add the package to `pubspec.yaml`.
2. New `lib/core/services/agora_calling_bootstrap.dart` with
   `localRole: CallParticipantRole.driver` and the `/v1/app/agent/go/...` paths.
3. New `lib/core/services/voip_callkit_bridge_service.dart`, change channel name
   to `/voip`.
4. New `ios/Runner/AppDelegate.swift` from the template, change channel name +
   CallKit `localizedName`.
5. Wire `main.dart` (background handler forwarder + `init` block) — same as rider.
6. Add `...AgoraCalling.routes()` to `GetMaterialApp.getPages`.
7. Replace your existing "Call Rider" button handler with
   `AgoraCalling.controller.placeCall(rideId, peerDisplayName, peerAvatarUrl)`.
8. Add Android manifest permissions.
9. Add iOS `Info.plist` entries + Xcode capabilities.
10. `flutter pub get && cd ios && pod install`.

The package itself never changes between the two apps.

---

## Limitations / out-of-scope

- Group calls (3+ participants) — single channel, single peer. The state
  machine assumes one `onUserJoined` to flip to `connected`.
- Video — engine wrapper hard-codes `disableVideo()`. Trivial to extend.
- Call recording — not implemented. Compliance-sensitive; route through
  backend if needed.

---

## License

Internal — Selcom. Do not redistribute.
