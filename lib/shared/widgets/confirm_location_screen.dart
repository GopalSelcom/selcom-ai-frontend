import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Marker;

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_adaptive_bottom_safe_scaffold.dart';
import '../../core/widgets/svg_picture_asset.dart';
import '../../features/home/presentation/controllers/confirm_location_controller.dart';
import 'app_back_button.dart';
import 'app_primary_button.dart';
import 'app_standard_bottom_sheet_bottom_pad.dart';
import 'app_text_field.dart';
import 'map_widgets.dart';

class ConfirmLocationScreen extends GetView<ConfirmLocationController> {
  const ConfirmLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final config = c.uiConfig;
    final canGoBack = Navigator.of(context).canPop();
    final mq = MediaQuery.of(context);
    final bottomSheetMaxHeight =
        mq.size.height - mq.padding.top - mq.padding.bottom - 12;
    final bottomPanelReserve = config.bottomPanelReserve;

    return AppAdaptiveBottomSafeScaffold(
      backgroundColor: AppColors.pageBackground,
      hasBottomWidget: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: _ConfirmLocationMap(
              controller: c,
              config: config,
              bottomPanelReserve: bottomPanelReserve,
            ),
          ),
          Obx(() {
            if (!c.isMapReady.value) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              bottom: bottomPanelReserve.h,
              child: IgnorePointer(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.h,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Positioned(
                        bottom: 4.h,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: Text(
                                config.pinLabel.tr,
                                style: AppTextStyles.homeCaption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 2.w,
                              height: 28.h,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (config.showPreviousPointMarker)
            Obx(() {
              if (!c.hasMovedFromInitial || c.mapController == null) {
                return const SizedBox.shrink();
              }
              final initial = c.initialLatLng;
              final trigger = c.selectedLatLng.value;
              return FutureBuilder<Offset?>(
                future: _projectInitialPointOffset(
                  context: context,
                  mapController: c,
                  initialLatLng: initial,
                  triggerLatLng: trigger,
                ),
                builder: (context, snap) {
                  final offset = snap.data;
                  if (offset == null) return const SizedBox.shrink();
                  return Positioned(
                    left: offset.dx - 24.w,
                    top: offset.dy - 24.h,
                    child: _PreviousPointBlueSymbol(size: 48.w),
                  );
                },
              );
            }),
          if (canGoBack)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10.h,
              left: 16.w,
              child: const AppBackButton(
                color: AppColors.textHeading,
                alignment: Alignment.center,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: bottomSheetMaxHeight),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 48.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: AppColors.skeletonBase,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              SvgPictureAsset(
                                config.headerIconAsset,
                                width: 36.w,
                                height: 36.w,
                                color: config.headerIconColor,
                                placeholderBuilder: (_) => Icon(
                                  Icons.location_on,
                                  color: config.headerIconColor,
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.headerTitle.tr,
                                      style: AppTextStyles.homeTitle.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      config.headerSubtitle.tr,
                                      style: AppTextStyles.homeCaption.copyWith(
                                        color: AppColors.textBody,
                                        fontSize: 15.sp,
                                        height: 20 / 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Obx(() {
                            final fullAddress = c.address.value.trim().isEmpty
                                ? config.addressEmptyFallback.tr
                                : c.address.value.trim();
                            final title = fullAddress.split(',').first.trim();
                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(
                                18.w,
                                14.h,
                                18.w,
                                14.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.borderWalletCard,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty
                                        ? config.addressEmptyFallback.tr
                                        : title,
                                    style: AppTextStyles.homeSubtitle.copyWith(
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15.sp,
                                      height: 20 / 15,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    fullAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.homeCaption.copyWith(
                                      color: AppColors.textBody,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      height: 20 / 12,
                                    ),
                                  ),
                                  if (c.isResolvingAddress.value) ...[
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 12.w,
                                          height: 12.w,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          AppStrings.updatingAddress.tr,
                                          style: AppTextStyles.homeCaption
                                              .copyWith(
                                                color: AppColors.textBody,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                          if (config.showDriverNote) ...[
                            SizedBox(height: 16.h),
                            Obx(() {
                              c.noteChipRevision.value;
                              final expanded = c.isNoteExpanded.value;
                              final noteText = c.noteForDriverController.text
                                  .trim();
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.borderWalletCard,
                                  ),
                                ),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeInOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: c.toggleNoteExpanded,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14.w,
                                              vertical: 12.h,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  AppStrings
                                                      .pickupConfirmationNoteLabel
                                                      .tr,
                                                  style: AppTextStyles
                                                      .homeSubtitle
                                                      .copyWith(
                                                        color: AppColors
                                                            .textHeading,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15.sp,
                                                      ),
                                                ),
                                                SizedBox(width: 10.w),
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      if (noteText.isNotEmpty &&
                                                          !expanded)
                                                        Flexible(
                                                          child: Text(
                                                            noteText,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            textAlign:
                                                                TextAlign.end,
                                                            style: AppTextStyles
                                                                .homeCaption
                                                                .copyWith(
                                                                  color: AppColors
                                                                      .textBody,
                                                                  fontSize:
                                                                      13.sp,
                                                                ),
                                                          ),
                                                        ),
                                                      if (noteText.isNotEmpty &&
                                                          !expanded)
                                                        SizedBox(width: 6.w),
                                                      AnimatedRotation(
                                                        turns: expanded
                                                            ? 0.5
                                                            : 0.0,
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 220,
                                                            ),
                                                        curve: Curves
                                                            .easeInOutCubic,
                                                        child: Icon(
                                                          Icons
                                                              .keyboard_arrow_down,
                                                          color: AppColors
                                                              .textHeading,
                                                          size: 26.sp,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (expanded) ...[
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            12.w,
                                            10.h,
                                            12.w,
                                            12.h,
                                          ),
                                          child: AppTextField(
                                            controller:
                                                c.noteForDriverController,
                                            hintText: AppStrings
                                                .pickupConfirmationNoteHint
                                                .tr,
                                            keyboardType:
                                                TextInputType.multiline,
                                            maxLines: 2,
                                            textInputAction:
                                                TextInputAction.done,
                                            scrollPadding: EdgeInsets.fromLTRB(
                                              20,
                                              mq.padding.top + 56,
                                              20,
                                              mq.viewInsets.bottom + 120,
                                            ),
                                            textFieldBackgroundColor:
                                                AppColors.white,
                                            borderColor:
                                                AppColors.borderWalletCard,
                                            onChanged: (_) {},
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                          SizedBox(height: 20.h),
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 54.h,
                              child: AppPrimaryButton(
                                label: config.confirmButtonLabel.tr,
                                onPressed: c.isSubmitting.value
                                    ? null
                                    : c.onConfirm,
                                isLoading: c.isSubmitting.value,
                                iconAsset: config.confirmButtonIconAsset,
                                iconColor: AppColors.white,
                                height: 54.h,
                              ),
                            ),
                          ),
                          const AppStandardBottomSheetBottomPad(
                            gestureNavOnly: true,
                            hideWhenKeyboardOpen: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Offset?> _projectInitialPointOffset({
    required BuildContext context,
    required ConfirmLocationController mapController,
    required LatLng initialLatLng,
    required LatLng triggerLatLng,
  }) async {
    if (mapController.mapController == null) return null;
    final raw = await AppMapService.screenOffsetFor(
      mapController.mapController!,
      initialLatLng,
    );
    if (raw == null) return null;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final dpr = MediaQuery.of(context).devicePixelRatio;
      return Offset(raw.dx / dpr, raw.dy / dpr);
    }
    return raw;
  }
}

class _ConfirmLocationMap extends StatelessWidget {
  const _ConfirmLocationMap({
    required this.controller,
    required this.config,
    required this.bottomPanelReserve,
  });

  final ConfirmLocationController controller;
  final ConfirmLocationUiConfig config;
  final double bottomPanelReserve;

  @override
  Widget build(BuildContext context) {
    final initial = controller.initialLatLng;
    final initialCamera = CameraPosition(target: initial, zoom: 16);

    return Obx(() {
      controller.routeCircles.value;
      return AppGoogleMap(
        key: ValueKey(
          'confirm_location_map_${initial.latitude}_${initial.longitude}',
        ),
        initialCameraPosition: initialCamera,
        circles: config.showRouteCircles
            ? controller.routeCircles.value
            : const <Circle>{},
        onMapCreated: controller.onMapCreated,
        onCameraMove: controller.onCameraMove,
        onCameraIdle: controller.onCameraIdle,
        padding: EdgeInsets.only(bottom: bottomPanelReserve.h),
      );
    });
  }
}

class _PreviousPointBlueSymbol extends StatelessWidget {
  const _PreviousPointBlueSymbol({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: size * 0.16,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: size * 0.40,
            top: size * 0.22,
            child: Container(
              width: size * 0.46,
              height: size * 0.46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: AppColors.white, width: 1.3),
              ),
            ),
          ),
          Positioned(
            left: size * 0.14,
            top: size * 0.31,
            child: Transform.rotate(
              angle: -0.65,
              child: CustomPaint(
                size: Size(size * 0.18, size * 0.18),
                painter: const _BlueTrianglePainter(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueTrianglePainter extends CustomPainter {
  const _BlueTrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.78, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlueTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
