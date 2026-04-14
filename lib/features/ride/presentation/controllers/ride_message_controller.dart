import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../domain/entities/ride_chat_message.dart';
import '../../domain/repositories/ride_chat_repository.dart';
import '../constants/ride_message_static_data.dart';

/// Ride-scoped chat (Figma `207:26441`). Uses [RideChatRepository] → socket `chat:*` when live.
class RideMessageController extends GetxController {
  RideMessageController({required RideChatRepository chatRepository}) : _repository = chatRepository;

  final RideChatRepository _repository;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final messages = <RideChatMessage>[].obs;
  final isSocketConnected = false.obs;
  final isSending = false.obs;

  late final String rideId;
  String driverName = 'John Anthany deo';
  String driverSubtitle = kRideChatStaticDriverPlate;

  /// Shown on outgoing bubbles until profile API provides the rider name.
  // TODO(static → API): Set from authenticated user / ride context.
  String riderBubbleDisplayName = 'Mike Mazowski';

  StreamSubscription<RideChatMessage>? _chatSub;
  StreamSubscription<bool>? _connectionSub;

  /// **TODO(static → API):** Set to `false` when chat history + send are fully driven by API/socket.
  /// While `true`, seeded [staticSeedMessages] are shown and socket send is skipped (UI-only).
  static const bool useStaticChatDataOnly = true;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    if (rideId.isEmpty && !useStaticChatDataOnly) {
      Future.microtask(() {
        Get.snackbar('Chat', 'Missing ride information.');
        Get.back();
      });
      return;
    }
    if (useStaticChatDataOnly) {
      _applyStaticSeed();
      return;
    }
    _bootstrap();
  }

  @override
  void onClose() {
    _chatSub?.cancel();
    _connectionSub?.cancel();
    if (!useStaticChatDataOnly) {
      _repository.stopListening();
    }
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _parseArgs() {
    final raw = Get.arguments;
    final args = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    var id = (args['rideId'] as String?)?.trim() ?? '';
    if (id.isEmpty && useStaticChatDataOnly) {
      id = kRideChatStaticPreviewRideId;
    }
    rideId = id;

    final name = (args['driverName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      driverName = name;
    } else if (useStaticChatDataOnly) {
      driverName = 'John Anthany deo';
    }

    final sub = (args['driverSubtitle'] as String?)?.trim();
    if (sub != null && sub.isNotEmpty) {
      driverSubtitle = sub;
    } else if (useStaticChatDataOnly) {
      driverSubtitle = kRideChatStaticDriverPlate;
    }
  }

  void _applyStaticSeed() {
    // TODO(static → API): Remove — replace with API/socket-driven message list.
    messages.assignAll(staticSeedMessages(rideId));
    isSocketConnected.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _bootstrap() async {
    _repository.startListening();

    _chatSub = _repository.incomingMessages.listen((msg) {
      if (msg.rideId != rideId) return;
      final exists = messages.any((m) => m.id == msg.id);
      if (exists) return;
      messages.add(msg);
      _scrollToBottom();
    });

    final socket = Get.find<AppSocketService>();
    _connectionSub = socket.connectionStream.listen((ok) {
      isSocketConnected.value = ok;
    });
    isSocketConnected.value = socket.isConnected;

    await _repository.ensureConnected();
    _repository.joinRideRoom(rideId: rideId);
    _scrollToBottom();
  }

  void sendCurrentMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty || rideId.isEmpty) return;

    isSending.value = true;
    final now = DateTime.now();
    final localId = 'local_${now.microsecondsSinceEpoch}';
    messages.add(
      RideChatMessage(
        id: localId,
        rideId: rideId,
        text: text,
        isFromRider: true,
        sentAt: now,
        displayName: riderBubbleDisplayName,
      ),
    );
    messageController.clear();
    _scrollToBottom();

    if (!useStaticChatDataOnly) {
      _repository.sendMessage(rideId: rideId, text: text);
    }
    isSending.value = false;
  }

  /// **TODO(static → API):** Wire to `tel:` / in-app call flow when driver phone is available from API.
  void onTapCallDriver() {}

  /// **TODO(static → API):** Emoji picker / sticker sheet when product supports it.
  void onTapComposerEmoji() {}

  /// **TODO(static → API):** Attachments (camera, gallery, files) per backend contract.
  void onTapComposerAttach() {}

  void goBack() => Get.back();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}
