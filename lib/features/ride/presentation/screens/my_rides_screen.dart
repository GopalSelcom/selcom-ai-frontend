import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../controllers/my_rides_controller.dart';
import '../widgets/my_rides_screen_layout.dart';
import '../widgets/my_rides_screen_shimmer.dart';
import '../widgets/ride_history_card.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject controller using GetIt and Put it into GetX
    final MyRidesController controller = Get.put(sl<MyRidesController>());

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppProfileHeader(title: AppStrings.myRides.tr),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MyRidesScreenLayout.listHorizontalPadding,
                      vertical: MyRidesScreenLayout.listVerticalPadding,
                    ),
                    child: MyRidesScreenShimmer.listContent(),
                  ),
                );
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
                          AppStrings.noPastRidesFound.tr,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchPastRides,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 120) {
                      controller.loadMorePastRides();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MyRidesScreenLayout.listHorizontalPadding,
                        vertical: MyRidesScreenLayout.listVerticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MyRidesScreenLayout
                                  .sectionTitleHorizontalInset,
                            ),
                            child: SizedBox(
                              height: MyRidesScreenLayout.sectionTitleHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppStrings.past.tr,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textBody,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15.sp,
                                    height: 20 / 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MyRidesScreenLayout.sectionTitleBottomGap,
                          ),

                          // Map Dynamic Data
                          ...controller.pastRides.map(
                            (ride) => RideHistoryCard(
                              ride: ride,
                              onTap: () => controller.onRideTap(ride),
                            ),
                          ),

                          if (controller.isLoadingMore.value)
                            MyRidesScreenShimmer.loadMoreItems(),

                          SizedBox(height: 40.h),
                        ],
                      ),
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
