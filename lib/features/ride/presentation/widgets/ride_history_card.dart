import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'ride_common_widgets.dart';

class RideHistoryCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onTap;

  const RideHistoryCard({super.key, required this.ride, this.onTap});

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.rideCompleted:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
      case RideStatus.searching:
        return 'Searching';
      case RideStatus.noDriverFound:
        return 'No Driver Found';
      default:
        return 'Completed'; // Default for history usually shows completed/cancelled
    }
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.rideCompleted:
        return const Color(0xFF0EAD36); // Green
      case RideStatus.cancelled:
        return const Color(0xFFE53935); // Red
      case RideStatus.searching:
        return const Color(0xFFF59E0B); // Orange
      case RideStatus.noDriverFound:
        return const Color(0xFF9CA3AF); // Grey
      default:
        return const Color(0xFF0EAD36);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy-MM-dd, hh:mm a',
    ).format(ride.createdAt);
    final vehicleType = ride.vehicleSnapshot?.vehicleType ?? 'Boda';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          border: Border.all(color: const Color(0xFFE6E9EE), width: 0.78),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Vehicle & Date & Status
            Padding(
              padding: EdgeInsets.only(
                left: 15.w,
                right: 15.w,
                top: 16.h,
                bottom: 12.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '$vehicleType $formattedDate',
                      style: TextStyle(
                        fontFamily: AppTextStyles.metropolisFont,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: _getStatusColor(ride.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getStatusText(ride.status),
                        style: TextStyle(
                          fontFamily: AppTextStyles.metropolisFont,
                          color: _getStatusColor(ride.status),
                          fontWeight: FontWeight.w500,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Divider
            Divider(
              color: Colors.black.withOpacity(0.1),
              height: 1,
              thickness: 0.5,
            ),

            // Middle Locations
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: RideLocationsTimeline(
                startLocation: ride.pickup.address.split(',').first,
                startAddress: ride.pickup.address,
                endLocation: ride.destination.address.split(',').first,
                endAddress: ride.destination.address,
              ),
            ),

            // Bottom Divider
            Divider(
              color: Colors.black.withOpacity(0.1),
              height: 1,
              thickness: 0.5,
            ),

            // Bottom Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment method ${ride.paymentMethod == PaymentMethod.selcomPesa ? 'Selcom pesa' : ride.paymentMethod.name}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 15.sp,
                    ),
                  ),
                  Text(
                    'TZS ${ride.finalFare ?? ride.fareEstimate}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0EAD36),
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
