import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Renders a QR code from [data] using the shared `qr_flutter` package.
class AppQrCode extends StatelessWidget {
  const AppQrCode({
    super.key,
    required this.data,
    this.size,
    this.padding,
  });

  final String data;
  final double? size;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 220.w;
    return Container(
      padding: padding ?? EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(31.r),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: dimension,
        backgroundColor: AppColors.white,
      ),
    );
  }
}
