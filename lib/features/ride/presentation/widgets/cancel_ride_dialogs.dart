import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CancelConfirmationDialog extends StatelessWidget {
  const CancelConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            SizedBox(height: 32.h),
            _ActionButton(
              title: 'YES, CANCEL',
              color: const Color(0xFFFF0050),
              textColor: Colors.white,
              onTap: () => Get.back(result: true),
            ),
            SizedBox(height: 12.h),
            _ActionButton(
              title: 'NO',
              color: const Color(0xFFF1F5F9),
              textColor: const Color(0xFF64748B),
              onTap: () => Get.back(result: false),
            ),
          ],
        ),
      ),
    );
  }
}

class CancelAssignmentWarningDialog extends StatelessWidget {
  const CancelAssignmentWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Your driver is already on the way.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            SizedBox(height: 16.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF475569),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  const TextSpan(text: 'A cancellation fee of '),
                  TextSpan(
                    text: 'TZS 150',
                    style: TextStyle(
                      color: const Color(0xFFFF0050),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: ' will be charged since your driver is on the way.',
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            _ActionButton(
              title: 'Keep Ride',
              color: const Color(0xFFFF0050),
              textColor: Colors.white,
              onTap: () => Get.back(result: false),
            ),
            SizedBox(height: 12.h),
            _ActionButton(
              title: 'Cancel & Pay',
              color: const Color(0xFFF1F5F9),
              textColor: const Color(0xFF64748B),
              onTap: () => Get.back(result: true),
            ),
          ],
        ),
      ),
    );
  }
}

class CancelReasonSelectionDialog extends StatefulWidget {
  const CancelReasonSelectionDialog({super.key});

  @override
  State<CancelReasonSelectionDialog> createState() =>
      _CancelReasonSelectionDialogState();
}

class _CancelReasonSelectionDialogState
    extends State<CancelReasonSelectionDialog> {
  final List<String> _reasons = [
    'Selected Wrong Pickup Location',
    'Selected Wrong Drop Location',
    'Booked By Mistake',
    'Selected Different Service/Vehicle',
    'Driver Asked To Pay Offline',
    'Driver Asked To Cancel',
    'Taking Too Long To Confirm The Ride',
    'Others',
  ];

  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Why do you want to cancel?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 24.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _reasons.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1.h, color: const Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final reason = _reasons[index];
                  final isSelected = _selectedReason == reason;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF0050)
                                    : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                              color: isSelected
                                  ? const Color(0xFFFF0050)
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 14.sp,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 32.h),
            _ActionButton(
              title: 'Continue',
              color: isSelected
                  ? const Color(0xFFFF0050)
                  : const Color(0xFFFF0050).withOpacity(0.5),
              textColor: Colors.white,
              onTap: _selectedReason == null
                  ? null
                  : () => Get.back(result: _selectedReason),
            ),
            SizedBox(height: 12.h),
            _ActionButton(
              title: 'NO',
              color: const Color(0xFFF1F5F9),
              textColor: const Color(0xFF64748B),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  bool get isSelected => _selectedReason != null;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.r),
          ),
          disabledBackgroundColor: color.withOpacity(0.4),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
