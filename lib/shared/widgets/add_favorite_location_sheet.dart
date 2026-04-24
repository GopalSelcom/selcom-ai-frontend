import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';
import 'app_draggable_bottom_sheet.dart';
import 'app_primary_button.dart';

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
  State<AddFavoriteLocationSheet> createState() => _AddFavoriteLocationSheetState();
}

class _AddFavoriteLocationSheetState extends State<AddFavoriteLocationSheet> {
  static const List<String> _labels = <String>['Home', 'Work', 'Office', 'Add New'];
  final TextEditingController _customLabelController = TextEditingController();
  String _selectedLabel = 'Home';

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0.92.sh,
      child: AppDraggableBottomSheet(
        initialChildSize: 0.50,
        minChildSize: 0.30,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.45, 0.65, 0.92],
        childBuilder: (scrollController) {
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
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
                'Add to favourates',
                style: AppTextStyles.homeTitle.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF132235),
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  widget.address,
                  style: AppTextStyles.homeCaption.copyWith(
                    fontSize: 14.sp,
                    color: const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Save Location As',
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF132235),
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
                TextField(
                  controller: _customLabelController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Enter custom label',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                  ),
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
          );
        },
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
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isAddNew ? AppColors.primary : const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: isAddNew
                  ? Icon(Icons.add, color: Colors.white, size: 14.sp)
                  : SvgPictureAsset(iconPath, width: 16.w, height: 16.h),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyles.homeChip.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.shade1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
