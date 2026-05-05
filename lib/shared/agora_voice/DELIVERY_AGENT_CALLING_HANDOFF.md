# DeliveryAgent App Handoff — Agora Calling Integration

This document is for the **DeliveryAgent (driver) app** team to implement the same call behavior we now have in rider app:
- incoming call screen visibility
- ringtone/full-screen incoming alert
- `call_cancelled` dismiss flow
- resilient token mint flow

---

## Scope

Implement in-app voice calling for driver app with:
- Bidirectional call support (driver can call rider, rider can call driver)
- Incoming push handling for `incoming_call` and `call_cancelled`
- Pre-answer cancel via backend cancel endpoint
- Rate-limit aware token mint retries

---

## Backend Contract (Driver App)

Use these endpoints from DeliveryAgent app:

- Mint token: `POST /v1/app/agent/go/rides/:id/call/token`
- Cancel pending outbound call: `POST /v1/app/agent/go/rides/call/cancel`

Headers:
- Driver app uses `access_token` auth header (as per backend contract)

Push payloads to handle:

### Incoming call
```json
{
  "type": "incoming_call",
  "ride_id": "<rideId>",
  "caller_role": "rider",
  "channel": "ride_<rideId>"
}
```

### Cancel pending call
```json
{
  "type": "call_cancelled",
  "ride_id": "<rideId>",
  "cancelled_by": "rider"
}
```

---

## Required Behavior

### 1) Incoming call push (`type=incoming_call`)
- Show incoming full-screen call UI (or full-screen notification fallback).
- Use a **stable notification id per ride**, for example: `incoming_call_<rideId>.hashCode`.
- On accept:
  - Fetch token using driver token endpoint
  - Join Agora channel

### 2) Cancel push (`type=call_cancelled`)
- Immediately dismiss incoming call UI for that `ride_id`
- Cancel matching incoming notification using same stable notification id
- If local call already joined due to race, leave channel safely

### 3) Outgoing call cancel before answer
- If driver taps cancel **before connected**:
  - hit `POST /v1/app/agent/go/rides/call/cancel`
  - then close local call UI / stop ringtone
- If already connected:
  - perform normal end/hangup flow (no pending-cancel endpoint)

### 4) Token mint rate limiting
- Handle `429 CALL_RATE_LIMIT_EXCEEDED`
- Retry token fetch with short backoff (respect `Retry-After` if present)
- Show user message: "Please wait before calling again"

---

## Android Requirements

### Manifest permissions
- `RECORD_AUDIO`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_PHONE_CALL`
- `USE_FULL_SCREEN_INTENT`

### Main activity
For lock-screen visibility:
- `android:showWhenLocked="true"`
- `android:turnScreenOn="true"`

### Notification channel
Create channel id: `go_incoming_calls`
- importance: max
- sound: enabled
- vibration: enabled
- call category
- full-screen intent

Recommended notification options:
- `category: call`
- `fullScreenIntent: true`
- `audioAttributesUsage: notificationRingtone`
- `visibility: public`
- `ongoing: true`
- `timeoutAfter: 30000`

---

## iOS Requirements

For reliable locked-screen ringing on driver app:
- PushKit + CallKit integration
- VoIP token registration to backend after login
- Handle both `incoming_call` and `call_cancelled` in PushKit callback
- On `call_cancelled`, dismiss CallKit UI and do not join Agora

Also ensure:
- `NSMicrophoneUsageDescription` in `Info.plist`

---

## Suggested Shared Components (Driver App)

Create/align equivalent modules:

- Token provider/service
  - `fetchCredentials(rideId)`
  - retry/backoff on `429`
- Incoming call bridge
  - route push payload to active ride controller by ride id
- Cancel bridge
  - route `call_cancelled` payload to active controller by ride id
- Call controller
  - `startCall`, `endCall`, `endCallFromRemote`
  - `startIncomingRingtone`, `stopIncomingRingtone`
  - token renew on `onTokenPrivilegeWillExpire`

---

## Error Mapping

Map backend responses to UX:

- `409 CALL_NOT_ALLOWED_FOR_STATUS` → disable/hide call action for current ride state
- `429 CALL_RATE_LIMIT_EXCEEDED` → show retry-later message
- `503 FEATURE_DISABLED` → hide call feature entirely
- `500 CALL_TOKEN_MINT_FAILED` → show temporary failure and allow retry

---

## QA Checklist (Driver App)

- Incoming call rings and full-screen UI appears when app is:
  - foreground
  - background
  - locked screen
- `call_cancelled` dismisses ringing UI in all app states
- Cancel before answer hits cancel endpoint and dismisses receiver UI
- Connected call supports mute/speaker/end
- Token renew works during long call
- Call closes on terminal ride status (`ride_completed`, `cancelled`, `no_driver_found`)
- No PII in logs/push payloads (no phone numbers, no token logging)

---

## Notes for Team

- Token is never sent in push payload. Receiver must mint own token on answer.
- Channel naming must stay exactly `ride_<rideId>` across rider and driver apps.
- Keep call behavior ride-scoped; do not allow calls outside active ride statuses.
