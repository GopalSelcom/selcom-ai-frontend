import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/call_controller.dart';
import '../../models/call_model.dart';
import 'call_button.dart';

/// Bottom row controls during an active call: mute / speaker / cancel-or-end.
///
/// Per brain doc § 8: button label flips between "Cancel" (before
/// `onUserJoined` fires) and "End Call" (after). Both call `controller.hangUp`
/// — the controller decides whether to hit `/cancel` or just `leaveChannel`.
class CallControls extends StatelessWidget {
  const CallControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Obx(() => _toggleButton(
                icon: controller.muted.value ? Icons.mic_off : Icons.mic,
                label: controller.muted.value ? 'Unmute' : 'Mute',
                active: controller.muted.value,
                onPressed: controller.toggleMute,
              )),
          Obx(() => CallButton.hangup(
                onPressed: controller.hangUp,
                label: controller.state.value == CallState.connected
                    ? 'End'
                    : 'Cancel',
              )),
          Obx(() => _toggleButton(
                icon: controller.speakerOn.value
                    ? Icons.volume_up
                    : Icons.hearing,
                label: controller.speakerOn.value ? 'Speaker' : 'Earpiece',
                active: controller.speakerOn.value,
                onPressed: controller.toggleSpeaker,
              )),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return CallButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
      background: active ? Colors.white : Colors.white24,
      iconColor: active ? Colors.black : Colors.white,
      size: 56,
    );
  }
}
