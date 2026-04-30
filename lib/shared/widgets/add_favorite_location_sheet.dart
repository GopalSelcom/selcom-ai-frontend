import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';
import 'app_primary_button.dart';
import 'app_text_field.dart';

class AddFavoriteLocationSheet extends StatefulWidget {
  const AddFavoriteLocationSheet({
    super.key,
    required this.address,
    required this.isSaving,
    required this.onSave,
  });

  final String address;
  final bool isSaving;
  final Future<void> Function(String label) onSave;

  @override
  State<AddFavoriteLocationSheet> createState() =>
      _AddFavoriteLocationSheetState();
}

class _AddFavoriteLocationSheetState extends State<AddFavoriteLocationSheet> {
  static const List<String> _labels = <String>[
    'Home',
    'Work',
    'Office',
    'Add New',
  ];
  final TextEditingController _customLabelController = TextEditingController();
  String _selectedLabel = 'Home';

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.92.sh),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(37.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Add to Favourites',
                style: AppTextStyles.homeTitle.copyWith(
                  height: 34 / 20,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  widget.address,
                  style: AppTextStyles.homeCaption.copyWith(height: 20 / 12),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Save Location As',
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: _labels.map((label) {
                  final isSelected = _selectedLabel == label;
                  return _labelChip(
                    label: label,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedLabel = label;
                        if (label != 'Add New') _customLabelController.clear();
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selectedLabel == 'Add New') ...[
                SizedBox(height: 12.h),
                AppTextField(
                  hintText: 'Enter custom label',
                  controller: _customLabelController,
                  textInputAction: TextInputAction.done,
                  textFieldBackgroundColor: AppColors.white,
                  textColor: AppColors.textHeading,
                  enableEnhancedStyle: false,
                ),
              ],
              SizedBox(height: 22.h),
              AppPrimaryButton(
                label: 'Save Address',
                isLoading: widget.isSaving,
                onPressed: () async {
                  final selected = _selectedLabel == 'Add New'
                      ? _customLabelController.text.trim()
                      : _selectedLabel;
                  await widget.onSave(selected);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isAddNew = label == 'Add New';
    final iconPath = label.toLowerCase() == 'home'
        ? AppAssets.icHomeChip
        : label.toLowerCase() == 'work'
        ? AppAssets.icWorkChip
        : AppAssets.icOfficeChip;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderWalletCard,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isAddNew
                ? SvgPictureAsset(
                    AppAssets.locationIcAdd,
                    width: 16.w,
                    height: 16.w,
                    color: AppColors.primary,
                    placeholderBuilder: (_) => Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                      size: 18.sp,
                    ),
                  )
                : SvgPictureAsset(iconPath, width: 16.w, height: 16.w),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyles.homeChip.copyWith(
                color: AppColors.figmaTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
