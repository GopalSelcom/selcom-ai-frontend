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
import '../utils/saved_places_ordering.dart';
import 'app_animated_reveal.dart';
import 'app_primary_button.dart';
import 'app_saved_place_chip.dart';
import 'app_text_field.dart';

/// One chip in the add-favourite picker (same order as [FavoriteLocationChipsRow]).
sealed class _AddFavoriteChipEntry {
  const _AddFavoriteChipEntry();

  String get selectionKey;
}

final class _AddFavoritePresetChip extends _AddFavoriteChipEntry {
  _AddFavoritePresetChip(this.slotId);

  final FavoriteLocationSlotId slotId;

  @override
  String get selectionKey => FavoriteLocationChipCatalog.presetKey(slotId);
}

final class _AddFavoriteExtraChip extends _AddFavoriteChipEntry {
  _AddFavoriteExtraChip(this.place);

  final SavedPlace place;

  @override
  String get selectionKey => 'extra:${place.id ?? SavedPlacesOrdering.effectiveLabel(place)}';
}

final class _AddFavoriteAddNewChip extends _AddFavoriteChipEntry {
  const _AddFavoriteAddNewChip();

  @override
  String get selectionKey => 'add_new';
}

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

  /// Filled presets → custom saved labels → empty presets → Add New (matches Home).
  List<_AddFavoriteChipEntry> _chipsForDisplay() {
    final extras = SavedPlacesOrdering.beyondPresetSlots(widget.savedPlaces);
    final groups = FavoriteLocationChipCatalog.slotDisplayGroups(
      resolvePlace: widget.resolveSavedPlace,
    );

    return [
      ...groups.filled.map(_AddFavoritePresetChip.new),
      ...extras.map(_AddFavoriteExtraChip.new),
      ...groups.empty.map(_AddFavoritePresetChip.new),
      const _AddFavoriteAddNewChip(),
    ];
  }

  String _labelForSave(_AddFavoriteChipEntry? entry) {
    if (entry == null) return '';
    return switch (entry) {
      _AddFavoriteAddNewChip() => _customLabelController.text.trim(),
      _AddFavoriteExtraChip(place: final place) =>
        SavedPlacesOrdering.effectiveLabel(place),
      _AddFavoritePresetChip(slotId: final slotId) =>
        FavoriteLocationChipCatalog.canonicalLabel(slotId),
    };
  }

  _AddFavoriteChipEntry? _entryForSelectionKey(String key) {
    for (final entry in _chipsForDisplay()) {
      if (entry.selectionKey == key) return entry;
    }
    return null;
  }

  /// Chrome above scroll body in [AppStandardBottomSheet] (handle + title + subtitle).
  static double _standardSheetHeaderHeight(BuildContext context) {
    return 10.h + 5.h + 13.h + 72.h + 14.h + 1.h + 16.h + 8.h;
  }

  double _estimateContentHeight(int chipCount) {
    final chipRows = (chipCount / 3).ceil();
    var height = 52.h + 20.h + 28.h + 10.h + (chipRows * 48.h).clamp(108.h, 200.h);
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

    final maxCap =
        (screenH * 0.92 - _standardSheetHeaderHeight(context) - safeBottom)
            .clamp(240.0, screenH * 0.75);

    return Obx(() {
      widget.savedPlaces.length;
      final chips = _chipsForDisplay();

      final bodyHeight = keyboard > 0
          ? (maxCap - keyboard).clamp(180.0, maxCap)
          : _estimateContentHeight(chips.length).clamp(200.0, maxCap);

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
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: chips.map((entry) {
                  final isSelected = _selectedLabel == entry.selectionKey;
                  return _labelChip(
                    entry: entry,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _hasUserSelectedLabel = true;
                        _selectedLabel = entry.selectionKey;
                        if (entry is! _AddFavoriteAddNewChip) {
                          _customLabelController.clear();
                        }
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
                        final entry = _entryForSelectionKey(_selectedLabel);
                        await widget.onSave(_labelForSave(entry));
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _labelChip({
    required _AddFavoriteChipEntry entry,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    if (entry is _AddFavoriteAddNewChip) {
      return AppSavedPlaceChip(
        label: AppStrings.addNew.tr,
        iconAsset: AppAssets.locationIcAdd,
        iconColor: AppColors.primary,
        onTap: onTap,
        backgroundColor: isSelected ? AppColors.primaryLight : null,
        borderColor: isSelected ? AppColors.primary : null,
      );
    }

    if (entry is _AddFavoriteExtraChip) {
      final title = SavedPlacesOrdering.effectiveLabel(entry.place);
      final display =
          title.capitalizeFirst ?? (title.isEmpty ? AppStrings.saved.tr : title);
      return AppSavedPlaceChip(
        label: display,
        iconAsset: AppAssets.icOtherChip,
        onTap: onTap,
        backgroundColor: isSelected ? AppColors.primaryLight : null,
        borderColor: isSelected ? AppColors.primary : null,
      );
    }

    final preset = entry as _AddFavoritePresetChip;
    final canonical = FavoriteLocationChipCatalog.canonicalLabel(preset.slotId);
    final hasSaved = widget.resolveSavedPlace(canonical) != null;
    final iconPath = hasSaved
        ? FavoriteLocationChipCatalog.categoryIconAsset(preset.slotId)
        : FavoriteLocationChipCatalog.emptySlotIconAsset;

    return AppSavedPlaceChip(
      label: _presetDisplayTitle(preset.slotId),
      iconAsset: iconPath,
      iconColor: hasSaved ? null : AppColors.primary,
      onTap: onTap,
      backgroundColor: isSelected ? AppColors.primaryLight : null,
      borderColor: isSelected ? AppColors.primary : null,
    );
  }

  String _presetDisplayTitle(FavoriteLocationSlotId id) {
    switch (id) {
      case FavoriteLocationSlotId.home:
        return AppStrings.home.tr;
      case FavoriteLocationSlotId.office:
        return AppStrings.office.tr;
      case FavoriteLocationSlotId.work:
        return AppStrings.work.tr;
      case FavoriteLocationSlotId.other:
        return AppStrings.other.tr;
    }
  }
}
