import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_route_location_pin_icon.dart';

/// **No intermediate stops:** one line `pickup | → | destination`.
///
/// **Multi-stop:** default one line `pickup | destination | ↓` (arrow last); tap
/// animates open to the full vertical route (stops + bridges). Height follows content.
class RideLocationSummaryCard extends StatefulWidget {
  const RideLocationSummaryCard({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    this.intermediateStops = const [],
  });

  final String pickupAddress;
  final String destinationAddress;
  final List<String> intermediateStops;

  @override
  State<RideLocationSummaryCard> createState() =>
      _RideLocationSummaryCardState();
}

class _RideLocationSummaryCardState extends State<RideLocationSummaryCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    if (widget.intermediateStops.isEmpty) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: AppColors.borderDefault),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowMapCard,
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  EdgeInsetsGeometry _padding() =>
      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h);

  static const Duration _expandDuration = Duration(milliseconds: 300);
  static const Curve _expandCurve = Curves.easeInOut;

  @override
  Widget build(BuildContext context) {
    final hasStops = widget.intermediateStops.isNotEmpty;

    if (!hasStops) {
      return Container(
        width: double.infinity,
        padding: _padding(),
        decoration: _decoration(),
        child: _buildSimpleOneLinePickupArrowDestination(),
      );
    }

    return GestureDetector(
      onTap: _toggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: _padding(),
        decoration: _decoration(),
        child: AnimatedSize(
          duration: _expandDuration,
          curve: _expandCurve,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? _buildExpandedMultiStopColumn()
              : _buildCollapsedMultiStopOneLine(),
        ),
      ),
    );
  }

  /// Single-stop: `pickup | → | destination`.
  Widget _buildSimpleOneLinePickupArrowDestination() {
    final textStyle = AppTextStyles.homeSubtitle.copyWith(
      color: AppColors.textHeading,
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildIconContainer(
                AppRouteLocationPinIcon.pickup(size: 12.sp),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.pickupAddress,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 6.w),
        Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.textHint,
          size: 18.sp,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Row(
            children: [
              _buildIconContainer(
                AppRouteLocationPinIcon.destination(size: 12.sp),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.destinationAddress,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Multi-stop collapsed: `pickup | destination |` trailing arrow (expand).
  Widget _buildCollapsedMultiStopOneLine() {
    final textStyle = AppTextStyles.homeSubtitle.copyWith(
      color: AppColors.textHeading,
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildIconContainer(
                AppRouteLocationPinIcon.pickup(size: 12.sp),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.pickupAddress,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Row(
            children: [
              _buildIconContainer(
                AppRouteLocationPinIcon.destination(size: 12.sp),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.destinationAddress,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 4.w),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textHint,
          size: 22.sp,
        ),
      ],
    );
  }

  /// Multi-stop expanded: vertical route (previous behavior).
  Widget _buildExpandedMultiStopColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVerticalPickupRow(),
        _buildBridge(height: 10.h),
        ...widget.intermediateStops.asMap().entries.expand((entry) {
          final index = entry.key;
          final stop = entry.value;
          return [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildIconContainer(
                  AppRouteLocationPinIcon.stop(index, size: 12.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    stop,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.textHeading,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 18.sp),
              ],
            ),
            _buildBridge(height: 10.h),
          ];
        }),
        _buildVerticalDestinationRow(isPlaceholderTrailing: true),
      ],
    );
  }

  Widget _buildVerticalPickupRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconContainer(
          AppRouteLocationPinIcon.pickup(
            size: 12.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            widget.pickupAddress,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textHeading,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.expand_less, color: AppColors.textHint, size: 18.sp),
      ],
    );
  }

  Widget _buildVerticalDestinationRow({required bool isPlaceholderTrailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconContainer(
          AppRouteLocationPinIcon.destination(size: 12.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            widget.destinationAddress,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textHeading,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isPlaceholderTrailing) SizedBox(width: 18.sp),
      ],
    );
  }

  Widget _buildIconContainer(Widget child) {
    return SizedBox(
      width: 20.sp,
      child: Center(child: child),
    );
  }

  Widget _buildBridge({required double height}) {
    return Row(
      children: [
        _buildIconContainer(
          Container(width: 1.w, height: height, color: AppColors.borderDefault),
        ),
        const Spacer(),
      ],
    );
  }
}
