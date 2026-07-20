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
import 'add_favorite_location_controller.dart';
import 'app_primary_button.dart';
import 'app_saved_place_chip.dart';
import 'app_text_field.dart';

/// Save-as-favourite picker body for [AppDialogs.showStandardBottomSheet].
class AddFavoriteLocationSheet extends StatelessWidget {
  const AddFavoriteLocationSheet({
    super.key,
    required this.controllerTag,
  });

  final String controllerTag;

  AddFavoriteLocationController get controller =>
      Get.find<AddFavoriteLocationController>(tag: controllerTag);

  static Future<void> show({
    required String address,
    required Future<void> Function(String label, String address) onSave,
    required SavedPlace? Function(String canonicalLabel) resolveSavedPlace,
    required RxBool isSaving,
    required RxList<SavedPlace> savedPlaces,
  }) {
    final controllerTag =
        'add_favorite_location_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(
      AddFavoriteLocationController(
        address: address,
        onSave: onSave,
        resolveSavedPlace: resolveSavedPlace,
        isSaving: isSaving,
        savedPlaces: savedPlaces,
      ),
      tag: controllerTag,
    );

    final context = Get.context;
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.addToFavourites.tr,
      subtitle: AppStrings.addToFavouritesSubtitle.tr,
      headerTextAlign: TextAlign.start,
      maxHeightFactor: context != null
          ? _scrollBodyMaxHeightFactor(context)
          : 0.65,
      barrierDismissible: true,
      content: AddFavoriteLocationSheet(controllerTag: controllerTag),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (Get.isRegistered<AddFavoriteLocationController>(
          tag: controllerTag,
        )) {
          Get.delete<AddFavoriteLocationController>(tag: controllerTag);
        }
      });
    });
  }

  /// Chrome above scroll body in [AppStandardBottomSheet] (handle + title + subtitle).
  static double _standardSheetHeaderHeight(BuildContext context) {
    return 10.h + 5.h + 13.h + 72.h + 14.h + 1.h + 16.h + 8.h;
  }

  /// Body max height fraction so header + scroll area + safe area fit on screen.
  static double _scrollBodyMaxHeightFactor(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final headerH = _standardSheetHeaderHeight(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomChrome = safeBottom > 0
        ? (GetPlatform.isIOS ? 0.0 : 8.h)
        : 16.h;
    final bodyPadding = 16.h + 8.h;
    final available = screenH - headerH - safeBottom - bottomChrome - bodyPadding;
    return (available / screenH).clamp(0.35, 0.72);
  }

  @override
  Widget build(BuildContext context) {
    return _AddFavoriteLocationSheetBody(controller: controller);
  }
}

class _AddFavoriteLocationSheetBody extends StatefulWidget {
  const _AddFavoriteLocationSheetBody({
    required this.controller,
  });

  final AddFavoriteLocationController controller;

  @override
  State<_AddFavoriteLocationSheetBody> createState() =>
      _AddFavoriteLocationSheetBodyState();
}

class _AddFavoriteLocationSheetBodyState
    extends State<_AddFavoriteLocationSheetBody> {
  final GlobalKey _saveButtonKey = GlobalKey();
  Worker? _canSaveWorker;
  bool _wasCanSave = false;

  AddFavoriteLocationController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _canSaveWorker = everAll(
      [
        controller.selectedLabel,
        controller.customLabelText,
        controller.hasUserSelectedLabel,
      ],
      (_) => _onCanSaveChanged(),
    );
  }

  @override
  void dispose() {
    _canSaveWorker?.dispose();
    super.dispose();
  }

  void _onCanSaveChanged() {
    final canSave = controller.canSave;
    if (canSave && !_wasCanSave) {
      _scheduleScrollSaveButtonIntoView();
    }
    _wasCanSave = canSave;
  }

  void _scheduleScrollSaveButtonIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        final saveContext = _saveButtonKey.currentContext;
        if (saveContext == null || !saveContext.mounted) return;
        Scrollable.ensureVisible(
          saveContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 1.0,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;
    final bottomChrome = safeBottom > 0
        ? (GetPlatform.isIOS ? 0.0 : 8.h)
        : 16.h;
    final bodyPadding = 16.h + 8.h;
    final viewportMaxHeight = (screenH -
            AddFavoriteLocationSheet._standardSheetHeaderHeight(context) -
            safeBottom -
            bottomChrome -
            bodyPadding -
            keyboard)
        .clamp(180.0, screenH * 0.65);

    return Obx(() {
      controller.savedPlaces.length;
      controller.selectedLabel.value;
      controller.customLabelText.value;
      controller.addressNoteText.value;
      controller.hasUserSelectedLabel.value;
      final saving = controller.isSaving.value;

      final chips = controller.chipsForDisplay();

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: viewportMaxHeight),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.skeletonBase),
                ),
                child: Text(
                  controller.effectiveAddress,
                  style: AppTextStyles.homeCaption.copyWith(height: 20 / 12),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                AppStrings.pickupConfirmationNoteLabel.tr,
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              _AddFavoriteAddressNoteField(
                onChanged: controller.onAddressNoteChanged,
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
                  final isSelected =
                      controller.selectedLabel.value == entry.selectionKey;
                  return _labelChip(
                    controller: controller,
                    entry: entry,
                    isSelected: isSelected,
                    onTap: () => controller.selectChip(entry),
                  );
                }).toList(),
              ),
              if (controller.selectedLabel.value == 'add_new') ...[
                SizedBox(height: 12.h),
                _AddFavoriteCustomLabelField(
                  onChanged: controller.onCustomLabelChanged,
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.topCenter,
                child: controller.canSave
                    ? Padding(
                        key: _saveButtonKey,
                        padding: EdgeInsets.only(top: 22.h, bottom: 8.h),
                        child: AppPrimaryButton(
                          label: AppStrings.saveAddress.tr,
                          isLoading: saving,
                          onPressed: controller.saveSelected,
                        ),
                      )
                    : SizedBox(width: double.infinity, height: 0),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _labelChip({
    required AddFavoriteLocationController controller,
    required AddFavoriteChipEntry entry,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    if (entry is AddFavoriteAddNewChip) {
      return AppSavedPlaceChip(
        label: AppStrings.addNew.tr,
        iconAsset: AppAssets.locationIcAdd,
        iconColor: AppColors.primary,
        onTap: onTap,
        backgroundColor: isSelected ? AppColors.primaryLight : null,
        borderColor: isSelected ? AppColors.primary : null,
      );
    }

    if (entry is AddFavoriteExtraChip) {
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

    final preset = entry as AddFavoritePresetChip;
    final canonical = FavoriteLocationChipCatalog.canonicalLabel(preset.slotId);
    final hasSaved = controller.resolveSavedPlace(canonical) != null;
    final iconPath = hasSaved
        ? FavoriteLocationChipCatalog.categoryIconAsset(preset.slotId)
        : FavoriteLocationChipCatalog.emptySlotIconAsset;

    return AppSavedPlaceChip(
      label: controller.presetDisplayTitle(preset.slotId),
      iconAsset: iconPath,
      iconColor: hasSaved ? null : AppColors.primary,
      onTap: onTap,
      backgroundColor: isSelected ? AppColors.primaryLight : null,
      borderColor: isSelected ? AppColors.primary : null,
    );
  }
}

class _AddFavoriteAddressNoteField extends StatefulWidget {
  const _AddFavoriteAddressNoteField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_AddFavoriteAddressNoteField> createState() =>
      _AddFavoriteAddressNoteFieldState();
}

class _AddFavoriteAddressNoteFieldState
    extends State<_AddFavoriteAddressNoteField> {
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
    return AppTextField(
      hintText: AppStrings.pickupConfirmationNoteHint.tr,
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.done,
      textFieldBackgroundColor: AppColors.white,
      textColor: AppColors.textHeading,
      enableEnhancedStyle: false,
    );
  }
}

class _AddFavoriteCustomLabelField extends StatefulWidget {
  const _AddFavoriteCustomLabelField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_AddFavoriteCustomLabelField> createState() =>
      _AddFavoriteCustomLabelFieldState();
}

class _AddFavoriteCustomLabelFieldState extends State<_AddFavoriteCustomLabelField> {
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
    return AppTextField(
      hintText: AppStrings.enterCustomLabel.tr,
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.done,
      textFieldBackgroundColor: AppColors.white,
      textColor: AppColors.textHeading,
      enableEnhancedStyle: false,
    );
  }
}
