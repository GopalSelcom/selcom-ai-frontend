# Agora Voice Module

Portable in-app voice calling module for Flutter using Agora RTC.

## Folder copy scope

Copy this folder to another app:

- `lib/shared/agora_voice/`

And copy/update only the integration touchpoints:

- App config values (`AGORA_APP_ID`, `AGORA_TOKEN_MODE`, `AGORA_TOKEN_ENDPOINT`)
- One UI trigger (button/tile) that opens `AgoraVoiceCallBottomSheet`
- One UI trigger (button/tile) that opens `AgoraVoiceCallScreen`
- One signaling adapter implementation for your app transport
- Optional mic permission text in platform files

## Dependencies

- `agora_rtc_engine`
- `permission_handler`
- `get` (for controller observables)

## Required config

Provide via `--dart-define`:

- `AGORA_APP_ID`
- `AGORA_TOKEN_MODE=none|api`
- `AGORA_TOKEN_ENDPOINT` (required when mode is `api`)

## Integration steps

1. Build a `AgoraVoiceConfig` using `AgoraVoiceConfig.fromAppConfig()`.
2. Create `AgoraVoiceEngineService` with:
   - `appId: config.appId`
   - `tokenProvider: config.createTokenProvider()`
3. Create `AgoraVoiceCallController` with:
   - `session.channelName` (for example: `ride_<rideId>`)
   - `session.uid` (`0` for auto in test mode)
4. Open `AgoraVoiceCallScreen` for outgoing and incoming call flows.
5. Implement `AgoraCallSignalingService` in your app layer and connect invite events.

## Signaling abstraction

The module includes:

- `AgoraCallSignalingService`
- `AgoraCallInviteEvent`

You must implement signaling in your host app (socket/chat/push/websocket) and map:

- `invite` -> show incoming call screen
- `accept` -> start/join Agora channel
- `reject`/`end` -> leave call and close screen

## Switch from test mode to dynamic token

Current test mode:

- `AGORA_TOKEN_MODE=none`

Switch to backend token:

1. Set `AGORA_TOKEN_MODE=api`
2. Set `AGORA_TOKEN_ENDPOINT=https://<your-backend>/...`

No widget-level changes are required.
