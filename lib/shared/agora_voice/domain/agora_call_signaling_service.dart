import 'dart:async';

import 'agora_call_invite_event.dart';

abstract class AgoraCallSignalingService {
  Stream<AgoraCallInviteEvent> get events;

  Future<void> start();

  Future<void> sendEvent(AgoraCallInviteEvent event);

  Future<void> dispose();
}
