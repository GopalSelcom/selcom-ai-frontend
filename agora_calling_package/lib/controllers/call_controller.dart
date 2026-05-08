import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';

import '../models/agora_config.dart';
import '../models/call_model.dart';
import '../services/agora_service.dart';
import '../services/call_api_service.dart';
import '../services/notification_service.dart';
import '../ui/screens/active_call_screen.dart';
import '../ui/screens/incoming_call_screen.dart';
import '../utils/audio_helper.dart';
import '../utils/constants.dart';
import '../utils/permissions_helper.dart';

/// Public surface for both apps. Reactive state powers the screens.
///
/// State machine — aligned with `brain/docs/AGORA-FRONTEND-GUIDE.md`
/// ----------------------------------------------------------------
/// Outgoing:
///   idle ─placeCall─> dialing (caller already in channel)
///                    ──onUserJoined OR call_joined push (deduped)──> connected
///                    ──unanswered_timeout──> ended (`unanswered`, /cancel POST)
///                    ──user_hangup──> /cancel POST + ended (`localHangup`)
///                    ──call_cancelled push? N/A — caller doesn't receive this
///
/// Incoming:
///   idle ─incoming_call push─> ringing
///                             ──user_accept──> connecting (POST mint, join)
///                                              ──onUserJoined──> connected
///                             ──user_decline──> ended (`rejectedByLocal`)
///                             ──call_cancelled push──> ended (`remoteCancelled`)
///
/// Connected (either path):
///   connected ──user_hangup──> ended (`localHangup`, leaveChannel only)
///             ──onUserOffline──> ended (`remoteHangup`)
///             ──connection_lost──> ended (`disconnected`)
class CallController extends GetxController {
  CallController({
    required this.config,
    required this.api,
    required this.agora,
    required this.notifications,
  });

  final AgoraCallingConfig config;
  final CallApiService api;
  final AgoraService agora;
  final AgoraCallingNotificationService notifications;

  late final CallAudio _audio = CallAudio(
    ringbackAsset: config.callerRingbackAsset,
    ringtoneAsset: config.incomingRingtoneAsset,
    endToneAsset: config.endTone,
  );

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------
  final Rx<CallState> state = CallState.idle.obs;
  final Rxn<CallModel> currentCall = Rxn<CallModel>();
  final RxBool muted = false.obs;
  final RxBool speakerOn = false.obs;
  final Rxn<CallEndReason> endReason = Rxn<CallEndReason>();
  final RxnString errorMessage = RxnString();
  final RxInt connectedSeconds = 0.obs;

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------
  StreamSubscription<IncomingPushPayload>? _pushSub;
  StreamSubscription<CallEvent?>? _callkitSub;
  Timer? _unansweredTimer;
  Timer? _connectedTimer;
  bool _agoraEventsBound = false;
  bool _connectedSignalled = false; // dedupes call_joined push vs onUserJoined

  /// Currently-joined Agora channel name. Set after a successful join,
  /// cleared on terminate. Used to short-circuit a duplicate `joinChannel`
  /// when two accept events race onto the same call (we'd otherwise hit
  /// `ERR_JOIN_CHANNEL_REJECTED` -17 and tear down the live audio session).
  String? _joinedChannelName;

  /// Caches the in-flight Agora init future so concurrent `_ensureAgoraReady`
  /// callers await the same work. Without this, two parallel `_acceptIncoming`
  /// runs (e.g. CallKit accept + replayed FCM) both pass the
  /// `_agoraEventsBound` check before either flips it true and we end up
  /// with two `RtcEngine` instances racing on the same uid.
  Future<void>? _agoraReadyFuture;

  /// Pending `Get.toNamed` retry — used when accept fires before the host
  /// app's `GetMaterialApp` is mounted (killed-state Accept on Android).
  Timer? _pendingNavTimer;

  /// True from the moment a CallKit Accept is consumed until the resulting
  /// Agora `joinChannel` either succeeds or fails. Used to swallow any
  /// `actionCallEnded` events the plugin may emit during the accept handoff
  /// (some flutter_callkit_incoming versions emit a stale "ended" right after
  /// transitioning the incoming call into "connected"). Without this, an
  /// accept can self-terminate before audio is up — the user sees nothing
  /// happen, while the caller side keeps ringing.
  bool _acceptInProgress = false;

  /// Prevents two overlapping `_acceptIncoming` runs when the user taps
  /// Accept on **both** the native CallKit/CallStyle UI and the in-app
  /// incoming screen at nearly the same time (would mint/join twice and
  /// confuse signaling).
  bool _acceptMutex = false;

  /// Wires push subscription + flutter_callkit_incoming events. Idempotent.
  ///
  /// When the app was killed and woken by a CallKit `Accept`, the native
  /// plugin buffers the event and replays it on the first `onEvent` listener
  /// — so the killed-state Accept reaches `_onCallkitEvent` once we subscribe
  /// here. `_acceptIncoming` reconstructs the call from the event body if the
  /// controller hadn't seen the original `incoming_call` push yet.
  Future<void> bootstrap() async {
    if (kDebugMode) debugPrint('[AGORA_CTRL] bootstrap()');
    _pushSub ??= notifications.pushStream.listen(_onPush);
    _callkitSub ??= FlutterCallkitIncoming.onEvent.listen(_onCallkitEvent);
  }

  @override
  void onClose() {
    _pushSub?.cancel();
    _callkitSub?.cancel();
    _unansweredTimer?.cancel();
    _connectedTimer?.cancel();
    _pendingNavTimer?.cancel();
    _audio.disposeAll();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Outgoing
  // ---------------------------------------------------------------------------

  /// Starts an outgoing call for [rideId]. Caller pre-joins the Agora channel.
  /// The backend pushes `incoming_call` to the peer and `call_joined` back to
  /// us when the peer mints their token.
  Future<void> placeCall({
    required String rideId,
    required String peerDisplayName,
    String? peerAvatarUrl,
  }) async {
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] placeCall rideId=$rideId state=${state.value}');
    }
    if (state.value == CallState.dialing ||
        state.value == CallState.connecting ||
        state.value == CallState.connected) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] placeCall ignored — already in call '
            '(state=${state.value})');
      }
      return;
    }
    final mic = await PermissionsHelper.ensureMicrophone();
    if (mic != PermissionOutcome.granted) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] placeCall mic denied=$mic');
      }
      throw CallPermissionDeniedException(mic);
    }

    _resetTransientState();
    state.value = CallState.dialing;
    errorMessage.value = null;

    try {
      currentCall.value = CallModel.outgoing(
        rideId: rideId,
        peerDisplayName: peerDisplayName,
        peerAvatarUrl: peerAvatarUrl,
      );

      final mint = await api.mintToken(rideId);
      currentCall.value = currentCall.value!.copyWith(
        appId: mint.appId,
        channel: mint.channel.isNotEmpty
            ? mint.channel
            : channelNameForRide(rideId),
        token: mint.token,
        uid: mint.uid,
        tokenExpiresAt: mint.expiresAt,
      );

      await _ensureAgoraReady();
      await _audio.startRingback();
      _startUnansweredTimer();
      _openActiveCallScreen();
      await _joinChannelFor(currentCall.value!);
    } catch (e) {
      _failWith('Could not start the call', e);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Incoming
  // ---------------------------------------------------------------------------

  void _onPush(IncomingPushPayload event) {
    switch (event.type) {
      case PushTypes.incomingCall:
        _handleIncomingPush(event.raw);
        break;
      case PushTypes.callJoined:
        _handleCallJoinedPush(event.raw);
        break;
      case PushTypes.callCancelled:
        _handleRemoteCancelled(event.raw);
        break;
    }
  }

  void _onCallkitEvent(CallEvent? event) {
    if (event == null) return;
    final body = event.body is Map
        ? Map<String, dynamic>.from(event.body as Map)
        : <String, dynamic>{};
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] callkit event=${event.event} body=$body');
    }
    switch (event.event) {
      case Event.actionCallAccept:
        unawaited(_acceptIncoming(body));
        break;
      case Event.actionCallDecline:
        unawaited(_declineIncoming(body));
        break;
      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        if (_acceptInProgress) {
          if (kDebugMode) {
            debugPrint('[AGORA_CTRL] suppressing callkit end during accept');
          }
          break;
        }
        unawaited(_localHangup(fromCallkit: true));
        break;
      case Event.actionCallToggleMute:
        final mutedFromOs = body['isMuted'] as bool?;
        if (mutedFromOs != null) {
          muted.value = mutedFromOs;
          unawaited(agora.setMuted(mutedFromOs));
        }
        break;
      default:
        break;
    }
  }

  Future<void> _handleIncomingPush(Map<String, dynamic> data) async {
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] _handleIncomingPush state=${state.value} '
          'data=$data');
    }
    // Block only when an actual call session is in flight. `error` is a
    // terminal state from a previous attempt — treat it like `ended`/`idle`
    // so a fresh incoming call can take over instead of being silently
    // dropped (which used to manifest as "the second call never rings").
    const inFlight = <CallState>{
      CallState.dialing,
      CallState.ringing,
      CallState.connecting,
      CallState.connected,
    };
    if (inFlight.contains(state.value)) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] ignoring incoming — already in call '
            '(state=${state.value})');
      }
      return;
    }
    final defaultLabel = _peerLabelFor(data);
    final call = CallModel.fromIncomingPush(
      data: data,
      defaultPeerLabel: defaultLabel,
    );
    if (call == null) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] dropped incoming push: missing ride_id');
      }
      return;
    }
    _resetTransientState();
    currentCall.value = call;
    state.value = CallState.ringing;
    // iOS: CallKit (FCM foreground + PushKit) is the only incoming surface —
    // skip the duplicate full-screen Flutter sheet and in-app ringtone
    // (native ring already plays).
    if (!Platform.isIOS) {
      await _audio.startRingtone();
      _openIncomingCallScreen();
    }
  }

  void _handleCallJoinedPush(Map<String, dynamic> data) {
    final pushedRide = (data['ride_id'] ?? data['rideId'])?.toString();
    final cur = currentCall.value;
    if (cur == null) return;
    if (pushedRide != null && pushedRide.isNotEmpty && pushedRide != cur.rideId) {
      return;
    }
    _markConnected();
  }

  void _handleRemoteCancelled(Map<String, dynamic> data) {
    final pushedRide = (data['ride_id'] ?? data['rideId'])?.toString();
    final cur = currentCall.value;
    if (cur == null) return;
    if (pushedRide != null && pushedRide.isNotEmpty && pushedRide != cur.rideId) {
      return;
    }
    if (state.value == CallState.ringing || state.value == CallState.dialing) {
      _terminate(CallEndReason.remoteCancelled);
    }
  }

  /// Callee accepts via the in-app screen OR via CallKit.
  Future<void> answer() async => _acceptIncoming(null);

  /// Callee declines via the in-app screen.
  Future<void> reject() async => _declineIncoming(null);

  /// Reconstructs `currentCall` + flips state to `ringing` when the controller
  /// missed the original `incoming_call` push (e.g. app was killed and woken
  /// straight to CallKit Accept). Idempotent — no-op if a call is already set.
  Future<void> _seedIncomingFromBody(Map<String, dynamic> body) async {
    if (currentCall.value != null && state.value == CallState.ringing) return;
    // CallKit nests the incoming-call data we passed into `extra`; Android
    // sends some fields at the top level. Merge both so we tolerate either.
    final extra = body['extra'];
    final merged = <String, dynamic>{
      ...body,
      if (extra is Map) ...Map<String, dynamic>.from(extra),
    };
    final defaultLabel = _peerLabelFor(merged);
    final reconstructed = CallModel.fromIncomingPush(
      data: merged,
      defaultPeerLabel: defaultLabel,
    );
    if (reconstructed == null) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] _seedIncomingFromBody: no ride_id, skipping');
      }
      return;
    }
    _resetTransientState();
    currentCall.value = reconstructed;
    state.value = CallState.ringing;
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] seeded ringing call '
          'rideId=${reconstructed.rideId} peer=${reconstructed.peerDisplayName}');
    }
  }

  Future<void> _acceptIncoming(Map<String, dynamic>? eventBody) async {
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] _acceptIncoming start state=${state.value} '
          'call=${currentCall.value?.rideId} hasBody=${eventBody != null}');
    }
    // Killed-state path: CallKit dispatched Accept before the controller had
    // a chance to consume the incoming-call push. Reconstruct from event.body.
    if ((currentCall.value == null || state.value != CallState.ringing) &&
        eventBody != null) {
      await _seedIncomingFromBody(eventBody);
    }

    final call = currentCall.value;
    if (call == null || state.value != CallState.ringing) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] _acceptIncoming bail: '
            'call=${call?.rideId} state=${state.value}');
      }
      return;
    }

    if (_acceptMutex) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] _acceptIncoming dedup — already answering');
      }
      return;
    }
    _acceptMutex = true;

    try {
      final mic = await PermissionsHelper.ensureMicrophone();
      if (mic != PermissionOutcome.granted) {
        if (kDebugMode) {
          debugPrint('[AGORA_CTRL] _acceptIncoming mic denied=$mic');
        }
        throw CallPermissionDeniedException(mic);
      }

      // Guard the accept handoff. Any `actionCallEnded` from the plugin between
      // here and successful join (which is normal — the native side transitions
      // the call out of "incoming" state) must NOT terminate the call we just
      // accepted. We do *not* call `endAllCalls()` here for the same reason —
      // see Bug 1 in the troubleshooting README.
      _acceptInProgress = true;
      state.value = CallState.connecting;
      await _audio.stopRingtone();

      // 1) Drop the in-app sheet immediately so we never stack it under the
      //    active call when the user answered from the **notification**.
      _dismissIncomingCallRouteIfOpen();

      // 2) Stop native ringing / clear Android CallStyle incoming notification.
      //    `setCallConnected` alone does not stop sound on Android; the plugin
      //    exposes `hideCallkitIncoming` for that. Do this **before** mint so
      //    the shade doesn't keep vibrating while we wait on the network.
      await _silenceNativeIncomingUi(call.rideId);

      try {
        final mint = await api.mintToken(call.rideId);
        currentCall.value = call.copyWith(
          appId: mint.appId,
          channel: mint.channel.isNotEmpty
              ? mint.channel
              : channelNameForRide(call.rideId),
          token: mint.token,
          uid: mint.uid,
          tokenExpiresAt: mint.expiresAt,
        );
        await _ensureAgoraReady();
        _openActiveCallScreen();
        await _joinChannelFor(currentCall.value!);

        // Second nudge after RTC is up — keeps iOS CallKit history accurate.
        await _silenceNativeIncomingUi(call.rideId);

        if (kDebugMode) {
          debugPrint('[AGORA_CTRL] _acceptIncoming joined channel');
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[AGORA_CTRL] _acceptIncoming join failed: $e\n$st');
        }
        _failWith('Could not join the call', e);
      } finally {
        _acceptInProgress = false;
      }
    } on CallPermissionDeniedException {
      rethrow;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] _acceptIncoming failed before join: $e\n$st');
      }
      rethrow;
    } finally {
      _acceptMutex = false;
    }
  }

  /// Stops the native incoming ring / clears the Android incoming
  /// notification without firing `endAllCalls()` (which would ricochet an
  /// `actionCallEnded` into our listener and kill a fresh accept).
  Future<void> _silenceNativeIncomingUi(String rideId) async {
    if (rideId.isEmpty) return;
    try {
      await FlutterCallkitIncoming.setCallConnected(rideId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] setCallConnected failed (non-fatal): $e');
      }
    }
    if (Platform.isAndroid) {
      try {
        await FlutterCallkitIncoming.hideCallkitIncoming(
          CallKitParams(id: rideId),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AGORA_CTRL] hideCallkitIncoming failed (non-fatal): $e');
        }
      }
    }
  }

  void _dismissIncomingCallRouteIfOpen() {
    if (Get.currentRoute != IncomingCallScreen.routeName) return;
    try {
      Get.back<void>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] dismiss incoming route failed: $e');
      }
    }
  }

  Future<void> _declineIncoming(Map<String, dynamic>? eventBody) async {
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] _declineIncoming start state=${state.value} '
          'call=${currentCall.value?.rideId} hasBody=${eventBody != null}');
    }
    if ((currentCall.value == null || state.value != CallState.ringing) &&
        eventBody != null) {
      // Even when declining we want a populated CallModel so termination logic
      // can dismiss the right CallKit handle and clear notifications.
      await _seedIncomingFromBody(eventBody);
    }
    final call = currentCall.value;
    if (call == null) {
      // Nothing to decline — make sure CallKit is dismissed anyway.
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (_) {}
      return;
    }
    if (state.value != CallState.ringing) {
      // State drifted (e.g. user already in `connecting`/`connected`). Treat
      // as a hangup so we still leave the channel cleanly.
      await _localHangup(fromCallkit: true);
      return;
    }
    await _audio.stopRingtone();
    // No backend "reject" endpoint exists — declining just dismisses CallKit
    // locally (handled by `_terminate(dismissCallkit: true)` below). The
    // caller's unanswered timer will fire if they wait long enough; otherwise
    // they'll explicitly cancel.
    _terminate(CallEndReason.rejectedByLocal);
  }

  // ---------------------------------------------------------------------------
  // Active-call controls
  // ---------------------------------------------------------------------------

  /// Either side ends the call. Before `connected`: hits cancel endpoint.
  /// After: just leaves the channel.
  Future<void> hangUp() async => _localHangup();

  Future<void> _localHangup({bool fromCallkit = false}) async {
    final call = currentCall.value;
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] _localHangup state=${state.value} '
          'call=${call?.rideId} fromCallkit=$fromCallkit');
    }
    if (call == null) {
      // No active call but the user mashed End anyway — make sure CallKit is
      // dismissed so we don't leave a phantom handle on the lock screen.
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (_) {}
      return;
    }
    final wasConnected = state.value == CallState.connected;

    if (!wasConnected && call.role == CallRole.caller) {
      // Cancel before the peer joined.
      try {
        await api.cancelCall(call.rideId);
      } catch (_) {
        // Best-effort — leave channel regardless.
      }
    }
    _terminate(CallEndReason.localHangup, dismissCallkit: !fromCallkit);
  }

  Future<void> toggleMute() async {
    muted.value = !muted.value;
    await agora.setMuted(muted.value);
  }

  Future<void> toggleSpeaker() async {
    speakerOn.value = !speakerOn.value;
    await agora.setSpeakerEnabled(speakerOn.value);
  }

  // ---------------------------------------------------------------------------
  // Agora wiring
  // ---------------------------------------------------------------------------

  Future<void> _ensureAgoraReady() async {
    if (_agoraEventsBound) return;
    // Cache the in-flight init so two parallel callers (e.g. a replayed
    // CallKit Accept that races with the foreground `incoming_call` push)
    // share one `RtcEngine` instead of each spinning up their own — the
    // second engine would then hit `ERR_JOIN_CHANNEL_REJECTED` (-17) on the
    // duplicate uid and tear the live audio down.
    final pending = _agoraReadyFuture ??= _runAgoraInit();
    try {
      await pending;
    } catch (_) {
      _agoraReadyFuture = null;
      rethrow;
    }
  }

  Future<void> _runAgoraInit() async {
    await agora.ensureInitialized(AgoraEvents(
      onJoined: _onLocalJoined,
      onRemoteJoined: _onRemoteJoined,
      onRemoteOffline: _onRemoteOffline,
      onTokenWillExpire: _onTokenWillExpire,
      onConnectionLost: _onConnectionLost,
      onError: _onAgoraError,
    ));
    _agoraEventsBound = true;
  }

  Future<void> _joinChannelFor(CallModel call) async {
    final token = call.token;
    final channel = call.channel;
    if (token == null || token.isEmpty || channel == null || channel.isEmpty) {
      _failWith('Missing call token / channel', StateError('mint incomplete'));
      return;
    }
    // Engine-level idempotency — if we're already joined to the same channel,
    // a second `joinChannel` (e.g. from a duplicate Accept event) is rejected
    // by Agora with `-17 ERR_JOIN_CHANNEL_REJECTED` and the failure path then
    // calls `leaveChannel`, dropping the *live* call. Skip the duplicate.
    if (_joinedChannelName == channel) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] _joinChannelFor skip — already joined '
            'channel=$channel');
      }
      return;
    }
    await agora.joinChannel(
      channelName: channel,
      token: token,
      uid: call.uid ?? 0,
    );
    _joinedChannelName = channel;
  }

  void _onLocalJoined() {
    // No-op — caller already considered "dialing" until the peer signals.
  }

  void _onRemoteJoined(int _) {
    _markConnected();
  }

  /// Single converging point for "connected" — fed by both `call_joined` push
  /// and Agora's `onUserJoined` SDK event. Whichever arrives first wins; the
  /// flag dedupes the second.
  void _markConnected() {
    if (_connectedSignalled) return;
    _connectedSignalled = true;
    if (state.value == CallState.idle || state.value == CallState.ended) {
      return;
    }
    _audio.stopRingback();
    _unansweredTimer?.cancel();
    state.value = CallState.connected;
    _startConnectedTimer();
    // No separate FG service — Agora's RTC SDK keeps its own audio session
    // alive while the channel is joined, and the iOS side relies on
    // UIBackgroundModes audio + voip. The previous flutter_background_service
    // path was redundant and tripped Android 14+/16 FGS notification rules.
  }

  void _onRemoteOffline(int _) {
    if (state.value == CallState.connected) {
      _terminate(CallEndReason.remoteHangup);
    } else if (state.value == CallState.connecting ||
        state.value == CallState.dialing) {
      _terminate(CallEndReason.remoteOffline);
    }
  }

  Future<void> _onTokenWillExpire() async {
    final call = currentCall.value;
    if (call == null) return;
    try {
      final mint = await api.mintToken(call.rideId);
      if (mint.token.isEmpty) return;
      await agora.renewToken(mint.token);
      currentCall.value = call.copyWith(
        token: mint.token,
        tokenExpiresAt: mint.expiresAt,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AGORA_CTRL] token refresh failed: $e');
    }
  }

  void _onConnectionLost() {
    if (state.value == CallState.connected ||
        state.value == CallState.connecting) {
      _terminate(CallEndReason.disconnected);
    }
  }

  void _onAgoraError(String message) {
    if (state.value == CallState.idle || state.value == CallState.ended) {
      return;
    }
    _failWith(message, Exception(message));
  }

  // ---------------------------------------------------------------------------
  // Termination + helpers
  // ---------------------------------------------------------------------------

  void _terminate(
    CallEndReason reason, {
    bool dismissCallkit = true,
  }) {
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] _terminate reason=$reason '
          'state=${state.value} dismissCallkit=$dismissCallkit');
    }
    if (state.value == CallState.ended || state.value == CallState.error) {
      return;
    }
    endReason.value = reason;
    state.value = CallState.ended;
    _unansweredTimer?.cancel();
    _connectedTimer?.cancel();
    _pendingNavTimer?.cancel();
    _acceptInProgress = false;
    _joinedChannelName = null;
    unawaited(_audio.disposeAll());
    unawaited(_audio.playEndTone());
    unawaited(agora.leaveChannel());
    if (dismissCallkit) {
      // Single source of dismissal — used when WE end the call (not when the
      // event comes from CallKit, where the plugin has already torn down its
      // UI and re-firing endAllCalls() would just bounce another spurious
      // `actionCallEnded` back through `_onCallkitEvent`).
      try {
        unawaited(FlutterCallkitIncoming.endAllCalls());
      } catch (_) {}
    }
    _closeOpenCallScreen();
  }

  void _failWith(String message, Object _) {
    errorMessage.value = message;
    endReason.value = CallEndReason.error;
    state.value = CallState.error;
    _unansweredTimer?.cancel();
    _connectedTimer?.cancel();
    _pendingNavTimer?.cancel();
    _joinedChannelName = null;
    unawaited(_audio.disposeAll());
    unawaited(agora.leaveChannel());
    try {
      unawaited(FlutterCallkitIncoming.endAllCalls());
    } catch (_) {}
    _closeOpenCallScreen();
  }

  void _resetTransientState() {
    muted.value = false;
    speakerOn.value = false;
    connectedSeconds.value = 0;
    endReason.value = null;
    errorMessage.value = null;
    _connectedSignalled = false;
  }

  void _startUnansweredTimer() {
    _unansweredTimer?.cancel();
    _unansweredTimer = Timer(config.unansweredTimeout, () {
      if (state.value == CallState.dialing) {
        // Fire-and-forget cancel on the backend (best-effort).
        final call = currentCall.value;
        if (call != null) {
          unawaited(api.cancelCall(call.rideId).catchError((_) {}));
        }
        _terminate(CallEndReason.unanswered);
      }
    });
  }

  void _startConnectedTimer() {
    _connectedTimer?.cancel();
    connectedSeconds.value = 0;
    _connectedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      connectedSeconds.value += 1;
    });
  }

  String _peerLabelFor(Map<String, dynamic> data) {
    final resolver = config.peerNameResolver;
    if (resolver != null) {
      try {
        return resolver(data);
      } catch (_) {}
    }
    final fromPush =
        (data['caller_name'] ?? data['callerName'])?.toString().trim();
    if (fromPush != null && fromPush.isNotEmpty) return fromPush;
    return config.localRole == CallParticipantRole.rider
        ? 'Your Driver'
        : 'Your Rider';
  }

  void _openActiveCallScreen() {
    _navigateWhenReady(ActiveCallScreen.routeName);
  }

  void _openIncomingCallScreen() {
    if (Platform.isIOS) return;
    _navigateWhenReady(IncomingCallScreen.routeName, fullscreenDialog: true);
  }

  /// Opens [routeName] as soon as the host app's `Navigator` is attached.
  ///
  /// Killed-state Accept on Android calls into the controller via the
  /// `flutter_callkit_incoming` event channel **before** `runApp` has finished
  /// building the host's `GetMaterialApp`. At that moment `Get.key.currentState`
  /// is still null and `Get.toNamed` is a silent no-op — the engine joins,
  /// audio comes up, but the user sees no call screen. We retry every 100ms
  /// until the navigator attaches (or 8s elapse, or the call ends), so the UI
  /// reliably appears once Flutter is ready.
  void _navigateWhenReady(String routeName, {bool fullscreenDialog = false}) {
    if (Get.currentRoute == routeName) return;
    if (_tryPushRoute(routeName, fullscreenDialog: fullscreenDialog)) {
      return;
    }
    if (kDebugMode) {
      debugPrint('[AGORA_CTRL] navigator not ready — polling for $routeName');
    }
    _pendingNavTimer?.cancel();
    var ticks = 0;
    _pendingNavTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      ticks++;
      if (ticks > 80) {
        if (kDebugMode) {
          debugPrint('[AGORA_CTRL] navigateWhenReady timeout for $routeName '
              '(navigator never attached)');
        }
        t.cancel();
        return;
      }
      // Bail if the call already ended/errored — don't push a stale screen.
      if (state.value == CallState.idle ||
          state.value == CallState.ended ||
          state.value == CallState.error) {
        t.cancel();
        return;
      }
      if (Get.currentRoute == routeName) {
        t.cancel();
        return;
      }
      if (_tryPushRoute(routeName, fullscreenDialog: fullscreenDialog)) {
        if (kDebugMode) {
          debugPrint('[AGORA_CTRL] navigator attached — pushed $routeName '
              'after ${ticks * 100}ms');
        }
        t.cancel();
      }
    });
  }

  bool _tryPushRoute(String routeName, {required bool fullscreenDialog}) {
    if (Get.key.currentState == null) return false;
    try {
      final pushed = Get.toNamed(routeName);
      if (pushed != null) return true;
      // Named-route lookup failed (host app didn't register it) — fall back
      // to a direct widget push so we still surface a call UI.
      Get.to(
        () => routeName == ActiveCallScreen.routeName
            ? const ActiveCallScreen()
            : const IncomingCallScreen(),
        routeName: routeName,
        fullscreenDialog: fullscreenDialog,
        opaque: true,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_CTRL] _tryPushRoute($routeName) failed: $e');
      }
      return false;
    }
  }

  void _closeOpenCallScreen() {
    // Cancel any still-pending nav retry — the call ended, no point in
    // surfacing a stale call screen if the navigator finally attaches.
    _pendingNavTimer?.cancel();
    final route = Get.currentRoute;
    if (route == ActiveCallScreen.routeName ||
        route == IncomingCallScreen.routeName) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (Get.currentRoute == ActiveCallScreen.routeName ||
            Get.currentRoute == IncomingCallScreen.routeName) {
          Get.back();
        }
      });
    }
  }
}

/// Thrown by the controller when mic permission is missing. UI can catch and
/// route to settings.
class CallPermissionDeniedException implements Exception {
  CallPermissionDeniedException(this.outcome);
  final PermissionOutcome outcome;
  @override
  String toString() => 'CallPermissionDeniedException($outcome)';
}
