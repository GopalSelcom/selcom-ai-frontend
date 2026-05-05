# Agora Voice (`lib/shared/agora_voice/`)

Portable **audio-only** Agora calling module for Flutter, aligned with the latest Selcom backend contracts.

This file is self-contained so you can hand it to another project without needing:
- `brain/docs/AGORA-ENV-SETUP.md`
- `brain/docs/AGORA-FRONTEND-GUIDE.md`
- `brain/docs/backend-specs/AGORA-CALLING.md`

---

## 1) What This Module Covers

- Backend token mint integration (`app_id`, `channel`, `token`, `uid`, `expires_at`)
- Engine lifecycle (init/join/leave/mute/speaker/renewToken)
- Full-screen incoming/outgoing call UI
- Shared socket-style invite handling (`invite/accept/reject/end`)
- Shared backend push payload parsing for:
  - `type=incoming_call`
  - `ride_id`
  - `caller_role`
  - `channel`

---

## 2) Copy To Another Project

Copy this folder as-is:

- `lib/shared/agora_voice/`

Do **not** copy Selcom bridge files. Build your own lightweight integration file in the target project to wire:
- config/env values
- auth header strategy (`Authorization` vs `access_token`)
- backend token path(s)
- signaling source (socket/FCM/APNs)

---

## 3) Commands To Run In The Other Project

From target project root:

```bash
flutter pub add agora_rtc_engine permission_handler dio get firebase_messaging flutter_callkit_incoming
flutter pub get
flutter analyze lib/shared/agora_voice
```

`firebase_messaging` + `flutter_callkit_incoming` are required for full incoming-call wake/ring flow from backend push.

---

## 4) Platform Requirements

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

Android implementation requirements for incoming calls:
- create notification channel id: `go_incoming_calls`
- set channel importance to `Importance.max`
- show call notification with:
  - `category: AndroidNotificationCategory.call`
  - `fullScreenIntent: true`
  - `priority: Priority.max`
- handle `type=incoming_call` in both:
  - foreground FCM listener
  - background FCM handler (`FirebaseMessaging.onBackgroundMessage`)

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>App needs microphone access for in-app voice calls.</string>
```

For iOS driver locked-screen incoming calls, add PushKit + CallKit capabilities and VoIP token registration in your host app.

---

## 5) Backend Contract (Latest)

### Token endpoints

- Rider app: `POST /v4/go/rides/:rideId/call/token`
- Driver app: `POST /v4/agent/go/rides/:rideId/call/token`

Expected success envelope:

```json
{
  "status_code": 200,
  "message": "Call token issued",
  "data": {
    "app_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "channel": "ride_<rideId>",
    "token": "<rtc_token>",
    "uid": 1234567890,
    "expires_at": "2026-04-29T15:00:00.000Z"
  }
}
```

### Incoming push payload (wake signal only)

```json
{
  "type": "incoming_call",
  "ride_id": "<rideId>",
  "caller_role": "rider",
  "channel": "ride_<rideId>"
}
```

Token is never sent in push payload; receiver mints its own token on answer.

---

## 6) Module Architecture

| Layer | File | Purpose |
|---|---|---|
| Domain | `domain/agora_voice_token_provider.dart` | Contract: fetch credentials by `rideId`. |
| Domain | `domain/agora_rtc_join_credentials.dart` | Parses backend token payload. |
| Domain | `domain/agora_call_invite_event.dart` | Socket/in-app signaling event model. |
| Domain | `domain/agora_incoming_call_signal.dart` | Parses backend `incoming_call` push payload. |
| Data | `data/ride_call_http_token_provider.dart` | Token providers: POST ride mint + optional legacy GET query mode. |
| Data | `data/static_voice_token_provider.dart` | Static fallback for local testing/no backend. |
| Service | `service/agora_voice_engine_service.dart` | Agora engine lifecycle + renew token. |
| Service | `service/agora_voice_incoming_call_handler.dart` | Shared incoming-call flow for signaling events and push payloads. |
| Presentation | `presentation/agora_voice_call_controller.dart` | UI state + permission + call operations. |
| Presentation | `presentation/agora_voice_call_screen.dart` | Full-screen call UI. |
| Presentation | `presentation/agora_voice_call_bottom_sheet.dart` | Optional compact UI. |

---

## 7) Minimal Integration (Host App)

1. Implement token provider:
   - Preferred: `RideCallHttpTokenProvider`
2. Build call controller:
   - `AgoraVoiceCallController(engineService: AgoraVoiceEngineService(...), session: AgoraVoiceCallSession(rideId: ...))`
3. Wire signaling:
   - Socket events -> `AgoraVoiceIncomingCallHandler.handleEvent(...)`
4. Wire push wake signals:
   - FCM/APNs payload -> `AgoraVoiceIncomingCallHandler.handleIncomingCallPush(...)`
5. On answer:
   - `startCall()` (it fetches receiver-side token and joins)
6. Optional behavior knobs (portable defaults):
   - `enableRingbackOnConnectFlow` (default: `true`)
   - `enableIncomingRingtone` (default: `true`)
   - `enableUnansweredTimeout` (default: `true`)
   - `unansweredTimeout` (default: `35s`)
   - `onUnansweredTimeout` (hook for host-app toast/dialog)
   - `onLocalEndRequested` (single place to emit signaling `type=end`)
   - `onCallConnected` (hook for analytics/start marker)
   - `onCallRejected` (hook when remote sends `type=reject`)
   - `onCallMissed` (hook when unanswered timeout fires)
   - `onCallEnded(reason)` (one callback with normalized end reason)
7. Built-in call duration:
   - `connectedDurationSeconds` (`RxInt`)
   - `connectedDurationLabel()` (`MM:SS`)
   - starts on `connected`, stops on any end/disconnect.

---

## 8) Runtime Config Recommendation

- `AGORA_TOKEN_MODE=ride_api`
- `AGORA_TOKEN_ENDPOINT` (optional override template when using `api` mode)
- `AGORA_APP_ID` (public app id, needed for static/legacy mode)

If backend returns `503 FEATURE_DISABLED`, host app should hide/disable call CTA.

### Example: outgoing call with timeout UX + symmetric end signal

```dart
final controller = AgoraVoiceCallController(
  engineService: AgoraVoiceEngineService(tokenProvider: tokenProvider),
  session: AgoraVoiceCallSession(rideId: rideId),
  onLocalEndRequested: () async {
    await signalingService.sendEvent(
      AgoraCallInviteEvent(
        type: AgoraCallInviteEventType.end,
        channelName: 'ride_$rideId',
        rideId: rideId,
        callerName: 'Rider',
        callerId: localClientId,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  },
  onUnansweredTimeout: () async {
    // host app UI feedback (snackbar/dialog/analytics)
  },
);
```

---

## 9) Change Notes (From Latest Backend Docs)

Applied updates in this module:

- Added support for backend incoming push payload shape via:
  - `domain/agora_incoming_call_signal.dart`
  - `AgoraVoiceIncomingCallHandler.handleIncomingCallPush(...)`
- Standardized docs around backend token contract fields:
  - `app_id`, `channel=ride_<rideId>`, `token`, `uid`, `expires_at`
- Kept token refresh flow on `onTokenPrivilegeWillExpire`
- Clarified that channel must be ride-scoped and identical across caller/receiver
- Clarified that driver and rider endpoints are distinct (`/v4/go/...` vs `/v4/agent/go/...`)
- Documented Android native/system-level incoming call requirements:
  - manifest permissions
  - `go_incoming_calls` channel
  - full-screen call notification behavior for foreground/background FCM

Host-app alignment change done in current repo:

- Removed temporary test channel usage; signaling channel now ride-scoped (`ride_<rideId>`) in ride feature.

---

## 10) End Reason Semantics

Controller normalizes how a call ended via:
- `AgoraVoiceCallEndReason.localHangup`
- `AgoraVoiceCallEndReason.remoteEnded`
- `AgoraVoiceCallEndReason.remoteRejected`
- `AgoraVoiceCallEndReason.remoteOffline`
- `AgoraVoiceCallEndReason.unansweredTimeout`
- `AgoraVoiceCallEndReason.disconnected`

UI helper:
- `endReasonLabel()` returns user-friendly text such as:
  - `Call declined`
  - `No answer`
  - `Connection lost`
  - `Call ended by other side`

Loop prevention rule implemented:
- Local hangup emits `type=end` once (through `onLocalEndRequested`).
- Remote `type=end`/`type=reject` ends locally via `endCallFromRemote(...)` without re-emitting.
- Duplicate local end actions are guarded in controller (`_isEnding`).

---

## 11) QA Checklist (Both Apps)

Run these on two real devices/emulators in the same `ride_<rideId>`:

1. A calls B, B answers:
   - A hears ringback while connecting.
   - B hears incoming ringtone.
   - On connect, ring sounds stop on both; duration starts (`MM:SS`).
2. A ends connected call:
   - B receives signaling `type=end`.
   - Both UIs close / move to ended once.
3. B rejects incoming call:
   - A gets remote-rejected path (`remoteRejected`) and correct message.
4. A calls B, B does not answer:
   - timeout fires (default 35s).
   - A triggers `onUnansweredTimeout` + ends with `unansweredTimeout`.
5. Network drop during active call:
   - call ends with `disconnected` and no ringtone/timer leak.

---

## 12) Debug Checklist

If call fails:

- mic permission denied/permanently denied
- backend token response missing `data.app_id` or `data.channel`
- caller/receiver joined different channels
- token expired and renew not triggered
- incoming push payload missing `type=incoming_call` or `ride_id/channel`
- wrong auth header for token endpoint (`Authorization` vs `access_token`)
- backend feature flag disabled (`FEATURE_AGORA_CALLING=false`)

---

## 13) Security Notes

- Never log full RTC token in production.
- Never ship Agora certificate in client builds.

---

## 14) Critical Bug Fixes (Handoff Notes)

### SDK Initialization Race Condition (May 2026)
**Issue**: The call would connect at the SDK level, but the app would never receive events (like `onUserJoined`), leading to a 35-second timeout even if the other person answered.
**Cause**: In `AgoraVoiceEngineService.ensureInitialized`, the `registerEvents` callback was being executed *before* the internal `_engine` reference was saved. Because the reference was null, the event handler registration was skipped.
**Fix**: Reordered the initialization sequence in `AgoraVoiceEngineService.dart` to save the `_engine` reference **before** calling `registerEvents`.
**Verification**: Confirmed that `[AGORA_FLOW] onJoinChannelSuccess` and `[AGORA_FLOW] onUserJoined` logs now trigger correctly.
