import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../domain/entities/ride_chat_message.dart';
import '../../domain/repositories/ride_chat_repository.dart';
import '../constants/ride_message_static_data.dart';

/// Ride-scoped chat (Figma `207:26441`). Uses [RideChatRepository] → socket `chat:*` when live.
class RideMessageController extends GetxController {
  RideMessageController({required RideChatRepository chatRepository})
    : _repository = chatRepository;

  final RideChatRepository _repository;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final messages = <RideChatMessage>[].obs;
  final isSocketConnected = false.obs;
  final isSending = false.obs;

  late final String rideId;
  String driverName = 'John Anthany deo';
  String driverSubtitle = kRideChatStaticDriverPlate;
  String driverPhone = '';

  final rideStatus = RideStatus.searching.obs;
  bool get canChat => [
    RideStatus.driverAssigned,
    RideStatus.driverArriving,
    RideStatus.driverArrived,
    RideStatus.rideStarted,
    RideStatus.rideInProgress,
    RideStatus.nearDestination,
  ].contains(rideStatus.value);

  /// Shown on outgoing bubbles until profile API provides the rider name.
  String riderBubbleDisplayName = 'Mike';

  StreamSubscription<RideChatMessage>? _chatSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<Map<String, dynamic>>? _rideStatusSub;

  /// **TODO(static → API):** Set to `false` when chat history + send are fully driven by API/socket.
  /// While `true`, seeded [staticSeedMessages] are shown and socket send is skipped (UI-only).
  /// **Spec 1.0:** Set to `false` as backend is now ready.
  static const bool useStaticChatDataOnly = false;

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
    _loadRiderProfile();
    _bootstrap();
  }

  Future<void> _loadRiderProfile() async {
    try {
      final storage = StorageService();
      final data = await storage.read(StorageKeys.user);
      if (data != null) {
        final json = jsonDecode(data);
        final name = (json['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          riderBubbleDisplayName = name;
        }
      }
    } catch (e) {
      debugPrint("Error loading rider profile: $e");
    }
  }

  @override
  void onClose() {
    _chatSub?.cancel();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    if (!useStaticChatDataOnly) {
      _repository.stopListening();
    }
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _parseArgs() {
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
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

    final phone = (args['driverPhone'] as String?)?.trim();
    if (phone != null && phone.isNotEmpty) {
      driverPhone = phone;
    }
  }

  void _applyStaticSeed() {
    messages.assignAll(staticSeedMessages(rideId));
    isSocketConnected.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _bootstrap() async {
    // 1. Start socket listening
    _repository.startListening();

    _chatSub = _repository.incomingMessages.listen((msg) {
      if (msg.rideId != rideId) return;
      // Socket echo or real-time message
      final existingIndex = messages.indexWhere((m) => m.id == msg.id);
      if (existingIndex != -1) {
        // Update existing (e.g. from local temp ID to real ID)
        messages[existingIndex] = msg;
      } else {
        // New message
        messages.add(msg);
        _scrollToBottom();
      }
    });

    final socket = Get.find<AppSocketService>();
    _connectionSub = socket.connectionStream.listen((ok) {
      isSocketConnected.value = ok;
    });
    isSocketConnected.value = socket.isConnected;

    // 2. Fetch history
    try {
      final history = await _repository.getHistory(rideId: rideId);
      if (history.isNotEmpty) {
        messages.assignAll(history);
      }
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
    }

    // 3. Connect/Join room
    await _repository.ensureConnected();
    _repository.joinRideRoom(rideId: rideId);

    // 4. Listen for status updates to enable/disable chat
    _rideStatusSub = socket.rideStatusStream.listen((payload) {
      final statusStr = (payload['status'] ?? '').toString().toLowerCase();
      if (statusStr.isNotEmpty) {
        rideStatus.value = RideStatus.values.firstWhere(
          (e) => e.name == _toCamelCase(statusStr),
          orElse: () => rideStatus.value,
        );
      }
    });

    _scrollToBottom();
  }

  String _toCamelCase(String snakeCase) {
    List<String> words = snakeCase.split('_');
    if (words.length == 1) return words[0];
    return words[0] +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join('');
  }

  void sendCurrentMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || rideId.isEmpty) return;

    if (!canChat) {
      Get.snackbar('Chat', 'Chat is only available during an active ride');
      return;
    }

    final now = DateTime.now();
    final localId = 'local_${now.microsecondsSinceEpoch}';
    final tempMsg = RideChatMessage(
      id: localId,
      rideId: rideId,
      text: text,
      isFromRider: true,
      sentAt: now,
      displayName: riderBubbleDisplayName,
    );

    messages.add(tempMsg);
    messageController.clear();
    _scrollToBottom();

    if (!useStaticChatDataOnly) {
      isSending.value = true;
      try {
        final success = await _repository.sendMessage(
          rideId: rideId,
          text: text,
        );
        if (!success) {
          Get.snackbar('Chat', 'Failed to send message');
          // Optionally remove the local message on failure
          messages.removeWhere((m) => m.id == localId);
        }
      } catch (e) {
        debugPrint("Error sending message: $e");
        Get.snackbar('Chat', 'Error sending message');
        messages.removeWhere((m) => m.id == localId);
      } finally {
        isSending.value = false;
      }
    }
  }

  /// **TODO(static → API):** Wire to `tel:` / in-app call flow when driver phone is available from API.
  void onTapCallDriver() {
    if (driverPhone.isNotEmpty) {
      Get.snackbar(
        'Calling Driver',
        'Initiating call to $driverPhone...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white.withOpacity(0.9),
      );
    } else {
      Get.snackbar('Error', 'Driver phone number not available');
    }
  }

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
