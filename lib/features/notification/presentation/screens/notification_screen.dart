import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/data/models/notification_model.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../controllers/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(sl<NotificationController>());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          /// Header + Mark All Read
          AppProfileHeader(
            title: AppStrings.notifications.tr,
            bottomPadding: 20.h,
            child: Padding(
              padding: EdgeInsets.only(top: 12.h, right: 16.w),
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(
                  () => GestureDetector(
                    onTap: controller.canMarkAllAsRead
                        ? controller.markAllAsRead
                        : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: controller.isMarkAllLoading.value
                          ? SizedBox(
                              width: 14.w,
                              height: 14.w,
                              child: const CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Mark all read (${controller.unreadCount.value})",
                              style: AppTextStyles.homeCaption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (controller.notifications.isEmpty) {
                return _buildEmptyState();
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 120) {
                    controller.loadMoreNotifications();
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: controller.getNotifications,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    itemCount:
                        controller.notifications.length +
                        (controller.hasMorePages ||
                                controller.isLoadingMore.value
                            ? 1
                            : 0),
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      if (index >= controller.notifications.length) {
                        if (controller.isLoadingMore.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }
                        return SizedBox(height: 8.h);
                      }
                      final notification = controller.notifications[index];
                      return _buildNotificationItem(notification, controller);
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.markAsRead(notification.id),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.white
              : AppColors.bgUnreadNotification,
          borderRadius: BorderRadius.circular(16.r),
          border: notification.isRead
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Red dot for unread
            if (!notification.isRead)
              Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.only(right: 8.w, top: 6.h),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),

            /// Icon
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(notification.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 20.sp,
              ),
            ),

            SizedBox(width: 12.w),

            /// Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title + Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.text,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(notification.createdOn),
                        style: AppTextStyles.homeCaption.copyWith(
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  SizedBox(height: 8.h),

                  if ((notification.orderId ?? '').isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSoftCircle,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Order: ${notification.orderId}',
                        style: AppTextStyles.homeCaption.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                        ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80.sp,
            color: AppColors.textBody.withValues(alpha: 0.2),
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.noNotificationsYet.tr,
            style: AppTextStyles.homeSubtitle.copyWith(color: AppColors.textBody),
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.weWillNotifyYouWhenSomethingImportantHappens.tr,
            style: AppTextStyles.homeCaption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getIconBackgroundColor(int? type) {
    switch (type) {
      case 500:
        return AppColors.bgInfoLight;
      case 501:
        return AppColors.bgPurpleLight;
      case 502:
        return AppColors.bgWarningLight;
      case 503:
        return AppColors.bgGreenLight;
      case 504:
        return AppColors.bgOrangeLight;
      default:
        return AppColors.bgSoftCircle;
    }
  }

  Color _getIconColor(int? type) {
    switch (type) {
      case 500:
        return AppColors.iconInfo;
      case 501:
        return AppColors.iconPurple;
      case 502:
        return AppColors.iconWarning;
      case 503:
        return AppColors.iconSuccess;
      case 504:
        return AppColors.iconOrange;
      default:
        return AppColors.textBody;
    }
  }

  IconData _getIcon(int? type) {
    switch (type) {
      case 500:
        return Icons.directions_car_filled_outlined;
      case 501:
        return Icons.chat_bubble_outline;
      case 502:
        return Icons.local_offer_outlined;
      case 503:
        return Icons.account_balance_wallet_outlined;
      case 504:
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
