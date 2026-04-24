import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/driver_accepted_controller.dart';
import '../../../../core/localization/app_strings.dart';

class StopEditorScreen extends StatefulWidget {
  const StopEditorScreen({super.key});

  @override
  State<StopEditorScreen> createState() => _StopEditorScreenState();
}

class _StopEditorScreenState extends State<StopEditorScreen> {
  final controller = Get.find<DriverAcceptedController>();
  late List<RideStopEntity> _stops;
  late List<RideStopEntity> _initialStops;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ride = Get.arguments['ride'] as RideEntity?;
    final destAddr = controller.destinationAddress.trim().toLowerCase();

    if (controller.stopUpdateWorkingStops.isNotEmpty) {
      // Use recovered stops if available
      _stops = List.from(controller.stopUpdateWorkingStops);
    } else {
      // Normal initialization from confirmed stops
      _stops = (ride?.stops ?? [])
          .where((s) {
            return s.address.trim().toLowerCase() != destAddr;
          })
          .map(
            (s) => RideStopEntity(
              index: s.index,
              lat: s.lat,
              lng: s.lng,
              address: s.address,
              status: s.status,
            ),
          )
          .toList();
    }
    _initialStops = List.from(_stops);
  }

  bool _hasChanges() {
    if (_stops.length != _initialStops.length) return true;
    for (int i = 0; i < _stops.length; i++) {
      if (_stops[i].address != _initialStops[i].address ||
          _stops[i].lat != _initialStops[i].lat ||
          _stops[i].lng != _initialStops[i].lng) {
        return true;
      }
    }
    return false;
  }

  void _addStop() async {
    // Navigate to location selection and get result
    final result = await Get.toNamed(
      AppRoutes.selectSavedLocation,
      arguments: {
        'isSelectingStop': true,
        'label': AppStrings.editStops.tr, // Or a more specific label
      },
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _stops.add(
          RideStopEntity(
            index: _stops.length,
            lat: (result['lat'] ?? 0.0).toDouble(),
            lng: (result['lng'] ?? 0.0).toDouble(),
            address: result['address'] ?? 'Selected Location',
            status: 'pending',
          ),
        );
        controller.stopUpdatePreview.value = null; // Reset preview on change
      });
    }
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      controller.stopUpdatePreview.value = null; // Reset preview on change
    });
  }

  void _reorderStops(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, item);
      controller.stopUpdatePreview.value = null; // Reset preview on change
    });
  }

  void _onSave() async {
    if (controller.stopUpdatePreview.value == null) {
      setState(() => _isSaving = true);
      await controller.previewStopsUpdate(_stops);
      setState(() => _isSaving = false);
    } else {
      setState(() => _isSaving = true);
      await controller.applyStopsUpdate(_stops);
      setState(() => _isSaving = false);
      if (controller.stopUpdateApplied.value != null) {
        Get.back(); // Return only on success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Stops',
          style: AppTextStyles.homeTitle.copyWith(fontSize: 18.sp),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.shade1,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              children: [
                _buildStaticPoint(
                  'Pickup Point',
                  controller.pickupAddress,
                  AppColors.info,
                  isPickup: true,
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _stops.length,
                  proxyDecorator: (widget, index, animation) {
                    return Material(color: AppColors.transparent, child: widget);
                  },
                  itemBuilder: (context, index) {
                    final stop = _stops[index];
                    return Padding(
                      key: ValueKey('stop_${stop.index}_$index'),
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_indicator,
                                color: AppColors.shade5,
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stop ${index + 1}',
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
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: AppColors.error,
                                size: 24.sp,
                              ),
                              onPressed: () => _removeStop(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onReorder: _reorderStops,
                ),
                _buildAddStopButton(),
                _buildStaticPoint(
                  'Destination',
                  controller.destinationAddress,
                  AppColors.success,
                ),
              ],
            ),
          ),
          _buildPreviewPanel(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Obx(() {
                final showButton =
                    _hasChanges() || controller.stopUpdatePreview.value != null;
                if (!showButton) return const SizedBox.shrink();

                return AppPrimaryButton(
                  label: controller.stopUpdatePreview.value == null
                      ? 'Update Ride'
                      : 'Confirm & Update',
                  onPressed: _isSaving ? null : _onSave,
                  isLoading: _isSaving,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStopButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: _addStop,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Add Stop',
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

  Widget _buildPreviewPanel() {
    return Obx(() {
      final preview = controller.stopUpdatePreview.value;
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
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
                  'New Estimated Fare:',
                  style: AppTextStyles.homeSubtitle.copyWith(fontSize: 14.sp),
                ),
                Text(
                  'TZS ${controller.priceFormatter(preview.newFareEstimate)}',
                  style: AppTextStyles.price.copyWith(fontSize: 18.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare Difference:',
                  style: AppTextStyles.homeCaption.copyWith(fontSize: 13.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '$sign TZS ${controller.priceFormatter(preview.deltaAmount)}',
                    style: AppTextStyles.homeCaption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (preview.deltaAmount > 0) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Fare increase will require a payment authorization.',
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
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.shade5.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              isPickup ? Icons.circle : Icons.location_on,
              color: color,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
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
