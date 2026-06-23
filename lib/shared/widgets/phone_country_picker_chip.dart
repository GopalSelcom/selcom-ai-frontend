import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../data/countries_phone_data.dart';
import '../utils/app_dialogs.dart';
import 'phone_country_picker_controller.dart';

/// Duka-style: emoji flag + dial code, full list from [Countries.all] in a sheet.
class PhoneCountryPickerChip extends StatelessWidget {
  const PhoneCountryPickerChip({
    super.key,
    this.selected,
    required this.onChanged,
    this.inline = false,
  });

  final CountryData? selected;
  final ValueChanged<CountryData> onChanged;

  /// Compact trigger for [AppTextField] prefix areas (no bordered chip chrome).
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected != null) ...[
          Text(
            selected!.flag,
            style: TextStyle(fontSize: inline ? 14.sp : 18.sp),
          ),
          SizedBox(width: 8.w),
          Text(
            selected!.dialCode,
            style: (inline
                    ? AppTextStyles.homeSubtitle
                    : AppTextStyles.body.copyWith(
                        fontFamily: AppTextStyles.metropolisFont,
                      ))
                .copyWith(
              fontWeight: inline ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textHeading,
              fontSize: inline ? 16.sp : 17.sp,
            ),
          ),
        ] else if (inline) ...[
          Text(
            '+',
            style: AppTextStyles.homeSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: AppColors.textBody,
            ),
          ),
        ] else ...[
          Text(
            AppStrings.selectCountry.tr,
            style: AppTextStyles.homeSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17.sp,
              color: AppColors.textBody,
            ),
          ),
        ],
        Icon(
          Icons.keyboard_arrow_down,
          size: inline ? 18.sp : 20.sp,
          color: AppColors.textBody,
        ),
      ],
    );

    if (inline) {
      return InkWell(
        onTap: _openSheet,
        borderRadius: BorderRadius.circular(8.r),
        child: label,
      );
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: _openSheet,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: label,
        ),
      ),
    );
  }

  Future<void> _openSheet() {
    final controllerTag =
        'phone_country_picker_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(
      PhoneCountryPickerController(selected: selected),
      tag: controllerTag,
    );

    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selectCountry.tr,
      subtitle: AppStrings.selectCountrySubtitle.tr,
      headerTextAlign: TextAlign.start,
      maxHeightFactor: 0.85,
      barrierDismissible: true,
      content: _CountryPickerSheet(
        controllerTag: controllerTag,
        onSelect: (country) {
          Get.back<void>();
          onChanged(country);
        },
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (Get.isRegistered<PhoneCountryPickerController>(tag: controllerTag)) {
          Get.delete<PhoneCountryPickerController>(tag: controllerTag);
        }
      });
    });
  }
}

/// Country list body for [AppDialogs.showStandardBottomSheet].
class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet({
    required this.controllerTag,
    required this.onSelect,
  });

  final String controllerTag;
  final ValueChanged<CountryData> onSelect;

  PhoneCountryPickerController get controller =>
      Get.find<PhoneCountryPickerController>(tag: controllerTag);

  /// Space used by [AppStandardBottomSheet] above the scrollable body.
  static double _standardSheetHeaderHeight(BuildContext context) {
    return 10.h + 5.h + 13.h + 56.h + 14.h + 1.h + 16.h + 8.h;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;

    final bodyMaxHeight =
        (screenH * 0.85 -
                keyboard -
                _standardSheetHeaderHeight(context) -
                safeBottom)
            .clamp(160.0, screenH * 0.55);

    final searchBlockHeight = 56.h;
    final listHeight = (bodyMaxHeight - searchBlockHeight - 12.h).clamp(
      80.0,
      bodyMaxHeight - searchBlockHeight,
    );

    final lightOnSheet = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.cardBackground,
        onSurface: AppColors.textHeading,
      ),
    );

    return Theme(
      data: lightOnSheet,
      child: Obx(() {
        controller.searchQuery.value;
        final filtered = controller.filteredCountries;

        return SizedBox(
          height: bodyMaxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CountrySearchField(onChanged: controller.updateSearch),
              SizedBox(height: 12.h),
              SizedBox(
                height: listHeight,
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.noCountriesFound.tr,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.only(bottom: 8.h),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, i) {
                          final country = filtered[i];
                          final isSel =
                              country.code == controller.selected?.code;
                          return InkWell(
                            onTap: () => onSelect(country),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                color: isSel
                                    ? AppColors.primaryLight
                                    : AppColors.surfaceSubtle,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    country.flag,
                                    style: TextStyle(fontSize: 22.sp),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      country.name,
                                      style: AppTextStyles.homeSubtitle
                                          .copyWith(
                                        fontSize: 15.sp,
                                        color: AppColors.textHeading,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    country.dialCode,
                                    style: AppTextStyles.homeSubtitle.copyWith(
                                      fontSize: 14.sp,
                                      color: AppColors.textBody,
                                    ),
                                  ),
                                  if (isSel) ...[
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 20.sp,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CountrySearchField extends StatefulWidget {
  const _CountrySearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_CountrySearchField> createState() => _CountrySearchFieldState();
}

class _CountrySearchFieldState extends State<_CountrySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.text,
      onChanged: widget.onChanged,
      style: AppTextStyles.body.copyWith(
        fontSize: 16.sp,
        color: AppColors.textHeading,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        hintText: AppStrings.searchCountry.tr,
        hintStyle: AppTextStyles.hint.copyWith(
          fontSize: 14.sp,
          color: AppColors.textHint,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.textBody,
          size: 22.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 12.h,
        ),
      ),
    );
  }
}
