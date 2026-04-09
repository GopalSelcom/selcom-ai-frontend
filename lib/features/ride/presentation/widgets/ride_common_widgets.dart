import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_text_styles.dart';

class RideDateFormatter {
  static String formatDate(String apiDate) {
    try {
      // Expected Input: 2026-03-05, 08:08 PM
      final parts = apiDate.split(', ');
      if (parts.length < 2) return apiDate;

      final dateParts = parts[0].split('-');
      if (dateParts.length < 3) return apiDate;

      final year = dateParts[0];
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final time = parts[1].replaceAll(' ', ''); // 08:08PM

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      String daySuffix = 'th';
      if (day >= 11 && day <= 13) {
        daySuffix = 'th';
      } else {
        switch (day % 10) {
          case 1: daySuffix = 'st'; break;
          case 2: daySuffix = 'nd'; break;
          case 3: daySuffix = 'rd'; break;
          default: daySuffix = 'th';
        }
      }

      final dayStr = day.toString().padLeft(2, '0');
      return '$dayStr$daySuffix ${months[month - 1]} $year . $time';
    } catch (e) {
      return apiDate;
    }
  }
}

class RideLocationsTimeline extends StatelessWidget {
  final String startLocation;
  final String startAddress;
  final String endLocation;
  final String endAddress;

  const RideLocationsTimeline({
    super.key,
    required this.startLocation,
    required this.startAddress,
    required this.endLocation,
    required this.endAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Start Location Row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Icon(Icons.location_on, color: const Color(0xFFF3004C), size: 22.w),
                  Expanded(
                    child: Container(
                      width: 1.w,
                      margin: EdgeInsets.symmetric(vertical: 2.h),
                      child: CustomPaint(
                        painter: DashedLinePainter(color: Colors.black.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startLocation,
                        style: TextStyle(
                          fontFamily: AppTextStyles.metropolisFont,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        startAddress,
                        style: TextStyle(
                          fontFamily: AppTextStyles.metropolisFont,
                          color: const Color(0xFF364B63),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // End Location Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.pin_fill, color: const Color(0xFF34C759), size: 22.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endLocation,
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    endAddress,
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      color: const Color(0xFF364B63),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color..strokeWidth = 0.5;
    var max = size.height;
    var dashHeight = 2.0;
    var dashSpace = 2.0;
    double startY = 0.0;
    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FareBreakdownRow extends StatelessWidget {
  final String title;
  final String amount;
  final bool isTotal;

  const FareBreakdownRow({
    super.key,
    required this.title,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.metropolisFont,
              fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
              color: const Color(0xFF364B63),
              fontSize: 14.sp,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontFamily: AppTextStyles.metropolisFont,
            fontWeight: isTotal ? FontWeight.w500 : FontWeight.w500,
            color: const Color(0xFF364B63),
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}

class NeedHelpRow extends StatelessWidget {
  const NeedHelpRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.headphone5, color: const Color(0xFF364B63), size: 24.w),
        SizedBox(width: 8.w),
        Text(
          'Need Help?',
          style: TextStyle(
            fontFamily: AppTextStyles.metropolisFont,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF364B63),
            fontSize: 15.sp,
          ),
        ),
      ],
    );
  }
}

class RideRatingStars extends StatelessWidget {
  final double? rating;
  final double starSize;

  const RideRatingStars({
    super.key,
    this.rating,
    this.starSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final isFilled = rating != null && index < rating!.floor();
        return Icon(
          Icons.star,
          color: isFilled ? const Color(0xFFFFCC00) : const Color(0xFFE6E9EE),
          size: starSize.w,
        );
      }),
    );
  }
}
