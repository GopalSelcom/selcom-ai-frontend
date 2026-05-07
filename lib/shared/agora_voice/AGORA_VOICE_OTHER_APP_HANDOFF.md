# Agora Voice — Other-app handoff (full integration)

This doc is everything the **other app** (driver / agent) needs to bring up voice calling end-to-end on Android and iOS, against the same backend voice-call contract the rider app uses.

It is self-contained. You should not need any internal `brain/docs/...` to wire this up.

Companion docs in this folder:

- `README.md` — module-level overview of `lib/shared/agora_voice/`
- `CROSS_APP_CHANGELOG_HANDOFF.md` — minimal diffs to mirror (call_joined, single-pop, dedupe-invite)

This doc supersedes them when standing up voice calling on a new app.

---

## 1) Backend contract recap (do not deviate)

Backend owns: token issuance, signaling delivery, push delivery for incoming wake, cancellation broadcast.

### 1.1 Ride-scoped identity

- Every call interaction includes `ride_id`.
- Channel naming is deterministic and identical for both users:
  - `channel = ride_<rideId>` (sanitize non-alphanumeric to `_`).

### 1.2 Signaling event types (rider ↔ driver realtime channel)

- `invite`, `accept`, `reject`, `end`
- Delivered in order per `ride_id`.

### 1.3 Incoming call push payload

```json
{
  "type": "incoming_call",
  "ride_id": "<rideId>",
  "channel": "ride_<rideId>",
  "caller_id": "<opaque>",
  "caller_name": "<display name>",
  "caller_role": "rider" | "driver"
}
```

Token is **never** in the push payload. Receiver mints its own token on answer.

### 1.4 Cancellation push payload

```json
{
  "type": "call_cancelled",
  "ride_id": "<rideId>"
}
```

### 1.5 Caller-side connected signal (optional but recommended)

```json
{
  "type": "call_joined",
  "ride_id": "<rideId>"
}
```

The caller treats `call_joined` as equivalent to Agora `onUserJoined` for the “Connected” UI. Dedupe with the SDK callback.

### 1.6 Platform delivery

- **Android**: incoming call push must be **data-only**. No top-level `notification` key. High priority.
- **iOS**: incoming call wake **must** use **APNs VoIP** push (PushKit). Standard alert APNs cannot wake a killed app to ring reliably.

### 1.7 Token endpoint shape

Driver app endpoint (mirror; rider uses `/v4/go/...`):

```
POST /v4/agent/go/rides/:rideId/call/token
```

Success envelope:

```json
{
  "status_code": 200,
  "data": {
    "app_id": "...",
    "channel": "ride_<rideId>",
    "token": "<rtc_token>",
    "uid": 1234567890,
    "expires_at": "<iso8601>"
  }
}
```

If backend returns `503 FEATURE_DISABLED`, hide/disable the call CTA.

---

## 2) What to copy from the rider repo

Drop these into the driver app **as-is** (they’re portable; do not edit):

- `lib/shared/agora_voice/` — full folder.
- `lib/core/services/voip_callkit_bridge_service.dart` — iOS PushKit/CallKit ↔ Flutter bridge (works as-is on Android too; it just no-ops there).
- `ios/Runner/AppDelegate.swift` — copy the PushKit + CallKit sections (keep your existing plugin registration and Maps key).

You will rewrite these per-app:

- The host integration in your “active ride / active task” feature controller (analog of `driver_accepted_controller.dart`).
- Your token provider header strategy (`Authorization` vs `access_token`, etc.).
- The backend endpoint path + the VoIP-token-register path.

---

## 3) iOS native setup

### 3.1 `Info.plist`

Add:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>App needs microphone access for in-app voice calls.</string>

<key>NSVoIPUsageDescription</key>
<string></string>

<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
  <string>audio</string>
  <string>voip</string>
  <!-- keep your existing modes -->
</array>
```

### 3.2 Capabilities (Xcode)

- Push Notifications
- Background Modes: **Voice over IP**, **Audio, AirPlay, and Picture in Picture**, **Remote notifications**

### 3.3 `AppDelegate.swift` — required pieces

The full reference implementation lives in `ios/Runner/AppDelegate.swift` of the rider repo. Critical contract-driven invariants:

- `desiredPushTypes = [.voIP]`
- `extractRideId(from:)` returns `String?`. **Drop pushes without `ride_id`** — never fabricate.
- `callerDisplayName(from:)` prefers `caller_name`, falls back to a role-based label only when missing.
- VoIP token (`pushRegistry(_:didUpdate:for:)`) is forwarded to Flutter via `MethodChannel("com.selcom.go/voip")` as `onVoipToken { token: <hex> }`.
- VoIP push (`pushRegistry(_:didReceiveIncomingPushWith:for:completion:)`):
  - `incoming_call` → `reportNewIncomingCall(...)` then `onVoipIncomingCall` to Flutter.
  - `call_cancelled` → end the existing call, then `onVoipCallCancelled` to Flutter.
- CallKit:
  - `CXAnswerCallAction` → `onVoipCallAccepted` to Flutter.
  - `CXEndCallAction` → `onVoipCallCancelled` to Flutter.
- Pending-event queue (`UserDefaults` key `pending_voip_events`) — events delivered before the Flutter engine is up are persisted and consumed by the bridge on first `initialize()`.

### 3.4 iOS PushKit reliability rule (read this once)

iOS 13+ requires `reportNewIncomingCall(...)` to be called for **every** received VoIP push, otherwise PushKit registration can be revoked. The current implementation honors this for `incoming_call`. For `call_cancelled` it relies on a previously reported call existing for that `ride_id`. If you expect cancellations without a prior incoming (race / app-killed-then-cancel), add a “report-then-immediately-end” path — open a follow-up if you need it.

---

## 4) Android native setup

### 4.1 `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

`MainActivity` should set `showWhenLocked` and `turnScreenOn` so full-screen intent rings on locked devices.

### 4.2 Notification channel

Create one channel id `go_incoming_calls` (importance MAX, sound + vibration). Show incoming-call notifications with:

- `category = AndroidNotificationCategory.call`
- `fullScreenIntent: true`
- `priority: Priority.max`
- `audioAttributesUsage: AudioAttributesUsage.notificationRingtone`
- `visibility: NotificationVisibility.public`

This is implemented in `NotificationService.showIncomingCallNotification(...)`. Mirror it.

### 4.3 FCM background handler

Register `_firebaseMessagingBackgroundHandler` (top-level, `@pragma('vm:entry-point')`). It must:

- Initialize Firebase.
- For `type == incoming_call` → show the `go_incoming_calls` notification (full-screen intent).
- For `type == call_cancelled` → cancel the same notification id (`incoming_call_<rideId>.hashCode`).

See `lib/main.dart` `_showAndroidIncomingCallNotification` for the reference implementation.

---

## 5) Flutter integration

### 5.1 Pubspec dependencies

```bash
flutter pub add agora_rtc_engine permission_handler dio get \
  firebase_messaging firebase_core flutter_local_notifications \
  flutter_secure_storage audioplayers vibration uuid
```

### 5.2 Bootstrap order in `main.dart`

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(...);
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

// after DI / config
await NotificationService().initialize();
await VoipCallkitBridgeService.instance.initialize();

// register VoIP token with backend whenever it changes
VoipCallkitBridgeService.instance.setOnVoipTokenChanged((token) async {
  await yourUserApi.registerVoipPushToken(token);
});
```

### 5.3 Token provider (driver-app variant)

```dart
RideCallHttpTokenProvider(
  dio: dio,
  tokenPathBuilder: (id) => '/v4/agent/go/rides/${id.trim()}/call/token',
  headersProvider: () => commonHeaders(accessTokenRequired: true),
);
```

### 5.4 Per-ride wiring (mirrors `DriverAcceptedController`)

When the driver opens an active ride/task, build the incoming-call handler and register the three FCM bridges:

```dart
final signaling = RideChatCallSignalingService(
  rideId: rideId, socketService: appSocket,
);
await signaling.start();

final handler = AgoraVoiceIncomingCallHandler(
  signalingService: signaling,
  localClientId: localClientId,
  rideId: rideId,
  localDisplayName: 'Driver',
  canStartCall: () => hasCallApiConfig(),
  buildController: (event) => AgoraVoiceCallController(
    engineService: AgoraVoiceEngineService(tokenProvider: tokenProvider),
    session: AgoraVoiceCallSession(rideId: event.rideId),
    onLocalEndRequested: () => _sendCallEndSignal(
      channelName: event.channelName, rideIdForSignal: event.rideId,
    ),
    enableRingbackOnConnectFlow: false, // callee path
    enableUnansweredTimeout: false,
  ),
  getActiveController: () => _inAppCallController,
  setActiveController: (c) => _inAppCallController = c,
  closeCallRouteIfOpen: _closeInAppCallScreenIfOpen,
  onRejectCallApi: (id) => callApi.cancelVoiceCall(id),
);

AgoraIncomingCallNotificationBridge.instance.register(
  rideId: rideId,
  onIncoming: (raw) => handler.handleIncomingCallPush(
    raw, callerId: 'fcm', callerName: _remoteCallerLabelFromPush(raw),
  ),
);

AgoraCallCancelNotificationBridge.instance.register(
  rideId: rideId,
  onCancelled: (_) async {
    final c = _inAppCallController;
    if (c == null) { _closeInAppCallScreenIfOpen(); return; }
    c.stopIncomingRingtone();
    await c.endCallFromRemote(reason: AgoraVoiceCallEndReason.remoteEnded);
  },
);

AgoraCallJoinedNotificationBridge.instance.register(
  rideId: rideId,
  onJoined: (_) async {
    final c = _inAppCallController;
    if (c == null) return;
    c.stopIncomingRingtone();
    await c.markConnectedFromSignal();
  },
);
```

Unregister all three in `onClose` and dispose the handler.

### 5.5 `NotificationService` foreground hooks

Foreground FCM `_onForegroundMessage` should branch on `data['type']`:

| `type` | Foreground action |
|---|---|
| `incoming_call` | Skip if iOS system call UI active for that `ride_id`; otherwise deliver to `AgoraIncomingCallNotificationBridge`, queue navigation, show local incoming-call notification. |
| `call_cancelled` | Deliver to `AgoraCallCancelNotificationBridge`; cancel the local incoming-call notification. |
| `call_joined` | Deliver to `AgoraCallJoinedNotificationBridge`; cancel the local incoming-call notification. |
| anything else | Show ordinary notification + ride-tracking sticky update. |

`_onMessageOpenedApp` and `getInitialMessage()` paths must funnel into a single `_handleNotificationNavigationRaw(raw)` so cold-start taps reach the same bridge dispatcher.

### 5.6 iOS system-CallKit dedupe

When PushKit fires `onVoipIncomingCall`, the bridge calls `NotificationService().markSystemIncomingActive(rideId)` so any concurrent FCM `incoming_call` for the same ride **does not** also open the in-app incoming UI on top of CallKit. On accept/cancel, mark cleared. The reference is in `VoipCallkitBridgeService._dispatch` and `NotificationService.handleSystemIncoming*`.

### 5.7 Channel-name normalization (contract)

Both clients must produce the same `channel`. The bridge’s `_resolveChannelForRide(...)` enforces `ride_<sanitized rideId>` if backend ever omits the field. Do not add a second sanitizer in feature code — use the helper in `_voiceChannelName()` (controller) or the signal model.

---

## 6) End-to-end flows

### 6.1 Outgoing (driver calls rider)

1. Driver taps Call → `signaling.sendEvent(invite, channel=ride_<id>)`.
2. Driver UI builds `AgoraVoiceCallController` and calls `startCall()` (mints token, joins channel).
3. Backend pushes `incoming_call` (data-only Android / VoIP iOS) to rider.
4. Rider answers → emits `accept` → mints token → joins same channel.
5. Backend optionally pushes `call_joined` to driver — driver UI flips to “Connected” via `markConnectedFromSignal()` deduped with `onUserJoined`.
6. Either side hangs up → emits `end` → both ends teardown once.

### 6.2 Reject

1. Rider taps Reject → emits `reject` → calls cancel-call API → ends locally without re-emitting.
2. Driver receives `reject` → `endCallFromRemote(remoteRejected)` → UI shows “Call declined”.

### 6.3 Forced cancel (ride lifecycle)

1. Backend determines the call is no longer valid → sends `call_cancelled` to both parties.
2. Each client dismisses its incoming UI / connected UI:
   - Active controller → `endCallFromRemote(remoteEnded)`.
   - No controller → close call route only.

---

## 7) Per-platform pitfalls (port-time)

| # | Pitfall | Mitigation |
|---|---|---|
| 1 | Android `notification`-only payload kills wake-up | Backend sends data-only; client handler reads `message.data['type']`. |
| 2 | iOS APNs alert push instead of VoIP | Backend MUST send via PushKit topic for incoming wake. |
| 3 | Two `invite`s race (FCM + socket) → stacked Accept/Reject | Already handled by `_incomingCallUiActive` + `_shouldIgnoreInviteBecauseCallSessionBusy()` in `AgoraVoiceIncomingCallHandler`. Do not bypass. |
| 4 | Double `Get.back()` after `endCall` | The `ever(callState)` worker pops on `ended`; **do not** also call `closeCallRouteIfOpen()` after `endCall` / `endCallFromRemote` when controller is non-null. |
| 5 | `call_joined` ignored | Register `AgoraCallJoinedNotificationBridge` per ride, call `markConnectedFromSignal()`. |
| 6 | iOS PushKit revoked over time | Always `reportNewIncomingCall(...)` per VoIP push (incoming or cancellation). |
| 7 | Missing `ride_id` push | Drop on both native (`extractRideId` → `nil`) and Flutter (`_normalizeIncomingRaw` → `null`). |
| 8 | Missing `channel` field on push | Bridge derives `ride_<sanitized rideId>` so client behavior is stable. |
| 9 | RTC token leaks in logs | `AgoraVoiceEngineService` logs only `appId` prefix + channel + uid; never the token. |

---

## 8) QA checklist (run on driver app)

Two real devices in the **same** `ride_<rideId>`:

1. Driver calls rider, rider answers:
   - Driver hears ringback while connecting.
   - Rider hears incoming ringtone.
   - On connect, ring sounds stop on both; duration starts (`MM:SS`).
2. Driver ends connected call:
   - Rider receives `end` and ends once.
3. Rider rejects:
   - Driver gets `remoteRejected` UX.
4. Driver calls rider, rider does not answer:
   - 35s unanswered timeout fires; `onUnansweredTimeout` runs.
5. Backend pushes `call_cancelled` mid-ring:
   - Both clients dismiss incoming UI, no leftover ringtone/timer.
6. Rider answers from locked iPhone (CallKit UI):
   - Accept routes app open and joins channel; no duplicate in-app incoming UI shown.
7. Network drop during active call:
   - Call ends with `disconnected`, no leaks.
8. Cold start tap on incoming notification:
   - Both Android (intent extras → `getInitialMessage()`) and iOS (PushKit pending events) deliver to active ride controller.

---

## 9) VoIP token registration (do not skip)

- Cache: `VoipCallkitBridgeService.instance.voipToken` (also persisted under `StorageKeys.voipToken`).
- Hook: `VoipCallkitBridgeService.instance.setOnVoipTokenChanged(handler)` is called whenever the iOS PushKit token changes; the cached token is replayed once when the host registers later (handles app cold-start before login).
- Contract for the backend register call (driver app endpoint to confirm with backend):

```
PATCH /v1/app/agent/go/voip-token
Body: { "voip_push_token": "<hex>" }
Auth: standard agent access token
```

Confirm path before wiring; ambiguity gate says “ask, don’t guess”.

---

## 10) Files reference (rider repo)

Backend-contract layer:

- `lib/shared/agora_voice/domain/agora_call_invite_event.dart`
- `lib/shared/agora_voice/domain/agora_incoming_call_signal.dart`
- `lib/shared/agora_voice/domain/agora_voice_call_session.dart`
- `lib/shared/agora_voice/domain/agora_voice_call_state.dart`
- `lib/shared/agora_voice/domain/agora_voice_call_end_reason.dart`
- `lib/shared/agora_voice/domain/agora_voice_token_provider.dart`
- `lib/shared/agora_voice/data/ride_call_http_token_provider.dart`

Engine + handlers:

- `lib/shared/agora_voice/service/agora_voice_engine_service.dart`
- `lib/shared/agora_voice/service/agora_voice_incoming_call_handler.dart`
- `lib/shared/agora_voice/service/agora_incoming_call_notification_bridge.dart`
- `lib/shared/agora_voice/service/agora_call_cancel_notification_bridge.dart`
- `lib/shared/agora_voice/service/agora_call_joined_notification_bridge.dart`

Presentation:

- `lib/shared/agora_voice/presentation/agora_voice_call_controller.dart`
- `lib/shared/agora_voice/presentation/agora_voice_call_screen.dart`

Host glue (rewrite per-app, not copy-paste):

- `lib/core/services/voip_callkit_bridge_service.dart`
- `lib/core/services/notification_service.dart` (`_onForegroundMessage`, `_handleForegroundIncomingCall`, `_handleForegroundCallCancelled`, `_handleForegroundCallJoined`, `markSystemIncomingActive`, `clearSystemIncomingActive`, `handleSystemIncomingAccepted`, `handleSystemIncomingCancelled`, `showIncomingCallNotification`, `cancelIncomingCallNotification`)
- `lib/main.dart` (`_firebaseMessagingBackgroundHandler`, `_showAndroidIncomingCallNotification`, `_incomingCallNotificationId`)
- `ios/Runner/AppDelegate.swift` (PushKit + CallKit + method channel)
- `lib/features/<active_ride>/presentation/controllers/<host>_controller.dart` (analog of `driver_accepted_controller.dart`)

---

## 11) Acceptance checklist (driver app handoff is done when)

- [ ] Token endpoint returns valid `app_id / channel / token / uid / expires_at` for an in-progress ride.
- [ ] Outgoing call from driver reaches rider on same `ride_<id>` channel.
- [ ] Incoming call from rider rings on driver across foreground / background / killed states (Android data-only + iOS PushKit).
- [ ] `call_cancelled` reliably dismisses ringing + connected UI on driver.
- [ ] `call_joined` flips driver UI to “Connected” without waiting for `onUserJoined` only.
- [ ] No second Accept/Reject layer on top of an active call (duplicate-invite guard).
- [ ] No double-pop after `endCall` / `endCallFromRemote` (single-pop rule).
- [ ] VoIP token relayed to backend via the registered hook on every token change and on first login.
- [ ] No PII / RTC token in logs.
