import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/payment_method_controller.dart';
import './payment_method_bottom_sheet.dart';

class PaymentBar extends StatelessWidget {
  final String buttonLabel;
  final VoidCallback onActionButtonPressed;
  final RxBool? isLoading;

  const PaymentBar({
    super.key,
    required this.buttonLabel,
    required this.onActionButtonPressed,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentMethodController>();

    return Obx(() {
      final pay = controller.selectedPayment.value;
      final loading = isLoading?.value ?? false;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(25.w, 18.h, 25.w, 18.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openPaymentSheet(context),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pay Using',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          SvgPictureAsset(
                            AppAssets.icPaymentArrowUp,
                            color: Colors.white,
                            width: 12.w,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        pay?.label ?? 'Select payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pay?.type == 'card')
                        Text(
                          'Card ending in XX1234', // Mock descriptive text from Figma
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(25.r),
                onTap: loading ? null : onActionButtonPressed,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 14.h,
                  ),
                  child: loading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          buttonLabel,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openPaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PaymentMethodBottomSheet(),
    );
  }
}
