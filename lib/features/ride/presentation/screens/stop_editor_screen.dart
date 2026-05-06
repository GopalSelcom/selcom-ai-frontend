import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_back_button.dart';
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
  static const int _maxDropStops = 3;
  late List<RideStopEntity> _stops;
  late List<String> _stopLocalKeys;
  late List<RideStopEntity> _initialStops;
  int _newStopCounter = 0;
  // Reuse this screen for two modes:
  // - false: mid-ride stops editor
  // - true : change drop location editor
  bool _isDestinationEditor = false;
  Map<String, dynamic>? _selectedDestination;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Do not carry stale preview panel from previous editor session.
    controller.stopUpdatePreview.value = null;
    controller.destinationUpdatePreview.value = null;

    final args = Get.arguments is Map<String, dynamic>
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    _isDestinationEditor = args['editorMode'] == 'destination';
    final ride = args['ride'] as RideEntity?;
    final destAddr = controller.destinationAddress.trim().toLowerCase();
    final confirmedStops = (ride?.stops ?? [])
        .where((s) => s.address.trim().toLowerCase() != destAddr)
        .toList();

    if (controller.stopUpdateWorkingStops.isNotEmpty) {
      // Use recovered stops if available
      _stops = List.from(controller.stopUpdateWorkingStops);
      // Frontend-only draft tracking:
      // items beyond confirmed baseline are treated as newly added stops.
      final baselineCount = confirmedStops.length;
      _stopLocalKeys = List.generate(_stops.length, (i) {
        if (i >= baselineCount) return 'new_${_newStopCounter++}';
        return 'confirmed_$i';
      });
    } else {
      // Normal initialization from confirmed stops
      _stops = confirmedStops
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
      _stopLocalKeys = List.generate(_stops.length, (i) => 'confirmed_$i');
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
    if (_stops.length >= _maxDropStops) {
      Get.snackbar(
        AppStrings.error.tr,
        'You can add up to $_maxDropStops stops only.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Navigate to location selection and get result
    final result = await Get.toNamed(
      AppRoutes.selectSavedLocation,
      arguments: {'isSelectingStop': true, 'label': AppStrings.addStops.tr},
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
        _stopLocalKeys.add('new_${_newStopCounter++}');
        controller.stopUpdatePreview.value = null; // Reset preview on change
      });
    }
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      _stopLocalKeys.removeAt(index);
      controller.stopUpdatePreview.value = null; // Reset preview on change
    });
  }

  void _reorderStops(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _stops.removeAt(oldIndex);
      final key = _stopLocalKeys.removeAt(oldIndex);
      _stops.insert(newIndex, item);
      _stopLocalKeys.insert(newIndex, key);
      controller.stopUpdatePreview.value = null; // Reset preview on change
    });
  }

  void _onSave() async {
    // Destination mode mirrors the add-stops UX:
    // first tap previews fare (confirm=false), second tap applies (confirm=true).
    if (_isDestinationEditor) {
      final selected = _selectedDestination;
      if (selected == null) return;
      setState(() => _isSaving = true);
      if (controller.destinationUpdatePreview.value == null) {
        await controller.previewDropLocationUpdate(selected);
      } else {
        final ok = await controller.applyDropLocationUpdate(selected);
        if (ok) {
          // Close any progress sheet first, then close editor screen.
          if (Get.isBottomSheetOpen ?? false) {
            Get.back();
          }
          Get.back();
          return;
        }
      }
      setState(() => _isSaving = false);
      return;
    }

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
        title: Text(
          _isDestinationEditor
              ? AppStrings.changeDropLocation.tr
              : AppStrings.addStops.tr,
        ),
        leading: const AppBackButton(
          color: AppColors.textHeading,
          alignment: Alignment.center,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              children: [
                if (_isDestinationEditor) ...[
                  _buildStaticPoint(
                    'Current Destination',
                    controller.destinationAddress,
                    AppColors.mapDropMarkerGreen,
                  ),
                  if ((_selectedDestination?['address']?.toString() ?? '')
                      .trim()
                      .isNotEmpty)
                    _buildStaticPoint(
                      'New Destination',
                      _selectedDestination?['address']?.toString() ?? '',
                      AppColors.primary,
                    ),
                  _buildChangeDropLocationButton(),
                ] else ...[
                  _buildStaticPoint(
                    'Pickup Point',
                    controller.pickupAddress,
                    AppColors.mapPickupMarkerBlue,
                    isPickup: true,
                  ),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stops.length,
                    proxyDecorator: (widget, index, animation) {
                      return Material(
                        color: AppColors.transparent,
                        child: widget,
                      );
                    },
                    itemBuilder: (context, index) {
                      final stop = _stops[index];
                      final canRemoveDraftStop =
                          _stopLocalKeys[index].startsWith('new_');
                      return Padding(
                        key: ValueKey('stop_${stop.index}_$index'),
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(AppRadius.card),
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
                    AppColors.mapDropMarkerGreen,
                  ),
                ],
              ],
            ),
          ),
          _isDestinationEditor
              ? _buildDestinationPreviewPanel()
              : _buildPreviewPanel(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Obx(() {
                final showButton = _isDestinationEditor
                    ? (_selectedDestination != null ||
                          controller.destinationUpdatePreview.value != null)
                    : (_hasChanges() || controller.stopUpdatePreview.value != null);
                if (!showButton) return const SizedBox.shrink();

                return AppPrimaryButton(
                  label: _isDestinationEditor
                      ? (controller.destinationUpdatePreview.value == null
                            ? 'Update Destination'
                            : 'Confirm & Update')
                      : (controller.stopUpdatePreview.value == null
                            ? 'Update Ride'
                            : 'Confirm & Update'),
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

  Widget _buildChangeDropLocationButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () async {
          // Use the same stop-style location picker used by add-stop flow.
          final selected = await controller.pickNewDropLocation();
          if (selected == null) return;
          if (!mounted) return;
          setState(() {
            _selectedDestination = selected;
          });
          controller.destinationUpdatePreview.value = null;
        },
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
      final preview = controller.destinationUpdatePreview.value;
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
                  'New Estimated Fare:',
                  style: AppTextStyles.homeSubtitle.copyWith(fontSize: 14.sp),
                ),
                Text(
                  'TZS ${controller.priceFormatter(preview.newFareEstimate)}',
                  style: AppTextStyles.price.copyWith(fontSize: 16.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare Difference:',
                  style: AppTextStyles.homeCaption.copyWith(fontSize: 12.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(
                    '$sign TZS ${controller.priceFormatter(delta)}',
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
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: _addStop,
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
                  'New Estimated Fare:',
                  style: AppTextStyles.homeSubtitle.copyWith(fontSize: 14.sp),
                ),
                Text(
                  'TZS ${controller.priceFormatter(preview.newFareEstimate)}',
                  style: AppTextStyles.price.copyWith(fontSize: 16.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare Difference:',
                  style: AppTextStyles.homeCaption.copyWith(fontSize: 12.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(
                    '$sign TZS ${controller.priceFormatter(preview.deltaAmount)}',
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
          border: Border.all(color: AppColors.shade5.withValues(alpha: 0.5)),
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
