import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/requests/save_user_additional_details_request.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/usecases/save_user_additional_details_use_case.dart';
import 'auth_controller.dart';

class SignUpController extends GetxController {
  SignUpController({required this.saveUserAdditionalDetailsUseCase});

  final SaveUserAdditionalDetailsUseCase saveUserAdditionalDetailsUseCase;
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final acceptedTerms = false.obs;
  final submitted = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final formTick = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _prefillSignUpFields();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void _prefillSignUpFields() {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final name = auth.pendingSignUpName.value.trim();
      final email = auth.pendingSignUpEmail.value.trim();
      if (name.isNotEmpty) {
        nameController.text = name;
      }
      if (email.isNotEmpty) {
        emailController.text = email;
      }
      if (name.isNotEmpty || email.isNotEmpty) {
        formTick.value++;
        return;
      }
    }
    unawaited(_prefillFromStoredUser());
  }

  Future<void> _prefillFromStoredUser() async {
    final raw = await StorageService().read(StorageKeys.user);
    if (raw == null || raw.isEmpty) return;

    final user = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    var updated = false;
    if (nameController.text.trim().isEmpty &&
        (user.name?.trim().isNotEmpty ?? false)) {
      nameController.text = user.name!.trim();
      updated = true;
    }
    if (emailController.text.trim().isEmpty &&
        (user.emailId?.trim().isNotEmpty ?? false)) {
      emailController.text = user.emailId!.trim();
      updated = true;
    }
    if (updated) {
      formTick.value++;
    }
  }

  void onNameChanged(String _) => formTick.value++;

  void onEmailChanged(String _) => formTick.value++;

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
    if (value.isEmpty) return AppStrings.emailIsRequired.tr;
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.pleaseEnterAValidEmail.tr;
    }
    return null;
  }

  bool get canSubmit =>
      acceptedTerms.value &&
      nameError == null &&
      emailError == null &&
      !isLoading.value;

  void markSubmitted() {
    submitted.value = true;
    formTick.value++;
  }

  Future<bool> submitAdditionalDetails() async {
    markSubmitted();
    if (!canSubmit) return false;

    if (isLoading.value) return false;
    errorMessage.value = '';

    final saved = await Loader.withFlag(isLoading, () async {
      final result = await saveUserAdditionalDetailsUseCase.call(
        request: SaveUserAdditionalDetailsRequest(
          name: nameController.text.trim(),
          emailId: emailController.text.trim(),
        ),
      );

      return await result.fold(
        (failure) async {
          errorMessage.value = failure.message;
          return false;
        },
        (user) async {
          await StorageService().write(
            StorageKeys.user,
            jsonEncode(user.toJson()),
          );
          await StorageService().write(StorageKeys.signupCompleted, 'true');
          return true;
        },
      );
    });

    if (saved) {
      Get.offAllNamed(AppRoutes.home);
    }
    return saved;
  }
}
