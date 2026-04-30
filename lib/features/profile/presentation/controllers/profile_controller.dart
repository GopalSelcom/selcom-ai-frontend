import 'dart:convert';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/web_view_screen.dart';
import '../../../ride/presentation/screens/my_rides_screen.dart';
import '../../domain/usecases/profile_usecase.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';

class ProfileController extends GetxController {
  final ProfileUseCase profileUseCase;
  final AppSettingsService appSettingsService;

  ProfileController({
    required this.profileUseCase,
    required this.appSettingsService,
  });

  // Observables for state
  final RxBool isEditing = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool showSettingsOption = false.obs;

  // User Data
  final Rxn<UserModel> userModel = Rxn<UserModel>();
  final RxString walletBalance = '43,829'.obs;
  final RxString walletNumber = '16010 00000 034'.obs;
  final Rxn<File> pickedImage = Rxn<File>();

  // Controllers for text fields
  late TextEditingController nameTextController;
  late TextEditingController phoneTextController;

  // Focus nodes
  late FocusNode nameFocusNode;
  late FocusNode phoneFocusNode;

  @override
  void onInit() {
    super.onInit();
    nameTextController = TextEditingController();
    phoneTextController = TextEditingController();

    nameFocusNode = FocusNode();
    phoneFocusNode = FocusNode();

    loadUserFromStorage();
    fetchWalletBalance();
    syncSettingsVisibility();
    ever<Map<String, bool>>(appSettingsService.features, (_) {
      syncSettingsVisibility();
    });
  }

  void syncSettingsVisibility() {
    showSettingsOption.value = appSettingsService.hasAnyFeatureEnabled;
  }

  Future<void> loadUserFromStorage() async {
    final data = await StorageService().read(StorageKeys.user);

    if (data != null) {
      final json = jsonDecode(data);
      final user = UserModel.fromJson(json);
      _updateLocalUserState(user);
    }
  }

  void _updateLocalUserState(UserModel user) {
    userModel.value = user;
    nameTextController.text = user.name ?? '';
    final mobile = user.mobileNumber?.toString() ?? '';
    phoneTextController.text = _formatPhoneForDisplay(mobile);
  }

  String _formatPhoneForDisplay(String number) {
    if (number.isEmpty) return '';
    String clean = number
        .replaceAll('+${userModel.value?.countryCode ?? ""}', '')
        .replaceAll(' ', '');
    final formatted = TanzaniaPhoneFormatter.formatString(clean);
    return '+${userModel.value?.countryCode ?? ""} $formatted';
  }

  @override
  void onClose() {
    nameTextController.dispose();
    phoneTextController.dispose();
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    super.onClose();
  }

  Future<void> fetchWalletBalance() async {
    // TODO: Skip API call for now if still pending on backend
    /*
    final result = await profileUseCase.getWalletBalance();
    result.fold(
      (failure) => null,
      (balance) {
        walletBalance.value = balance.balance.toString();
      },
    );
    */
  }

  void toggleEditMode() {
    if (!isEditing.value) {
      isEditing.value = true;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (isEditing.value) {
          nameFocusNode.requestFocus();
        }
      });
    } else {
      isEditing.value = false;
    }
  }

  Future<void> saveProfile() async {
    if (nameTextController.text.trim().isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.validation.tr,
        message: AppStrings.nameCannotBeEmpty.tr,
      );
      return;
    }

    nameFocusNode.unfocus();
    phoneFocusNode.unfocus();

    isLoading.value = true;

    final result = await profileUseCase.saveUserAdditionalDetails(
      name: nameTextController.text.trim(),
      emailId: userModel.value?.emailId ?? '',
      imagePath: pickedImage.value?.path,
    );

    result.fold(
      (failure) {
        AppDialogs.showErrorDialog(message: failure.message);
      },
      (updatedUser) async {
        // Save to storage
        await StorageService().write(
          StorageKeys.user,
          jsonEncode(updatedUser.toJson()),
        );

        // Update local state
        _updateLocalUserState(updatedUser);

        pickedImage.value = null;
        isEditing.value = false;
        AppDialogs.showSuccessDialog(
          message: AppStrings.userProfileUpdatedSuccessfully.tr,
        );
      },
    );

    isLoading.value = false;
  }

  Future<void> pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Optimize image size
      );

      if (image != null) {
        pickedImage.value = File(image.path);
      }
    } catch (e) {
      AppDialogs.showErrorDialog(message: 'Error picking image: $e');
    }
  }

  void cancelEdit() {
    nameFocusNode.unfocus();
    phoneFocusNode.unfocus();
    if (userModel.value != null) {
      _updateLocalUserState(userModel.value!);
    }
    pickedImage.value = null;
    isEditing.value = false;
  }

  void handleBack() {
    if (isEditing.value) {
      cancelEdit();
    } else {
      Get.back();
    }
  }

  void openMyRides() {
    Get.to(() => const MyRidesScreen());
  }

  void openPaymentMethods() {
    Get.toNamed(AppRoutes.paymentMethods);
  }

  void openContactUs() {
    Get.toNamed(AppRoutes.contactUs);
  }

  void openPromotions() {
    Get.toNamed(AppRoutes.promotions);
  }

  void openFavoriteLocations() {
    Get.toNamed(AppRoutes.favoriteLocations);
  }

  void openPrivacyPolicy() {
    Get.to(
      () => WebViewScreen(
        title: AppStrings.privacyPolicy.tr,
        url: "${AppConfig.baseUrl}/${URLS.common.privacy}",
      ),
    );
  }

  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  void openSettings() {
    Get.toNamed(AppRoutes.settings);
  }

  void logout() {
    AppDialogs.showConfirmationDialog(
      title: AppStrings.logout.tr,
      message: 'Are you sure you want to logout from the app?',
      confirmText: 'Logout',
      confirmColor: AppColors.error,
      onConfirm: () async {
        await StorageService().deleteAll();
        Get.offAllNamed(AppRoutes.phone);
      },
    );
  }
}
