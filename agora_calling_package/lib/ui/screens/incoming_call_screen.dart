import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/call_controller.dart';
import '../../models/call_model.dart';
import '../../utils/permissions_helper.dart';
import '../widgets/call_button.dart';

/// Full-screen incoming call surface. Shown by the controller when an
/// `incoming_call` push arrives in the foreground, OR when the user taps the
/// full-screen-intent ringing notification.
class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  static const String routeName = '/agora_calling/incoming';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: SafeArea(
          child: Obx(() {
            final call = controller.currentCall.value;
            if (call == null) {
              // State changed while route was building.
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => Get.back<void>());
              return const SizedBox.shrink();
            }
            return _IncomingCallBody(
              call: call,
              onAccept: () => _accept(controller, context),
              onReject: () => controller.reject(),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _accept(CallController controller, BuildContext ctx) async {
    try {
      await controller.answer();
    } on CallPermissionDeniedException catch (e) {
      if (!ctx.mounted) return;
      _showPermissionDialog(ctx, e.outcome);
    }
  }

  void _showPermissionDialog(BuildContext ctx, PermissionOutcome outcome) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Microphone permission needed'),
        content: const Text(
          'Allow microphone access in Settings to take voice calls.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          if (outcome == PermissionOutcome.permanentlyDenied)
            TextButton(
              onPressed: () {
                PermissionsHelper.openSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
}

class _IncomingCallBody extends StatelessWidget {
  const _IncomingCallBody({
    required this.call,
    required this.onAccept,
    required this.onReject,
  });

  final CallModel call;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Text(
            'Incoming voice call',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          _Avatar(url: call.peerAvatarUrl, name: call.peerDisplayName),
          const SizedBox(height: 24),
          Text(
            call.peerDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ride • ${call.rideId}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CallButton.hangup(onPressed: onReject, label: 'Decline'),
              CallButton.accept(onPressed: onAccept, label: 'Accept'),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});
  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 56,
        backgroundColor: Colors.white12,
        backgroundImage: NetworkImage(url!),
      );
    }
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 56,
      backgroundColor: Colors.white12,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
