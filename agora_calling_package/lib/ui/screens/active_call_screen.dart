import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/call_controller.dart';
import '../../models/call_model.dart';
import '../widgets/call_controls.dart';

/// Connected / dialing / connecting surface. Shown immediately after the
/// caller taps "call" or after the callee taps "Accept".
class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  static const String routeName = '/agora_calling/active';

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
            if (call == null ||
                controller.state.value == CallState.idle ||
                controller.state.value == CallState.ended) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => Get.back<void>());
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: 32),
                _StatusLine(controller: controller),
                const SizedBox(height: 24),
                _AvatarLarge(call: call),
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
                _Subtitle(controller: controller),
                const Spacer(),
                const CallControls(),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.controller});
  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.state.value;
      final label = switch (s) {
        CallState.dialing => 'Calling…',
        CallState.connecting => 'Connecting…',
        CallState.connected => 'In call',
        CallState.error =>
          controller.errorMessage.value ?? 'Call error',
        _ => '',
      };
      return Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      );
    });
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.controller});
  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.state.value == CallState.connected) {
        // Must read connectedSeconds inside Obx so GetX rebuilds every tick.
        final secs = controller.connectedSeconds.value;
        final m = (secs ~/ 60).toString().padLeft(2, '0');
        final s = (secs % 60).toString().padLeft(2, '0');
        return Text(
          '$m:$s',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        );
      }
      return const SizedBox.shrink();
    });
  }
}

class _AvatarLarge extends StatelessWidget {
  const _AvatarLarge({required this.call});
  final CallModel call;

  @override
  Widget build(BuildContext context) {
    final url = call.peerAvatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 64,
        backgroundColor: Colors.white12,
        backgroundImage: NetworkImage(url),
      );
    }
    final initials = call.peerDisplayName.trim().isEmpty
        ? '?'
        : call.peerDisplayName.trim().substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 64,
      backgroundColor: Colors.white12,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
