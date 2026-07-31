import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/requests/send_email_request.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_reason_picker_bottom_sheet.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class ContactUsController extends GetxController {
  final ProfileRepository profileRepository;
  final RideRepository rideRepository;

  ContactUsController({
    required this.profileRepository,
    required this.rideRepository,
  });

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final subjects = <String>[].obs;
  final supportNumber = ''.obs;
  final supportEmail = ''.obs;
  final emailText = ''.obs;

  final selectedReason = AppStrings.selectAReason.tr.obs;
  final messageController = TextEditingController();
  final canSubmit = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;

    final result = await profileRepository.getEmailSubjects();

    result.fold(
      (failure) => AppDialogs.showErrorDialog(message: failure.message),
      (data) {
        subjects.assignAll(data.subjectList);
        supportNumber.value = data.supportNumber ?? '';
        supportEmail.value = data.supportEmail ?? '';
        emailText.value = data.emailText ?? '';
      },
    );

    isLoading.value = false;
  }

  Future<void> sendMessage() async {
    if (selectedReason.value == AppStrings.selectAReason.tr) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseSelectAReason.tr);
      return;
    }
    if (messageController.text.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterAMessage.tr);
      return;
    }

    if (isSubmitting.value) return;

    await Loader.withFlag(isSubmitting, () async {
      final result = await profileRepository.sendEmail(
        SendEmailRequest(
          subject: selectedReason.value,
          message: messageController.text,
        ),
      );

      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (success) {
          Get.back();
          AppDialogs.showSuccessDialog(message: success.message ?? '');
        },
      );
    });
  }

  void onMessageChanged(String value) {
    _updateCanSubmit();
  }

  void setSelectedReason(String reason) {
    selectedReason.value = reason;
    _updateCanSubmit();
  }

  void openReasonPicker() {
    final placeholder = AppStrings.selectAReason.tr;
    AppReasonPickerBottomSheet.show(
      content: Obx(() {
        return AppReasonPickerBottomSheet(
          options: [
            for (final subject in subjects)
              AppReasonPickerOption(label: subject, value: subject),
          ],
          selectedValue: selectedReason.value == placeholder
              ? ''
              : selectedReason.value,
          onSelected: (option) => setSelectedReason(option.value),
        );
      }),
    );
  }

  void _updateCanSubmit() {
    final hasReason = selectedReason.value != AppStrings.selectAReason.tr;
    final hasMessage = messageController.text.trim().isNotEmpty;
    canSubmit.value = hasReason && hasMessage;
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
