# Agora Voice (`lib/shared/agora_voice/`)

Portable **audio-only** Agora calling module for Flutter, ready to reuse in another app.

This module covers:
- token-driven Agora join flow
- outgoing/incoming in-app call screens
- shared incoming call event handling (`invite` / `accept` / `reject` / `end`)
- token refresh on expiry callback

---

## 1) Copy To Another Project

Copy this folder as-is:

- `lib/shared/agora_voice/`

Do **not** copy Selcom-specific bridge files. In your target project, create your own integration file (similar to `lib/core/integration/agora_voice_selcom.dart`) to wire:
- app config
- auth headers
- token endpoint path

---

## 2) Commands To Run In Other Project

Run these in the other project root:

```bash
flutter pub add agora_rtc_engine permission_handler dio get
```

Then refresh packages:

```bash
flutter pub get
```

Optional sanity check:

```bash
flutter analyze lib/shared/agora_voice
```

---

## 3) Platform Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>App needs microphone access for in-app voice calls.</string>
```

---

## 4) Module Architecture

| Layer | File | Purpose |
|---|---|---|
| Domain | `domain/agora_voice_token_provider.dart` | Contract: fetch credentials by `rideId`. |
| Domain | `domain/agora_rtc_join_credentials.dart` | Parsed backend payload (`app_id`, `channel`, `token`, `uid`, `expires_at`). |
| Domain | `domain/agora_call_invite_event.dart` | Shared signaling payload (`invite/accept/reject/end`). |
| Data | `data/ride_call_http_token_provider.dart` | Backend token providers (POST ride mint + legacy GET). |
| Data | `data/static_voice_token_provider.dart` | Static credentials for test/no-backend mode. |
| Service | `service/agora_voice_engine_service.dart` | Engine init/join/leave/mute/speaker/token-renew lifecycle. |
| Service | `service/agora_voice_incoming_call_handler.dart` | Reusable incoming-call orchestrator for signaling events. |
| Presentation | `presentation/agora_voice_call_controller.dart` | Call state + permission + start/end/toggle logic. |
| Presentation | `presentation/agora_voice_call_screen.dart` | Full-screen incoming/outgoing call UI. |
| Presentation | `presentation/agora_voice_call_bottom_sheet.dart` | Optional bottom-sheet style call UI. |

---

## 5) Minimal Integration Steps

1. Implement your signaling adapter using:
   - `AgoraCallSignalingService`
2. Create a token provider:
   - `RideCallHttpTokenProvider` (recommended backend flow), or
   - `StaticVoiceTokenProvider` (testing)
3. Build controller:
   - `AgoraVoiceCallController(engineService: AgoraVoiceEngineService(...), session: AgoraVoiceCallSession(rideId: ...))`
4. Show call screen:
   - `AgoraVoiceCallScreen(...)`
5. Wire incoming signaling events through:
   - `AgoraVoiceIncomingCallHandler.handleEvent(event)`

---

## 6) Backend Token Contract (Recommended)

Expected token payload (`data` object):

```json
{
  "app_id": "your_agora_app_id",
  "channel": "ride_<rideId>",
  "token": "<rtc_token>",
  "uid": 12345,
  "expires_at": "2026-04-29T15:00:00.000Z"
}
```

Important:
- signaling `channelName` should match backend `channel`
- both caller and receiver must join the same channel
- caller and receiver should use different UIDs

---

## 7) Suggested Runtime Config Keys

- `AGORA_TOKEN_MODE=ride_api` (recommended)
- `AGORA_TOKEN_ENDPOINT` (optional; required if using `api` mode templates)
- `AGORA_APP_ID` (used in static/legacy modes)

---

## 8) Common Debug Checklist

If call fails:
- verify mic permission granted
- verify token response contains valid `app_id`, `channel`, `token`, `uid`
- verify both apps use same channel
- verify caller/receiver UIDs are different
- verify signaling event reaches receiver (`invite`)
- verify token not expired

---

## 9) Security Notes

- Never log full RTC token in production.
- Never ship Agora certificate in the client app.
