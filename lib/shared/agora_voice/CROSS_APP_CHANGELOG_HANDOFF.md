# Agora voice — cross-app handoff (changelog)

Use this when porting the **same behavior** into the **driver / other** app that owns **accept / CallKit / FCM**. It lists what changed in the rider integration so you can mirror contracts and avoid regressions.

**Canonical backend + product rules:** `brain/docs/backend-specs/AGORA-CALLING.md`, `brain/docs/AGORA-FRONTEND-GUIDE.md`.

---

## 1) `call_joined` push → “connected” UI (caller side)

**Why:** Backend notifies the **original caller** when the callee mints a token. The Agora SDK may fire `onUserJoined` slightly later. The guide says: treat **`call_joined` and `onUserJoined` as equivalent “connected” signals**; dedupe; start the duration timer once.

**Module changes (`lib/shared/agora_voice/`):**

| File | Change |
|------|--------|
| `presentation/agora_voice_call_controller.dart` | Added `_markConnectedIfNeeded({required String source})` and public `markConnectedFromSignal()` so FCM can mirror `onUserJoined` without double-starting the timer. `onUserJoined` uses the same helper. |
| `service/agora_call_joined_notification_bridge.dart` | **New.** Routes `type == call_joined` + matching `ride_id` to the active session’s callback (same pattern as cancel + incoming bridges). |

**Host app (example: rider `DriverAccepted` + notifications):**

- Register the bridge for the active ride: on `call_joined`, call `controller.stopIncomingRingtone()` (if any) and `await controller.markConnectedFromSignal()`.
- In `NotificationService`, handle `call_joined` in foreground (and in your navigation/tap path if needed): deliver to the bridge; optionally cancel the `incoming_call` local notification for that `ride_id`.
- Unregister bridge when the ride controller disposes.

**Driver app:** When you are the **callee**, you still answer with `startCall()`. When you are the **caller** after the rider answers, ensure you also handle `call_joined` from FCM the same way so “Calling…” flips to connected without waiting only on `onUserJoined`.

---

## 2) One `Get.back()` to close the call route (no extra pop)

**Why:** `ever(callState)` (or the incoming handler’s worker) already calls `Get.back()` when `callState == ended`. Calling `closeCallRouteIfOpen()` / `_closeInAppCallScreenIfOpen()` **again** after `await endCall()` / `await endCallFromRemote()` popped the call **and then the screen under it** (wrong route, map “loading” flash).

**Module changes:**

| File | Change |
|------|--------|
| `service/agora_voice_incoming_call_handler.dart` | Removed redundant `closeCallRouteIfOpen()` after local `endCall` / `endCall` in `onReject` and `onHangUp`. For remote `reject` / `end`: call `endCallFromRemote` only when controller non-null; call `closeCallRouteIfOpen()` **only** when controller is null. |
| *(host)* `driver_accepted_controller.dart` | Removed second `_closeInAppCallScreenIfOpen()` after `endCallFromRemote` in FCM `call_cancelled` when controller exists. Kept single pop when controller is null. Removed redundant close after outgoing `onReject` following `endCall`. |

**Driver app:** Mirror the rule: **either** reactive close on **`ended`** **or** manual close after **`endCall`, not both.**

---

## 3) Duplicate `invite` — no second Accept/Reject on top of active call

**Why:** Socket (`Stream.listen`) and FCM do **not** serialize async work. Two `invite`s (e.g. FCM + duplicate push, or FCM + parallel socket invite) could run `_showIncomingCallScreen` twice → second `Get.to` stacks a **new** `AgoraVoiceCallScreen` with a **fresh** controller (Accept/Reject visible) **above** an already **connected** call. No Agora “failure” log; it’s a navigation/stack issue.

**Module change (`service/agora_voice_incoming_call_handler.dart`):**

- `_incomingCallUiActive` — set `true` before push, cleared in `finally` after `Get.to` completes.
- `_shouldIgnoreInviteBecauseCallSessionBusy()` — if `getActiveController()?.callState` is `connecting` or `connected`, ignore new `invite`.
- `dispose()` resets `_incomingCallUiActive`.

Debug logs (kDebugMode): `skip duplicate invite (incoming UI already active)`, `skip invite (call already connecting or connected)`.

**Driver app:** Copy this handler logic if you reuse `AgoraVoiceIncomingCallHandler`; or enforce an equivalent single-flight + “busy session” gate before any second fullscreen incoming UI.

---

## 4) Push types to handle (recap)

| `type` | Recipient (typical) | Client action |
|--------|----------------------|----------------|
| `incoming_call` | Callee | Ring / show incoming UI → answer → `startCall()` |
| `call_joined` | Caller | `markConnectedFromSignal()` (dedupe with `onUserJoined`) |
| `call_cancelled` | Other party | Dismiss ring UI; `endCallFromRemote` / leave channel as today |

---

## 5) Files touched in rider repo (reference)

- `lib/shared/agora_voice/presentation/agora_voice_call_controller.dart`
- `lib/shared/agora_voice/service/agora_voice_incoming_call_handler.dart`
- `lib/shared/agora_voice/service/agora_call_joined_notification_bridge.dart` *(new)*
- `lib/core/services/notification_service.dart` *(host)*
- `lib/features/ride/presentation/controllers/driver_accepted_controller.dart` *(host)*

---

## 6) Optional porting checklist (other app)

- [ ] Token path + auth headers for **driver** backend.
- [ ] FCM: `incoming_call`, `call_joined`, `call_cancelled` → same parsing; channel id / full-screen intent unchanged on Android.
- [ ] Register **`AgoraCallJoinedNotificationBridge`** (or equivalent) for active task/ride id.
- [ ] **No double** route close after **`endCall`**.
- [ ] **Dedupe** stacked **`invite`** UI (this handler or equivalent).
- [ ] VoIP + CallKit path: still dismiss on `call_cancelled`; do not double-pop after end.
