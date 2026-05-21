import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../domain/entities/ride_chat_message.dart';
import '../controllers/ride_message_controller.dart';

class RideMessageScreen extends GetView<RideMessageController> {
  const RideMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSubtle,
      body: Stack(
        children: [
          // Map Header (Faded static image) - extends to top edge under status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140.h,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                AppAssets.mapBackground,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          // Content Column
          Column(
            children: [
              SizedBox(height: 90.h),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _grabber(),
                      _header(),
                      _safetyBanner(),
                      Expanded(child: _messageList()),
                      _composer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grabber() {
    return Container(
      width: 48.w,
      height: 4.h,
      margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(40.r),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Row(
        children: [
          const AppBackButton(color: AppColors.textHeading),
          Expanded(
            child: Column(
              children: [
                Text(
                  controller.driverName,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 34 / 20,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  controller.driverSubtitle,
                  style: AppTextStyles.homeCaption.copyWith(
                    fontSize: 15.sp,
                    height: 20 / 15,
                    color: AppColors.figmaTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34.w,
            height: 34.w,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: controller.onTapCallDriver,
              icon: SvgPictureAsset(
                AppAssets.icCall,
                width: 14.w,
                height: 14.w,
                color: AppColors.white,
                placeholderBuilder: (_) =>
                    const Icon(Icons.call, color: AppColors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyBanner() {
    return Obx(() {
      return AnimatedCrossFade(
        firstChild: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.safetyBannerBg,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                padding: EdgeInsets.all(6.w),
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
                child: SvgPictureAsset(
                  AppAssets.icInfo,
                  width: 14.w,
                  height: 14.h,
                  color: AppColors.white,
                  placeholderBuilder: (_) => const Icon(
                    Icons.info_outline,
                    color: AppColors.white,
                    size: 14,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  AppStrings
                      .doNotShareYourPersonalDetailsWithRiderBeSafeAndAlwaysCheckYourLuggage
                      .tr,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSafetyNotice,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    height: 20 / 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        secondChild: const SizedBox(width: double.infinity, height: 0),
        crossFadeState: controller.showSafetyBanner.value
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 350),
        firstCurve: Curves.easeInOut,
        secondCurve: Curves.easeInOut,
        sizeCurve: Curves.easeInOut,
      );
    });
  }

  Widget _messageList() {
    return Obx(() {
      return ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.all(16.w),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final m = controller.messages[index];
          return m.isFromRider ? _riderRow(m) : _driverRow(m);
        },
      );
    });
  }

  Widget _driverRow(RideChatMessage m) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.72.sw),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4.r),
                    topRight: Radius.circular(14.r),
                    bottomLeft: Radius.circular(14.r),
                    bottomRight: Radius.circular(14.r),
                  ),
                  border: Border.all(color: AppColors.borderWalletCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.text,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textHeading,
                        height: 20 / 15,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatTime(m.sentAt),
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.textDriverTime,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riderRow(RideChatMessage m) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.72.sw),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14.r),
                    topRight: Radius.circular(4.r),
                    bottomLeft: Radius.circular(14.r),
                    bottomRight: Radius.circular(14.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.text,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15.sp,
                        color: AppColors.white,
                        height: 20 / 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(m.sentAt),
                            style: AppTextStyles.homeCaption.copyWith(
                              color: AppColors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14.sp,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}";
  }

  Widget _composer() {
    return Obx(() {
      final bool allowed = controller.canChat;
      final bool sending = controller.isSending.value;
      return Container(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          border: const Border(
            top: BorderSide(color: AppColors.borderWalletCard),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Opacity(
            opacity: allowed ? 1.0 : 0.5,
            child: AbsorbPointer(
              absorbing: !allowed,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _quickReplyChips(allowed: allowed, sending: sending),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          enabled: allowed,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 1,
                          maxLines: 5,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textHeading,
                          ),
                          decoration: InputDecoration(
                            hintText: allowed
                                ? 'Write a message...'
                                : 'Chat unavailable',
                            hintStyle: AppTextStyles.hint.copyWith(
                              color: AppColors.textMessageHint,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: allowed && !sending
                              ? AppColors.primary
                              : AppColors.skeletonBase,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: sending ? null : controller.sendCurrentMessage,
                          icon: SvgPictureAsset(
                            AppAssets.icSend,
                            width: 18.w,
                            height: 18.w,
                            color: AppColors.white,
                            placeholderBuilder: (_) => const Icon(
                              Icons.send_rounded,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _quickReplyChips({required bool allowed, required bool sending}) {
    return Obx(() {
      if (controller.hideQuickRepliesBecauseTyping.value) {
        return const SizedBox.shrink();
      }
      if (!allowed || controller.quickReplies.isEmpty) {
        return const SizedBox.shrink();
      }
      final labels = controller.quickReplies;

      return Padding(
        padding: EdgeInsets.only(bottom: 5.h),
        child: Opacity(
          opacity: sending ? 0.45 : 1,
          child: IgnorePointer(
            ignoring: sending,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) SizedBox(width: 8.w),
                    Material(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      child: InkWell(
                        onTap: () => controller.sendQuickReply(labels[i]),
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 220.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppColors.borderWalletCard,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.homeCaption.copyWith(
                              color: AppColors.textHeading,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
