import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selcom_rides_frontend/core/widgets/svg_picture_asset.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A card that shows both pickup and drop-off locations in a vertical flow.
/// Designed for Finding Driver and Driver Accepted screens.
/// A card that shows both pickup and drop-off locations in a vertical flow.
/// Designed for Finding Driver and Driver Accepted screens.
/// Supports expansion to show intermediate stops for multi-stop rides.
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
  State<RideLocationSummaryCard> createState() => _RideLocationSummaryCardState();
}

class _RideLocationSummaryCardState extends State<RideLocationSummaryCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    if (widget.intermediateStops.isEmpty) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasStops = widget.intermediateStops.isNotEmpty;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: 61.h,
          maxHeight: _isExpanded ? 800.h : 61.h,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMapCard,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pickup Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildIconContainer(
                    SvgPictureAsset(
                      AppAssets.locationIcPickupPin,
                      width: 14.sp,
                      height: 14.sp,
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
                  if (hasStops)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textHint,
                      size: 18.sp,
                    ),
                ],
              ),

              // Connecting Bridge
              _buildBridge(height: _isExpanded ? 10.h : 4.h),

              if (!_isExpanded) ...[
                // Collapsed Destination Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildIconContainer(
                      SvgPictureAsset(
                        AppAssets.locationIcDestinationPin,
                        width: 14.sp,
                        height: 14.sp,
                        color: AppColors.mapDropMarkerGreen,
                      ),
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
                    if (hasStops) SizedBox(width: 18.sp), // Alignment placeholder
                  ],
                ),
              ] else ...[
                // Expanded View: Intermediate Stops
                ...widget.intermediateStops.map((stop) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildIconContainer(
                            Icon(
                              Icons.location_on,
                              color: AppColors.mapStopMarkerRed,
                              size: 14.sp,
                            ),
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
                    ],
                  );
                }),
                // Final Destination Row (Expanded)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildIconContainer(
                      SvgPictureAsset(
                        AppAssets.locationIcDestinationPin,
                        width: 14.sp,
                        height: 14.sp,
                        color: AppColors.mapDropMarkerGreen,
                      ),
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
                    SizedBox(width: 18.sp),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
          Container(
            width: 1.w,
            height: height,
            color: AppColors.borderDefault,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
