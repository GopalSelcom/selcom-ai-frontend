import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/data/models/responses/get_saved_places_response.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../utils/app_dialogs.dart';
import '../utils/favorite_location_chip_catalog.dart';
import 'app_animated_reveal.dart';
import 'app_primary_button.dart';
import 'app_saved_place_chip.dart';
import 'app_text_field.dart';

/// Save-as-favourite picker body for [AppDialogs.showStandardBottomSheet].
class AddFavoriteLocationSheet extends StatefulWidget {
  const AddFavoriteLocationSheet({
    super.key,
    required this.address,
    required this.onSave,
    required this.resolveSavedPlace,
    required this.isSaving,
    required this.savedPlaces,
  });

  final String address;
  final Future<void> Function(String label) onSave;

  /// Same lookup as Home chips ([FavoriteLocationChipsRow]): canonical labels `Home`, `Office`, …
  final SavedPlace? Function(String canonicalLabel) resolveSavedPlace;

  /// Reactive saving flag (e.g. [HomeController.isSavingPlace]).
  final RxBool isSaving;

  /// Saved places list so chip icons refresh when favourites change.
  final RxList<SavedPlace> savedPlaces;

  static Future<void> show({
    required String address,
    required Future<void> Function(String label) onSave,
    required SavedPlace? Function(String canonicalLabel) resolveSavedPlace,
    required RxBool isSaving,
    required RxList<SavedPlace> savedPlaces,
  }) {
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.addToFavourites.tr,
      subtitle: AppStrings.addToFavouritesSubtitle.tr,
      headerTextAlign: TextAlign.start,
      maxHeightFactor: 0.92,
      barrierDismissible: true,
      content: AddFavoriteLocationSheet(
        address: address,
        onSave: onSave,
        resolveSavedPlace: resolveSavedPlace,
        isSaving: isSaving,
        savedPlaces: savedPlaces,
      ),
    );
  }

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

  /// Chrome above scroll body in [AppStandardBottomSheet] (handle + title + subtitle).
  static double _standardSheetHeaderHeight(BuildContext context) {
    return 10.h + 5.h + 13.h + 72.h + 14.h + 1.h + 16.h + 8.h;
  }

  double _estimateContentHeight() {
    var height = 52.h + 20.h + 28.h + 10.h + 108.h;
    if (_selectedLabel == 'add_new') {
      height += 12.h + 56.h;
    }
    if (_canSave) {
      height += 22.h + 56.h;
    }
    return height + 8.h;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;

    final maxCap = (screenH * 0.92 -
            _standardSheetHeaderHeight(context) -
            safeBottom)
        .clamp(240.0, screenH * 0.75);

    final bodyHeight = keyboard > 0
        ? (maxCap - keyboard).clamp(180.0, maxCap)
        : _estimateContentHeight().clamp(200.0, maxCap);

    return SizedBox(
      height: bodyHeight,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Obx(() {
              widget.savedPlaces.length;
              return Wrap(
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
                        if (label != 'add_new') {
                          _customLabelController.clear();
                        }
                      });
                    },
                  );
                }).toList(),
              );
            }),
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
            Obx(() {
              final saving = widget.isSaving.value;
              return AppAnimatedReveal(
                show: _canSave,
                visibleKey: const ValueKey('save-button-visible'),
                hiddenKey: const ValueKey('save-button-hidden'),
                child: Padding(
                  padding: EdgeInsets.only(top: 22.h, bottom: 8.h),
                  child: AppPrimaryButton(
                    label: AppStrings.saveAddress.tr,
                    isLoading: saving,
                    onPressed: () async {
                      final selected = _selectedLabel == 'add_new'
                          ? _customLabelController.text.trim()
                          : _canonicalLabelForPresetKey(_selectedLabel);
                      await widget.onSave(selected);
                    },
                  ),
                ),
              );
            }),
          ],
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
