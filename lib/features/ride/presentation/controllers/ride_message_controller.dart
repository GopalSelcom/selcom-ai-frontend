import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/entities/ride_chat_message.dart';
import '../../domain/repositories/ride_chat_repository.dart';

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
  String driverSubtitle = '';
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

  StreamSubscription<RideChatMessage>? _chatSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingStatusSub;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    if (rideId.isEmpty) {
      Future.microtask(() {
        AppDialogs.showErrorDialog(
          title: AppStrings.chat.tr,
          message: AppStrings.missingRideInformation.tr,
        );
        Get.back();
      });
      return;
    }
    _bootstrap();
  }

  @override
  void onClose() {
    _chatSub?.cancel();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _trackingStatusSub?.cancel();
    _repository.stopListening();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _parseArgs() {
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    rideId = (args['rideId'] as String?)?.trim() ?? '';

    final name = (args['driverName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      driverName = name;
    }

    final sub = (args['driverSubtitle'] as String?)?.trim();
    if (sub != null && sub.isNotEmpty) {
      driverSubtitle = sub;
    }

    final phone = (args['driverPhone'] as String?)?.trim();
    if (phone != null && phone.isNotEmpty) {
      driverPhone = phone;
    }

    final initialStatus = args['initialStatus'];
    if (initialStatus != null) {
      if (initialStatus is RideStatus) {
        rideStatus.value = initialStatus;
      } else if (initialStatus is String) {
        final normalized = initialStatus.trim().toLowerCase();
        if (normalized == 'accepted') {
          rideStatus.value = RideStatus.driverAssigned;
        } else {
          rideStatus.value = RideStatus.values.firstWhere(
            (e) =>
                e.name.toLowerCase() == normalized ||
                e.name.toLowerCase() == _toCamelCase(normalized).toLowerCase(),
            orElse: () => rideStatus.value,
          );
        }
      }
    }
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
        // Find matching local message (same text, sent within 30 seconds)
        // We use a wider window (30s) to account for potential clock drift or delay.
        final localIndex = messages.indexWhere(
          (m) =>
              m.id.startsWith('local_') &&
              m.text == msg.text &&
              msg.sentAt.difference(m.sentAt).inSeconds.abs() < 30,
        );

        if (localIndex != -1) {
          // Replace the local optimistic bubble with the real server message
          messages[localIndex] = msg;
        } else {
          // Truly new message from other party
          messages.add(msg);
          _scrollToBottom();
        }
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
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint("Error fetching chat history: $e");
    }

    // 3. Connect/Join room
    await _repository.ensureConnected();
    _repository.joinRideRoom(rideId: rideId);

    _rideStatusSub = socket.rideStatusStream.listen((payload) {
      final statusStr = (payload.status ?? '').toString().toLowerCase();
      _updateRideStatusFromStr(statusStr);
    });

    _trackingStatusSub = socket.trackingUpdateStatusStream.listen((payload) {
      if (payload == null) return;
      final statusStr = (payload.status ?? '').toString().toLowerCase();
      _updateRideStatusFromStr(statusStr);
    });

    _scrollToBottom();
  }

  void _updateRideStatusFromStr(String statusStr) {
    if (statusStr.isEmpty) return;
    if (statusStr == 'accepted' || statusStr == 'driver_assigned') {
      rideStatus.value = RideStatus.driverAssigned;
    } else {
      rideStatus.value = RideStatus.values.firstWhere(
        (e) => e.name == _toCamelCase(statusStr),
        orElse: () => rideStatus.value,
      );
    }
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
      AppDialogs.showErrorDialog(
        title: AppStrings.chat.tr,
        message: AppStrings.chatIsOnlyAvailableDuringAnActiveRide.tr,
      );
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
    );

    messages.add(tempMsg);
    messageController.clear();
    _scrollToBottom();

    isSending.value = true;
    try {
      final success = await _repository.sendMessage(rideId: rideId, text: text);
      if (!success) {
        AppDialogs.showErrorDialog(
          title: AppStrings.chat.tr,
          message: AppStrings.failedToSendMessage.tr,
        );
        // Optionally remove the local message on failure
        messages.removeWhere((m) => m.id == localId);
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint("Error sending message: $e");
      AppDialogs.showErrorDialog(
        title: AppStrings.chat.tr,
        message: AppStrings.errorSendingMessage.tr,
      );
      messages.removeWhere((m) => m.id == localId);
    } finally {
      isSending.value = false;
    }
  }

  /// **TODO(static → API):** Wire to `tel:` / in-app call flow when driver phone is available from API.
  Future<void> onTapCallDriver() async {
    final phone = driverPhone.trim();
    if (phone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.call.tr,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }

    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        AppDialogs.showErrorDialog(
          title: AppStrings.call.tr,
          message: AppStrings.unableToOpenPhoneDialer.tr,
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint("Error launching dialer: $e");
      AppDialogs.showErrorDialog(
        title: AppStrings.call.tr,
        message: AppStrings.errorOpeningPhoneDialer.tr,
      );
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
