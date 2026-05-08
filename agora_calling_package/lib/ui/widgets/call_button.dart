import 'package:flutter/material.dart';

/// Round icon button used by both the incoming and active call screens. Pure
/// presentational — no business logic.
class CallButton extends StatelessWidget {
  const CallButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background = Colors.white24,
    this.iconColor = Colors.white,
    this.size = 64,
  });

  /// "Accept call" preset (green).
  factory CallButton.accept({
    Key? key,
    required VoidCallback onPressed,
    String label = 'Accept',
  }) =>
      CallButton(
        key: key,
        icon: Icons.call,
        label: label,
        onPressed: onPressed,
        background: const Color(0xFF22C55E),
      );

  /// "Reject / hang up" preset (red).
  factory CallButton.hangup({
    Key? key,
    required VoidCallback onPressed,
    String label = 'Hang up',
  }) =>
      CallButton(
        key: key,
        icon: Icons.call_end,
        label: label,
        onPressed: onPressed,
        background: const Color(0xFFEF4444),
      );

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: iconColor, size: size * 0.45),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}
