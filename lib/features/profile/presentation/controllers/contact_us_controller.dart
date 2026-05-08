import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../data/models/contact_us_models.dart';
import '../../domain/repositories/profile_repository.dart';

class ContactUsController extends GetxController {
  final ProfileRepository profileRepository;
  final RideRepository rideRepository;

  ContactUsController({
    required this.profileRepository,
    required this.rideRepository,
  });

  final isLoading = false.obs;
  final subjects = <String>[].obs;
  final supportNumber = ''.obs;
  final supportEmail = ''.obs;
  final emailText = ''.obs;

  final selectedReason = AppStrings.selectAReason.tr.obs;
  final messageController = TextEditingController();

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
        final res = data;
        subjects.assignAll(res.subjects ?? []);
        supportNumber.value = res.supportNumber ?? '';
        supportEmail.value = res.supportEmail ?? '';
        emailText.value = res.emailText ?? '';
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

    isLoading.value = true;
    final result = await profileRepository.sendEmail(
      SendEmailRequestModel(
        subject: selectedReason.value,
        message: messageController.text,
      ),
    );

    isLoading.value = false;

    result.fold(
      (failure) => AppDialogs.showErrorDialog(message: failure.message),
      (success) {
        Get.back();
        AppDialogs.showSuccessDialog(message: success.message);
      },
    );
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
