import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/models/contact_us_models.dart';
import '../../../ride/domain/repositories/ride_repository.dart';

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

  final selectedReason = 'Select a Reason'.obs;
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
    if (selectedReason.value == 'Select a Reason') {
      AppDialogs.showErrorDialog(message: 'Please select a reason');
      return;
    }
    if (messageController.text.isEmpty) {
      AppDialogs.showErrorDialog(message: 'Please enter a message');
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
        Get.snackbar('Success', success.message);
      },
    );
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
