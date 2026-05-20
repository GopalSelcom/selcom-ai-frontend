import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../data/countries_phone_data.dart';
import '../../shared/utils/app_dialogs.dart';

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
        onTap: () => _openSheet(context),
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

  Future<void> _openSheet(BuildContext context) async {
    await AppDialogs.showAnimatedBottomSheet<void>(
      barrierDismissible: true,
      child: _CountryPickerSheet(
        selected: selected,
        onSelect: (c) {
          Navigator.of(context).pop();
          onChanged(c);
        },
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.selected,
    required this.onSelect,
  });

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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom;
    final maxSheetH = mq.size.height * 0.72;
    final sheetH = maxSheetH.clamp(320.0, 560.0);

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
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: sheetH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select country',
                          style: AppTextStyles.homeTitle.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textBody, size: 22.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: TextField(
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
                      hintText: 'Search country…',
                      hintStyle: AppTextStyles.hint.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppColors.textBody, size: 22.sp),
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No countries found',
                        style: AppTextStyles.homeSubtitle.copyWith(color: AppColors.textBody),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
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
                                  Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp),
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
        ),
      ),
    );
  }
}
