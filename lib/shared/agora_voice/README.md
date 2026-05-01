# Agora Voice (`lib/shared/agora_voice/`)

Portable **audio-only** Agora RTC integration aligned with `brain/docs/AGORA-FRONTEND-GUIDE.md`.

## Copy to another app

Copy the whole folder:

- `lib/shared/agora_voice/`

Do **not** copy Selcom wiring — recreate a thin bridge (see `lib/core/integration/agora_voice_selcom.dart` in this repo as a template).

### Dependencies (host `pubspec.yaml`)

- `agora_rtc_engine`
- `permission_handler`
- `dio` (for backend token mint)
- `get` (controller observables; optional — you can re-skin presentation without GetX)

## Architecture

| Layer | Role |
|--------|------|
| `domain/agora_voice_token_provider.dart` | Host implements how tokens are fetched (`rideId` → credentials). |
| `domain/agora_rtc_join_credentials.dart` | Parsed backend payload: `app_id`, `channel`, `token`, `uid`, `expires_at`. |
| `data/static_voice_token_provider.dart` | No-backend / tokenless dev: fixed `channel` + `uid` + optional empty token. |
| `data/ride_call_http_token_provider.dart` | `RideCallHttpTokenProvider` (POST mint) + `ChannelQueryTokenProvider` (legacy GET). |
| `service/agora_voice_engine_service.dart` | Engine lifecycle, join options per guide (`communication` profile, publish mic, auto-subscribe audio), `renewToken` on expiry callback from controller. |
| `presentation/` | GetX UI/controller; swap for your state management if needed. |

## Backend token (recommended)

1. Implement POST `.../rides/:rideId/call/token` on your server (see brain guide).
2. Provide a `RideCallHttpTokenProvider` with:
   - `Dio` using your API `baseUrl`
   - `tokenPathBuilder(rideId)` → path or full URL containing the ride id
   - `headersProvider` → `Authorization` (or your driver header scheme)
3. Build `AgoraVoiceEngineService(tokenProvider: ...)`.
4. Build `AgoraVoiceCallSession(rideId: ...)` — **must** be the same ride the backend mints tokens for.

### Config modes (Selcom reference: `AgoraVoiceSelcom`)

- **`AGORA_TOKEN_MODE=ride_api`** — POST relative path from guide (`/v4/go/rides/...` or `/v4/agent/go/rides/...` depending on rider vs driver factory).
- **`AGORA_TOKEN_MODE=api`** + `AGORA_TOKEN_ENDPOINT` containing `{rideId}` — POST to that template (full URL allowed).
- **`AGORA_TOKEN_MODE=api`** + endpoint **without** `{rideId}` — legacy **GET** token (`ChannelQueryTokenProvider`, channel + uid query).
- **Else** — `StaticVoiceTokenProvider` (needs `AGORA_APP_ID` + local channel/uid).

## Signaling

Invite/accept over socket/FCM stays **outside** this folder — keep `AgoraCallInviteEvent` + your `AgoraCallSignalingService` implementation in the host app. **Signaling `channelName` must match** the backend `channel` field when using minted tokens.

## Security

- Never log full RTC tokens in production.
- Never ship Agora **certificate** in the client (server-only).
