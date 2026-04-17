import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import 'ride_common_widgets.dart';

class RideDetailsBottomSheet extends StatelessWidget {
  final RideModel ride;

  const RideDetailsBottomSheet({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy-MM-dd, hh:mm a',
    ).format(ride.createdAt);
    final isCancelled = ride.status.name == 'cancelled';
    final rideCharge = isCancelled
        ? (ride.cancellationFee ?? 0)
        : ride.fareEstimate;
    final totalAmount = isCancelled
        ? (ride.cancellationFee ?? 0)
        : (ride.finalFare ?? ride.fareEstimate);

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(37.r),
          topRight: Radius.circular(37.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          // Drag handle
          Container(
            width: 48.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E9EE),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'Your Rides',
            style: TextStyle(
              fontFamily: AppTextStyles.metropolisFont,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontSize: 20.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vehicle Type and Image Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.vehicleSnapshot?.vehicleType ?? 'Boda',
                            style: TextStyle(
                              fontFamily: AppTextStyles.metropolisFont,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              fontSize: 20.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            RideDateFormatter.formatDate(formattedDate),
                            style: TextStyle(
                              fontFamily: AppTextStyles.metropolisFont,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF364B63),
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/images/img_boda.png',
                        height: 60.h,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.two_wheeler,
                          size: 50.w,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Pick and Drop locations
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
                      border: Border.all(
                        color: const Color(0xFFE6E9EE),
                        width: 0.78,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: RideLocationsTimeline(
                      startLocation: ride.pickup.address.split(',').first,
                      startAddress: ride.pickup.address,
                      endLocation: ride.destination.address.split(',').first,
                      endAddress: ride.destination.address,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Total Fare
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
                      border: Border.all(
                        color: const Color(0xFFE6E9EE),
                        width: 0.78,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Fare',
                          style: TextStyle(
                            fontFamily: AppTextStyles.metropolisFont,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        FareBreakdownRow(
                          title: 'Ride Charge',
                          amount: 'TZS $rideCharge',
                        ),
                        SizedBox(height: 12.h),
                        const FareBreakdownRow(
                          title: 'Booking Fees & Convenience Charges',
                          amount: 'TZS 0.00',
                        ),
                        SizedBox(height: 12.h),
                        FareBreakdownRow(
                          title: 'Total Amount',
                          amount: 'TZS $totalAmount',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Rating
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
                      border: Border.all(
                        color: const Color(0xFFE6E9EE),
                        width: 0.78,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How was your ride?',
                          style: TextStyle(
                            fontFamily: AppTextStyles.metropolisFont,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        RideRatingStars(rating: ride.driverSnapshot?.rating),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Need Help
                  const NeedHelpRow(),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Done Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: AppPrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
