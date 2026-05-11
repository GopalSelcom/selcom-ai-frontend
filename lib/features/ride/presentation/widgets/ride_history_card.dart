import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/ride_active_navigation.dart';
import 'ride_common_widgets.dart';

class RideHistoryCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onTap;

  const RideHistoryCard({super.key, required this.ride, this.onTap});

  String _getStatusText(RideStatus status) {
    if (rideStatusIsOngoingActive(status)) {
      return AppStrings.ongoing.tr;
    }
    switch (status) {
      case RideStatus.rideCompleted:
        return AppStrings.completed.tr;
      case RideStatus.cancelled:
        return AppStrings.cancelled.tr;
      case RideStatus.noDriverFound:
        return AppStrings.noDriverFound.tr;
      default:
        return AppStrings.completed.tr;
    }
  }

  Color _getStatusColor(RideStatus status) {
    if (rideStatusIsOngoingActive(status)) {
      return AppColors.info;
    }
    switch (status) {
      case RideStatus.rideCompleted:
        return AppColors.iconSuccess;
      case RideStatus.cancelled:
        return AppColors.error;
      case RideStatus.noDriverFound:
        return AppColors.borderInputMuted;
      default:
        return AppColors.iconSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy-MM-dd, hh:mm a',
    ).format(ride.createdAt);
    final resolvedVehicleType = (ride.vehicleDisplayName ?? '').trim();
    final vehicleType = resolvedVehicleType.isNotEmpty
        ? resolvedVehicleType
        : AppStrings.fallbackRideName.tr;
    final effectiveFare = ride.status == RideStatus.cancelled
        ? (ride.cancellationFee ?? 0)
        : (ride.fareBreakdown?.totalAmount ??
              ride.finalFare ??
              ride.fareEstimate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          border: Border.all(color: AppColors.borderWalletCard, width: 0.79),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Vehicle & Date & Status
            Padding(
              padding: EdgeInsets.fromLTRB(15.w, 17.h, 12.w, 13.h),
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
                        color: AppColors.black,
                        fontSize: 15.sp,
                        height: 20 / 15,
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
                      SizedBox(width: 3.w),
                      Text(
                        _getStatusText(ride.status),
                        style: TextStyle(
                          fontFamily: AppTextStyles.metropolisFont,
                          color: _getStatusColor(ride.status),
                          fontWeight: FontWeight.w500,
                          fontSize: 15.sp,
                          height: 20 / 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Divider
            Divider(
              color: AppColors.black.withValues(alpha: 0.1),
              height: 1,
              thickness: 0.5,
            ),

            // Middle Locations
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              child: RideLocationsTimeline(
                startLocation: ride.pickup.address.split(',').first,
                startAddress: ride.pickup.address,
                endLocation: ride.destination.address.split(',').first,
                endAddress: ride.destination.address,
                stops: ride.stops,
                showStopsAsSummary: true,
              ),
            ),

            // Bottom Divider
            Divider(
              color: AppColors.black.withValues(alpha: 0.1),
              height: 1,
              thickness: 0.5,
            ),

            // Bottom Row
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 13.h, 12.w, 17.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.paymentMethodWithName.trParams({
                      'name': ride.paymentMethod == PaymentMethod.selcomPesa
                          ? AppStrings.selcomPesa.tr
                          : ride.paymentMethod.name,
                    }),
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      fontSize: 15.sp,
                      height: 20 / 15,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(effectiveFare),
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w500,
                      color: AppColors.iconSuccess,
                      fontSize: 15.sp,
                      height: 20 / 15,
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
