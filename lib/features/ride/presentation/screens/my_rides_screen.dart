import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';

import '../controllers/my_rides_controller.dart';
import '../widgets/ride_history_card.dart';
import '../widgets/ride_details_bottom_sheet.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject controller using GetIt and Put it into GetX
    final MyRidesController controller = Get.put(sl<MyRidesController>());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppProfileHeader(title: 'My Rides', bottomPadding: 24),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.pastRides.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.fetchPastRides,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400.h,
                      child: Center(
                        child: Text(
                          'No past rides found',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.shade2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchPastRides,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 24.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'Past',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.shade2,
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Map Dynamic Data
                        ...controller.pastRides.map(
                          (ride) => RideHistoryCard(
                            ride: ride,
                            onTap: () {
                              Get.bottomSheet(
                                RideDetailsBottomSheet(ride: ride),
                                isScrollControlled: true,
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
