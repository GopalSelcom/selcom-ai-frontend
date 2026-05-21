import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../data/countries_phone_data.dart';
import '../utils/app_dialogs.dart';

/// Duka-style: emoji flag + dial code, full list from [Countries.all] in a sheet.
class PhoneCountryPickerChip extends StatelessWidget {
  const PhoneCountryPickerChip({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CountryData selected;
  final ValueChanged<CountryData> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => _openSheet(),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selected.flag, style: TextStyle(fontSize: 18.sp)),
              SizedBox(width: 8.w),
              Text(
                selected.dialCode,
                style: AppTextStyles.body.copyWith(
                  fontFamily: AppTextStyles.metropolisFont,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHeading,
                  fontSize: 17.sp,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20.sp,
                color: AppColors.textBody,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet() {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selectCountry.tr,
      subtitle: AppStrings.selectCountrySubtitle.tr,
      headerTextAlign: TextAlign.start,
      maxHeightFactor: 0.85,
      barrierDismissible: true,
      content: _CountryPickerSheet(
        selected: selected,
        onSelect: (country) {
          Get.back<void>();
          onChanged(country);
        },
      ),
    );
  }
}

/// Country list body for [AppDialogs.showStandardBottomSheet].
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected, required this.onSelect});

  final CountryData selected;
  final ValueChanged<CountryData> onSelect;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _search = TextEditingController();
  List<CountryData> _filtered = Countries.all;

  @override
  void initState() {
    super.initState();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.removeListener(_filter);
    _search.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _search.text.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    setState(() {
      if (q.isEmpty) {
        _filtered = Countries.all;
      } else {
        _filtered = Countries.all.where((c) {
          final dialNorm = c.dialCode.replaceAll('+', '');
          return c.name.toLowerCase().contains(q) ||
              c.dialCode.toLowerCase().contains(q) ||
              (qDigits.isNotEmpty && dialNorm.contains(qDigits)) ||
              c.code.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

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

    // Match [AppStandardBottomSheet] max body (0.85) minus chrome and keyboard.
    final bodyMaxHeight = (screenH * 0.85 -
            keyboard -
            _standardSheetHeaderHeight(context) -
            safeBottom)
        .clamp(160.0, screenH * 0.55);

    final searchBlockHeight = 56.h;
    final listHeight = (bodyMaxHeight - searchBlockHeight - 12.h)
        .clamp(80.0, bodyMaxHeight - searchBlockHeight);

    // Sheet uses light surfaces; force dark input/list text when app theme is dark.
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
      child: SizedBox(
        height: bodyMaxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search,
              keyboardType: TextInputType.text,
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
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: listHeight,
              child: _filtered.isEmpty
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
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, i) {
                        final c = _filtered[i];
                        final isSel = c.code == widget.selected.code;
                        return InkWell(
                          onTap: () => widget.onSelect(c),
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
                                Text(c.flag, style: TextStyle(fontSize: 22.sp)),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: AppTextStyles.homeSubtitle.copyWith(
                                      fontSize: 15.sp,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                ),
                                Text(
                                  c.dialCode,
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
      ),
    );
  }
}
