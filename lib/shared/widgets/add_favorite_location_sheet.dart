import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/data/models/responses/get_saved_places_response.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../utils/favorite_location_chip_catalog.dart';
import 'app_primary_button.dart';
import 'app_saved_place_chip.dart';
import 'app_text_field.dart';

class AddFavoriteLocationSheet extends StatefulWidget {
  const AddFavoriteLocationSheet({
    super.key,
    required this.address,
    required this.isSaving,
    required this.onSave,
    required this.resolveSavedPlace,
  });

  final String address;
  final bool isSaving;
  final Future<void> Function(String label) onSave;

  /// Same lookup as Home chips ([FavoriteLocationChipsRow]): canonical labels `Home`, `Office`, …
  final SavedPlace? Function(String canonicalLabel) resolveSavedPlace;

  @override
  State<AddFavoriteLocationSheet> createState() =>
      _AddFavoriteLocationSheetState();
}

class _AddFavoriteLocationSheetState extends State<AddFavoriteLocationSheet> {
  /// Home row order: Home, Office, Work, Other — then Add New (unchanged behavior).
  static final List<String> _chipKeys = <String>[
    ...FavoriteLocationSlotId.values.map(FavoriteLocationChipCatalog.presetKey),
    'add_new',
  ];

  final TextEditingController _customLabelController = TextEditingController();
  String _selectedLabel = '';
  bool _hasUserSelectedLabel = false;

  bool get _canSave {
    if (!_hasUserSelectedLabel) return false;
    if (_selectedLabel.isEmpty) return false;
    if (_selectedLabel == 'add_new') {
      return _customLabelController.text.trim().length >= 3;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _resetSelectionState();
  }

  @override
  void didUpdateWidget(covariant AddFavoriteLocationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _resetSelectionState();
    }
  }

  void _resetSelectionState() {
    _selectedLabel = '';
    _hasUserSelectedLabel = false;
    _customLabelController.clear();
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.top - bottomInset - 12.h;
    final maxSheetHeight = availableHeight.clamp(280.h, 0.92.sh);
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.w,
            10.h,
            16.w,
            24.h + mediaQuery.padding.bottom,
          ),
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
                AppStrings.addToFavourites.tr,
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
                AppStrings.saveLocationAs.tr,
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: _chipKeys.map((label) {
                  final isSelected = _selectedLabel == label;
                  return _labelChip(
                    label: label,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _hasUserSelectedLabel = true;
                        _selectedLabel = label;
                        if (label != 'add_new') _customLabelController.clear();
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selectedLabel == 'add_new') ...[
                SizedBox(height: 12.h),
                AppTextField(
                  hintText: AppStrings.enterCustomLabel.tr,
                  controller: _customLabelController,
                  onChanged: (_) => setState(() {
                    _hasUserSelectedLabel = true;
                  }),
                  textInputAction: TextInputAction.done,
                  textFieldBackgroundColor: AppColors.white,
                  textColor: AppColors.textHeading,
                  enableEnhancedStyle: false,
                ),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    child: child,
                  ),
                ),
                child: _canSave
                    ? Padding(
                        key: const ValueKey('save-button-visible'),
                        padding: EdgeInsets.only(top: 22.h),
                        child: AppPrimaryButton(
                          label: AppStrings.saveAddress.tr,
                          isLoading: widget.isSaving,
                          onPressed: () async {
                            final selected = _selectedLabel == 'add_new'
                                ? _customLabelController.text.trim()
                                : _canonicalLabelForPresetKey(_selectedLabel);
                            await widget.onSave(selected);
                          },
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('save-button-hidden')),
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
    if (label == 'add_new') {
      return AppSavedPlaceChip(
        label: _displayLabel(label),
        iconAsset: AppAssets.locationIcAdd,
        iconColor: AppColors.primary,
        onTap: onTap,
        backgroundColor: isSelected ? AppColors.primaryLight : null,
        borderColor: isSelected ? AppColors.primary : null,
      );
    }

    final id = FavoriteLocationSlotId.values.firstWhere(
      (e) => FavoriteLocationChipCatalog.presetKey(e) == label,
    );
    final canonical = FavoriteLocationChipCatalog.canonicalLabel(id);
    final hasSaved = widget.resolveSavedPlace(canonical) != null;
    final iconPath = hasSaved
        ? FavoriteLocationChipCatalog.categoryIconAsset(id)
        : FavoriteLocationChipCatalog.emptySlotIconAsset;

    return AppSavedPlaceChip(
      label: _displayLabel(label),
      iconAsset: iconPath,
      iconColor: hasSaved ? null : AppColors.primary,
      onTap: onTap,
      backgroundColor: isSelected ? AppColors.primaryLight : null,
      borderColor: isSelected ? AppColors.primary : null,
    );
  }

  String _displayLabel(String key) {
    switch (key) {
      case 'home':
        return AppStrings.home.tr;
      case 'office':
        return AppStrings.office.tr;
      case 'work':
        return AppStrings.work.tr;
      case 'other':
        return AppStrings.other.tr;
      case 'add_new':
        return AppStrings.addNew.tr;
      default:
        return key;
    }
  }

  String _canonicalLabelForPresetKey(String key) {
    final id = FavoriteLocationSlotId.values.firstWhere(
      (e) => FavoriteLocationChipCatalog.presetKey(e) == key,
      orElse: () => FavoriteLocationSlotId.other,
    );
    return FavoriteLocationChipCatalog.canonicalLabel(id);
  }
}
