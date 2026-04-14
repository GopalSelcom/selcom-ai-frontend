import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
            title: "Notifications",
            bottomPadding: 20.h,
            child: Padding(
              padding: EdgeInsets.only(top: 12.h, right: 16.w),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    controller.markAllAsRead();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      "Mark all read",
                      style: AppTextStyles.homeCaption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

              return RefreshIndicator(
                onRefresh: controller.getNotifications,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  itemCount: controller.notifications.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return _buildNotificationItem(notification, controller);
                  },
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
              ? Colors.white
              : const Color(0xFFF0F9FF), // Unread bg
          borderRadius: BorderRadius.circular(16.r),
          border: notification.isRead
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                  color: Colors.red,
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
                          notification.message,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: AppColors.shade1,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(notification.timestamp),
                        style: AppTextStyles.homeCaption.copyWith(
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  /// Subtitle
                  Text(
                    notification.title,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.shade2,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  /// ID Tag
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'NO: ${notification.id}',
                      style: AppTextStyles.homeCaption.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.shade1,
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
            color: AppColors.shade2.withOpacity(0.2),
          ),
          SizedBox(height: 16.h),
          Text(
            'No notifications yet',
            style: AppTextStyles.homeSubtitle.copyWith(color: AppColors.shade2),
          ),
          SizedBox(height: 8.h),
          Text(
            'We will notify you when something important happens.',
            style: AppTextStyles.homeCaption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getIconBackgroundColor(int? type) {
    switch (type) {
      case 1:
        return const Color(0xFFE0F2FE);
      case 2:
        return const Color(0xFFFEF3C7);
      case 3:
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getIconColor(int? type) {
    switch (type) {
      case 1:
        return const Color(0xFF0284C7);
      case 2:
        return const Color(0xFFD97706);
      case 3:
        return const Color(0xFF16A34A);
      default:
        return AppColors.shade2;
    }
  }

  IconData _getIcon(int? type) {
    switch (type) {
      case 1:
        return Icons.directions_car_filled_outlined;
      case 2:
        return Icons.local_offer_outlined;
      case 3:
        return Icons.account_balance_wallet_outlined;
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
