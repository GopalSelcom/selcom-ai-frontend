import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/svg_picture_asset.dart';

enum PaymentStatus { pending, success }

class PaymentStatusDialog extends StatelessWidget {
  final PaymentStatus status;
  final int? secondsRemaining;

  const PaymentStatusDialog({
    super.key,
    required this.status,
    this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = status == PaymentStatus.pending;

    final Color bgColor = isPending ? const Color(0xFFE6DCCD) : const Color(0xFFD6EADC);
    final Color circleColor = isPending ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    final String asset = isPending ? AppAssets.icPaymentPending : AppAssets.icPaymentSuccess;
    final String title = isPending
        ? 'Request sent. Payment will be deducted automatically from your wallet to book your ride.'
        : 'Payment received. Your ride is being booked and driver is assigned.';

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 132.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              ),
              child: Center(
                child: Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPictureAsset(
                      asset,
                      width: 44.w,
                      height: 44.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Metropolis',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF132235),
                  height: 1.3,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            if (isPending && secondsRemaining != null)
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Text(
                  'Expire in ${_formatTimer(secondsRemaining!)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Metropolis',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF364B63),
                    height: 1.33,
                  ),
                ),
              )
            else
              SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString();
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
