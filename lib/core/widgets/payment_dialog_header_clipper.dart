import 'package:flutter/material.dart';

/// Curved bottom edge used by [PaymentStatusDialog] and matching confirmation UIs.
class PaymentDialogHeaderClipper extends CustomClipper<Path> {
  PaymentDialogHeaderClipper();

  @override
  Path getClip(Size size) {
    final dipTopY = size.height - 22;
    final dipBottomY = size.height - 6;
    final half = size.width / 2;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, dipTopY)
      ..quadraticBezierTo(size.width * 0.75, dipTopY, half, dipBottomY)
      ..quadraticBezierTo(size.width * 0.25, dipTopY, 0, dipTopY)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
