# Sounds

Drop the following audio files here before publishing the package:

- `ringback.mp3` — looped tone played to the **caller** while waiting for the
  callee to pick up.
- `ringtone.mp3` — looped tone played to the **callee** while the incoming-call
  screen is shown.
- `call_end.mp3` — short tone played once when a call terminates.

The package references these paths in `AgoraCallingConfig` defaults. Override
those defaults if you'd rather ship custom asset names per app.
