import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/web_view_screen.dart';
import '../../../ride/presentation/screens/my_rides_screen.dart';
import '../../../wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../../wallet/presentation/utils/wallet_format_utils.dart';
import '../../data/models/request/update_profile_request.dart';
import '../../domain/usecases/profile_usecase.dart';
class ProfileController extends GetxController {
  final ProfileUseCase profileUseCase;
  final AppSettingsService appSettingsService;
  final GetWalletSummaryUseCase getWalletSummaryUseCase;

  ProfileController({
    required this.profileUseCase,
    required this.appSettingsService,
    required this.getWalletSummaryUseCase,
  });

  // Observables for state
  final RxBool isEditing = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingProfile = true.obs;
  final RxBool showSettingsOption = false.obs;
  final RxBool showSafetyOption = false.obs;

  // User Data
  final Rxn<UserModel> userModel = Rxn<UserModel>();
  final RxString walletBalance = ''.obs;
  final RxString walletNumber = ''.obs;
  final RxBool isWalletLinked = false.obs;
  final RxBool isLoadingWallet = true.obs;
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

    fetchWalletBalance();
    unawaited(_loadInitialContent());
    ever<Map<String, bool>>(appSettingsService.features, (_) {
      syncSettingsVisibility();
    });
  }

  /// Menu rows shown when not loading (must match [_buildSettingsList]).
  int get visibleMenuItemCount {
    var count = 4;
    if (showSafetyOption.value) count++;
    if (showSettingsOption.value) count++;
    return count;
  }

  Future<void> _loadInitialContent() async {
    isLoadingProfile.value = true;
    try {
      await _syncProfileMenuVisibility();
      await _fetchProfileData();
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> _syncProfileMenuVisibility() async {
    await appSettingsService.preload();
    syncSettingsVisibility();
  }

  void syncSettingsVisibility() {
    showSettingsOption.value = appSettingsService.hasAnyFeatureEnabled;
    showSafetyOption.value = !appSettingsService.featureEnabled(
      'ride_pin_admin_required',
    );
  }

  Future<void> fetchProfile() async {
    await _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final result = await profileUseCase.getProfile();
    result.fold(
      (failure) {
        AppDialogs.showErrorDialog(message: failure.message);
      },
      (user) {
        _updateLocalUserState(user);
      },
    );
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
    isLoadingWallet.value = true;
    try {
      final summary = await getWalletSummaryUseCase();
      final account = summary.walletNumber.trim();
      if (account.isEmpty) {
        _setWalletUnlinked();
        return;
      }
      isWalletLinked.value = true;
      walletBalance.value = NumberFormat('#,##0', 'en_US').format(summary.balance);
      walletNumber.value = formatWalletAccountNumber(account);
    } catch (_) {
      _setWalletUnlinked();
    } finally {
      isLoadingWallet.value = false;
    }
  }

  void _setWalletUnlinked() {
    isWalletLinked.value = false;
    walletBalance.value = '';
    walletNumber.value = '';
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

    if (isLoading.value) return;

    nameFocusNode.unfocus();
    phoneFocusNode.unfocus();

    String? failureMessage;
    var saved = false;

    await Loader.withFlag(isLoading, () async {
      final result = await profileUseCase.updateProfile(
        UserProfileUpdateRequest(
          image: pickedImage.value,
          name: nameTextController.text.trim(),
          emailId: '',
          userId: userModel.value?.id ?? '',
          dob: '',
          nidaNumber: '',
        ),
      );

      await result.fold(
        (failure) async {
          failureMessage = failure.message;
        },
        (updatedUser) async {
          final refreshed = await profileUseCase.getProfile();
          refreshed.fold(
            (_) {
              final userModel = UserModel.fromJson(
                updatedUser.response?.toJson() ?? const {},
              );
              _updateLocalUserState(userModel);
            },
            (freshUser) {
              _updateLocalUserState(freshUser);
            },
          );
          saved = true;
        },
      );
    });

    if (failureMessage != null) {
      AppDialogs.showErrorDialog(message: failureMessage!);
      return;
    }
    if (!saved) return;

    pickedImage.value = null;
    isEditing.value = false;
    AppDialogs.showSuccessDialog(
      message: AppStrings.userProfileUpdatedSuccessfully.tr,
    );
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
        await saveProfile();
      }
    } catch (e) {
      AppDialogs.showErrorDialog(
        message: AppStrings.errorPickingImage.trParams({'error': e.toString()}),
      );
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

  void openWallet() {
    Get.toNamed(AppRoutes.wallet);
  }

  void openContactUs() {
    Get.toNamed(AppRoutes.contactUs);
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

  void openSafety() {
    Get.toNamed(AppRoutes.safety);
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
      message: AppStrings.areYouSureYouWantToLogoutFromTheApp.tr,
      confirmText: AppStrings.logout.tr,
      onConfirm: () async {
        SessionExpiryService.teardownOnLogout();
        await StorageService().deleteAll();
        Get.offAllNamed(AppRoutes.phone);
      },
    );
  }
}
