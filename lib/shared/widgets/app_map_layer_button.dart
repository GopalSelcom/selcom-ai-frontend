import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// Toggles between standard and satellite map layers on map screens.
///
/// Icon reflects the *target* layer after tap (map icon → switch to standard,
/// satellite icon → switch to satellite). Wired to [AppMapTypeService] via
/// [AppGoogleMap] or stacked above [AppMapGpsButton] on Home.
class AppMapLayerButton extends StatelessWidget {
  const AppMapLayerButton({
    super.key,
    required this.isSatelliteView,
    required this.onPressed,
  });

  final bool isSatelliteView;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = isSatelliteView
        ? AppStrings.mapStandardView.tr
        : AppStrings.mapSatelliteView.tr;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.shadowSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48.w,
            height: 48.w,
            child: Icon(
              isSatelliteView ? Icons.map_outlined : Icons.satellite_alt_outlined,
              color: AppColors.textHeading,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}
