import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/theme/app_text_styles.dart';

class RideDateFormatter {
  static String formatDate(String apiDate) {
    try {
      final parts = apiDate.split(', ');
      if (parts.length < 2) return apiDate;

      final dateParts = parts[0].split('-');
      if (dateParts.length < 3) return apiDate;

      final year = dateParts[0];
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final time = parts[1].replaceAll(' ', ''); // 08:08PM

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      String daySuffix = 'th';
      if (day >= 11 && day <= 13) {
        daySuffix = 'th';
      } else {
        switch (day % 10) {
          case 1:
            daySuffix = 'st';
            break;
          case 2:
            daySuffix = 'nd';
            break;
          case 3:
            daySuffix = 'rd';
            break;
          default:
            daySuffix = 'th';
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
  final List<RideStopEntity>? stops;

  const RideLocationsTimeline({
    super.key,
    required this.startLocation,
    required this.startAddress,
    required this.endLocation,
    required this.endAddress,
    this.stops,
  });

  @override
  Widget build(BuildContext context) {
    // Filter stops to avoid duplicating final destination
    final filteredStops = (stops ?? []).where((s) {
      final stopAddr = s.address.trim().toLowerCase();
      final endAddr = endAddress.trim().toLowerCase();
      return stopAddr != endAddr;
    }).toList();

    final bool isMulti = filteredStops.isNotEmpty;
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

    return Column(
      children: [
        // Start Location Row
        _buildLocationRow(
          title: startLocation,
          address: startAddress,
          icon: _buildLetterIcon(
            isMulti ? 'A' : 'P',
            color: const Color(0xFF4FA3FF),
          ),
          showBottomLine: true,
        ),

        // Intermediate Stops
        for (int i = 0; i < filteredStops.length; i++)
          _buildLocationRow(
            title: filteredStops[i].address.split(',').first,
            address: filteredStops[i].address,
            icon: _buildLetterIcon(
              letters[i + 1],
              color: const Color(0xFFE11D48),
            ),
            showBottomLine: true,
          ),

        // End Location Row
        _buildLocationRow(
          title: endLocation,
          address: endAddress,
          icon: _buildLetterIcon(
            isMulti ? letters[filteredStops.length + 1] : 'D',
            color: const Color(0xFF34C759), // Green
          ),
          showBottomLine: false,
        ),
      ],
    );
  }

  Widget _buildLetterIcon(String label, {required Color color}) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required String title,
    required String address,
    required Widget icon,
    required bool showBottomLine,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              icon,
              if (showBottomLine)
                Expanded(
                  child: Container(
                    width: 1.w,
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    child: CustomPaint(
                      painter: DashedLinePainter(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showBottomLine ? 16.h : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    address,
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
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.w
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double currentY = 0;

    while (currentY < size.height) {
      canvas.drawLine(
        Offset(0, currentY),
        Offset(0, currentY + dashWidth),
        paint,
      );
      currentY += dashWidth + dashSpace;
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

  const RideRatingStars({super.key, this.rating, this.starSize = 44});

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
