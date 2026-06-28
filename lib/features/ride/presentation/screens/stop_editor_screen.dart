import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_adaptive_bottom_safe_scaffold.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/driver_accepted_controller.dart';
import '../controllers/stop_editor_controller.dart';

/// Presentational shell for add-stops / change-drop flows.
/// Behavior lives in [StopEditorController]; previews read [DriverAcceptedController].
class StopEditorScreen extends GetView<StopEditorController> {
  const StopEditorScreen({super.key});

  DriverAcceptedController get driverController => controller.driverController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.translucent,
      child: Obx(() {
        driverController.stopUpdatePreview.value;
        driverController.destinationUpdatePreview.value;
        controller.selectedDestination.value;
        controller.stops.length;

        final showSave = controller.shouldShowSaveButton;

        return AppAdaptiveBottomSafeScaffold(
          backgroundColor: AppColors.cardBackground,
          hasBottomWidget: showSave,
          body: Column(
            children: [
              AppBar(
                title: Text(controller.appBarTitle),
                leading: const AppBackButton(
                  color: AppColors.textHeading,
                  alignment: Alignment.center,
                ),
              ),
              Expanded(
                child: controller.isDestinationEditor
                    ? ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 20.h,
                        ),
                        children: [
                          _buildStaticPoint(
                            AppStrings.currentDestination.tr,
                            driverController.destinationAddress,
                            AppColors.mapDropMarkerGreen,
                          ),
                          Obx(() {
                            final address =
                                controller.selectedDestination.value?['address']
                                    ?.toString() ??
                                '';
                            if (address.trim().isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _buildStaticPoint(
                              AppStrings.newDestination.tr,
                              address,
                              AppColors.secondary,
                            );
                          }),
                          _buildChangeDropLocationButton(),
                        ],
                      )
                    : Obx(_buildStopsEditorScrollView),
              ),
              controller.isDestinationEditor
                  ? _buildDestinationPreviewPanel()
                  : _buildPreviewPanel(),
            ],
          ),
          footer: showSave
              ? Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: AppPrimaryButton(
                    label: controller.saveButtonLabel,
                    onPressed:
                        controller.isSaving.value ? null : controller.onSave,
                    isLoading: controller.isSaving.value,
                  ),
                )
              : null,
        );
      }),
    );
  }

  Widget _buildStopsEditorScrollView() {
    final stops = controller.stops;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
          sliver: SliverToBoxAdapter(
            child: _buildStaticPoint(
              AppStrings.pickupPoint.tr,
              driverController.pickupAddress,
              AppColors.mapPickupMarkerBlue,
              isPickup: true,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverReorderableList(
            itemCount: stops.length,
            onReorder: controller.reorderStops,
            proxyDecorator: (widget, index, animation) {
              return Material(
                color: AppColors.transparent,
                child: widget,
              );
            },
            itemBuilder: (context, index) {
              final stop = stops[index];
              final canRemoveDraftStop = controller.canRemoveDraftStopAt(index);
              return ReorderableDragStartListener(
                key: ValueKey('stop_${stop.index}_$index'),
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.shade5.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          color: AppColors.shade5,
                          size: 22.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.stopNumber.trParams({
                                  'number': '${index + 1}',
                                }),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                stop.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textBody,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canRemoveDraftStop)
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            onPressed: () => controller.removeStop(index),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverToBoxAdapter(child: Obx(_buildAddStopButton)),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
          sliver: SliverToBoxAdapter(
            child: _buildStaticPoint(
              AppStrings.destination.tr,
              driverController.destinationAddress,
              AppColors.mapDropMarkerGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeDropLocationButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: controller.pickNewDestination,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPictureAsset(
                AppAssets.locationIcAdd,
                width: 18.w,
                height: 18.w,
                color: AppColors.primary,
                placeholderBuilder: (_) => Icon(
                  Icons.add_circle,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.changeDropLocation.tr,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationPreviewPanel() {
    return Obx(() {
      final preview = driverController.destinationUpdatePreview.value;
      if (preview == null) return const SizedBox.shrink();

      final isIncrease = preview.newFareEstimate > preview.oldFareEstimate;
      final isDecrease = preview.newFareEstimate < preview.oldFareEstimate;
      final color = isIncrease
          ? AppColors.error
          : (isDecrease ? AppColors.success : AppColors.textBody);
      final sign = isIncrease ? '+' : (isDecrease ? '-' : '');
      final delta = (preview.newFareEstimate - preview.oldFareEstimate).abs();

      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.newEstimatedFare.tr,
                  style: AppTextStyles.homeSubtitle.copyWith(fontSize: 14.sp),
                ),
                Text(
                  '${CurrencyFormatter.displaySymbol} ${driverController.priceFormatter(preview.newFareEstimate)}',
                  style: AppTextStyles.price.copyWith(fontSize: 16.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.fareDifference.tr,
                  style: AppTextStyles.homeCaption.copyWith(fontSize: 12.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(
                    '$sign ${CurrencyFormatter.displaySymbol} ${driverController.priceFormatter(delta)}',
                    style: AppTextStyles.price.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAddStopButton() {
    final atMaxStops = controller.isAtMaxStops;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Opacity(
        opacity: atMaxStops ? 0.45 : 1.0,
        child: InkWell(
          onTap: atMaxStops ? null : controller.addStop,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPictureAsset(
                  AppAssets.locationIcAdd,
                  width: 18.w,
                  height: 18.w,
                  color: AppColors.primary,
                  placeholderBuilder: (_) => Icon(
                    Icons.add_circle,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  AppStrings.addStop.tr,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Obx(() {
      final preview = driverController.stopUpdatePreview.value;
      if (preview == null) return const SizedBox.shrink();

      final isIncrease = preview.direction == 'up';
      final isDecrease = preview.direction == 'down';
      final color = isIncrease
          ? AppColors.error
          : (isDecrease ? AppColors.success : AppColors.textBody);
      final sign = isIncrease ? '+' : (isDecrease ? '-' : '');

      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.newEstimatedFare.tr,
                  style: AppTextStyles.homeSubtitle.copyWith(fontSize: 14.sp),
                ),
                Text(
                  '${CurrencyFormatter.displaySymbol} ${driverController.priceFormatter(preview.newFareEstimate)}',
                  style: AppTextStyles.price.copyWith(fontSize: 16.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.fareDifference.tr,
                  style: AppTextStyles.homeCaption.copyWith(fontSize: 12.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(
                    '$sign ${CurrencyFormatter.displaySymbol} ${driverController.priceFormatter(preview.deltaAmount)}',
                    style: AppTextStyles.price.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (preview.deltaAmount > 0) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    width: 15.w,
                    height: 15.w,
                    padding: EdgeInsets.all(3.w),
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPictureAsset(
                      AppAssets.icInfo,
                      width: 10.w,
                      height: 10.h,
                      color: AppColors.white,
                      placeholderBuilder: (_) => Icon(
                        Icons.info,
                        color: AppColors.warning,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      AppStrings.fareIncreasePaymentAuthorization.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildStaticPoint(
    String title,
    String address,
    Color color, {
    bool isPickup = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderWalletCard),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: SvgPictureAsset(
                isPickup
                    ? AppAssets.locationIcPickupPin
                    : AppAssets.locationIcDestinationPin,
                color: color,
                placeholderBuilder: (_) => Icon(
                  isPickup ? Icons.location_on : Icons.push_pin,
                  color: color,
                  size: 20.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.shade2,
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
