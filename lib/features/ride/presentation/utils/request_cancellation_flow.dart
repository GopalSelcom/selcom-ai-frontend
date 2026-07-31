import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/responses/rides/ride_cancellation_request_response.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/data/models/support_models.dart';
import '../../../../features/auth/domain/repositories/support_repository.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_reason_picker_bottom_sheet.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/repositories/ride_repository.dart';

class _CancellationRequestDraft {
  const _CancellationRequestDraft({
    required this.reason,
    required this.description,
  });

  final String reason;
  final String description;
}

/// Support-reviewed cancellation request (route deviation). Never calls PUT cancel.
class RequestCancellationFlow {
  RequestCancellationFlow({
    required this.rideRepository,
    required this.rideId,
    this.preselectedReason = 'route_deviation',
  });

  final RideRepository rideRepository;
  final String rideId;
  final String preselectedReason;

  /// Opens reason + optional description sheet; returns created ticket data or null.
  Future<RideCancellationRequestResponseData?> run() async {
    if (rideId.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.submitFailed.tr,
        message: AppStrings.rideIdIsMissing.tr,
      );
      return null;
    }

    List<SupportReasonModel> reasons = const [];
    await Loader.run(() async {
      final result = await di.sl<SupportRepository>().getSupportReasons();
      result.fold((_) {}, (data) {
        reasons = data.cancellationReasons.isNotEmpty
            ? data.cancellationReasons
            : data.reasons;
      });
    });

    if (reasons.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.submitFailed.tr,
        message: AppStrings.couldNotLoadCancellationReasons.tr,
      );
      return null;
    }

    final selected = reasons.any((r) => r.value == preselectedReason)
        ? preselectedReason
        : reasons.first.value;
    final selectedLabel = reasons
        .firstWhere(
          (r) => r.value == selected,
          orElse: () => reasons.first,
        )
        .label;

    final draft =
        await AppDialogs.showStandardBottomSheet<_CancellationRequestDraft>(
          barrierDismissible: true,
          sheet: _RequestCancellationSheet(
            reasons: reasons,
            initialReason: selected,
            initialReasonLabel: selectedLabel,
          ),
        );

    if (draft == null || draft.reason.isEmpty) return null;

    RideCancellationRequestResponseData? data;
    Failure? failure;
    await Loader.run(() async {
      final result = await rideRepository.requestCancellation(
        rideId: rideId,
        reason: draft.reason,
        description: draft.description.isEmpty ? null : draft.description,
      );
      result.fold((f) => failure = f, (d) => data = d);
    });

    if (failure is RideNotActiveFailure) {
      AppDialogs.showErrorDialog(
        title: AppStrings.submitFailed.tr,
        message: failure!.message.isNotEmpty
            ? failure!.message
            : AppStrings.rideNotActiveRefresh.tr,
      );
      return null;
    }

    if (failure != null || data == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.submitFailed.tr,
        message: failure?.message.isNotEmpty == true
            ? failure!.message
            : AppStrings.couldNotSubmitCancellationRequest.tr,
      );
      return null;
    }

    return data;
  }
}

class _RequestCancellationSheet extends StatefulWidget {
  const _RequestCancellationSheet({
    required this.reasons,
    required this.initialReason,
    required this.initialReasonLabel,
  });

  final List<SupportReasonModel> reasons;
  final String initialReason;
  final String initialReasonLabel;

  @override
  State<_RequestCancellationSheet> createState() =>
      _RequestCancellationSheetState();
}

class _RequestCancellationSheetState extends State<_RequestCancellationSheet> {
  late final TextEditingController _descriptionController;
  late final RxString _selectedReason;
  late final RxString _selectedReasonLabel;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _selectedReason = widget.initialReason.obs;
    _selectedReasonLabel = widget.initialReasonLabel.obs;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _selectedReason.value;
    if (reason.isEmpty) return;
    final description = _descriptionController.text.trim();
    Get.back(
      result: _CancellationRequestDraft(
        reason: reason,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStandardBottomSheet(
      title: AppStrings.requestToCancel.tr,
      subtitle: AppStrings.requestCancellationSubtitle.tr,
      maxHeightFactor: 0.85,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.selectAReason.tr,
            style: AppTextStyles.homeSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: 8.h),
          Obx(
            () => Material(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await AppReasonPickerBottomSheet.show(
                    content: Obx(
                      () => AppReasonPickerBottomSheet(
                        options: widget.reasons
                            .map(
                              (r) => AppReasonPickerOption(
                                label: r.label,
                                value: r.value,
                              ),
                            )
                            .toList(growable: false),
                        selectedValue: _selectedReason.value,
                        onSelected: (option) {
                          _selectedReason.value = option.value;
                          _selectedReasonLabel.value = option.label;
                        },
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedReasonLabel.value,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSlate,
                        size: 22.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.optionalDetails.tr,
            style: AppTextStyles.homeSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: 8.h),
          AppTextField(
            controller: _descriptionController,
            hintText: AppStrings.describeWhatHappenedHint.tr,
            maxLines: 3,
          ),
          SizedBox(height: 8.h),
        ],
      ),
      footer: Obx(
        () => AppPrimaryButton(
          label: AppStrings.submitRequest.tr,
          onPressed: _selectedReason.value.isEmpty ? null : _submit,
        ),
      ),
    );
  }
}
