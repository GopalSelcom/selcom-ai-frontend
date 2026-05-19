import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

import '../../../../core/data/models/requests/save_user_additional_details_request.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/login_pin_gate_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/usecases/save_user_additional_details_use_case.dart';

class SignUpController extends GetxController {
  SignUpController({required this.saveUserAdditionalDetailsUseCase});

  final SaveUserAdditionalDetailsUseCase saveUserAdditionalDetailsUseCase;
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final acceptedTerms = false.obs;
  final submitted = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final _formTick = 0.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void onNameChanged(String _) => _formTick.value++;
  void onEmailChanged(String _) => _formTick.value++;

  void setAcceptedTerms(bool value) {
    acceptedTerms.value = value;
  }

  String? get nameError {
    final value = nameController.text.trim();
    if (value.isEmpty) return AppStrings.nameIsRequired.tr;
    if (value.length < 2) return AppStrings.pleaseEnterAValidName.tr;
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(value)) {
      return AppStrings.nameContainsInvalidCharacters.tr;
    }
    return null;
  }

  String? get emailError {
    final value = emailController.text.trim();
    if (value.isEmpty) return null;
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) return AppStrings.pleaseEnterAValidEmail.tr;
    return null;
  }

  bool get canSubmit =>
      acceptedTerms.value &&
      nameError == null &&
      emailError == null &&
      !isLoading.value;

  void markSubmitted() {
    submitted.value = true;
    _formTick.value++;
  }

  Future<bool> submitAdditionalDetails() async {
    markSubmitted();
    if (!canSubmit) return false;

    isLoading.value = true;
    errorMessage.value = '';
    final result = await saveUserAdditionalDetailsUseCase.call(
      request: SaveUserAdditionalDetailsRequest(
        name: nameController.text.trim(),
        emailId: emailController.text.trim(),
      ),
    );
    isLoading.value = false;

    return await result.fold((failure) async {
      errorMessage.value = failure.message;
      return false;
    }, (user) async {
      await StorageService().write(
        StorageKeys.user,
        jsonEncode(user.toJson()),
      );
      await StorageService().write(StorageKeys.signupCompleted, 'true');
      // New signup may require app login PIN setup when pin_set == false.
      final nextRoute = await sl<LoginPinGateService>().resolvePostAuthRoute(
        defaultRoute: AppRoutes.home,
      );
      if (nextRoute == AppRoutes.pinSetup) {
        Get.offAllNamed(
          AppRoutes.pinSetup,
          arguments: {'mode': 'setup', 'nextRoute': AppRoutes.home},
        );
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
      return true;
    });
  }
}
