import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/data/models/user_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/session_auth_service.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/balance_visibility_policy.dart';
import '../../../../shared/utils/clipboard_utils.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/web_view_screen.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../../wallet/domain/entities/wallet_summary_entity.dart';
import '../../../wallet/presentation/utils/wallet_format_utils.dart';
import '../../../wallet/presentation/utils/wallet_session.dart';
import '../../data/cache/user_profile_cache.dart';
import '../../data/models/request/update_profile_request.dart';
import '../../domain/usecases/profile_usecase.dart';

/// In-memory wallet summary for the profile card across [ProfileController]
/// instances (GetX factory recreates the controller each profile visit).
///
/// Lets us skip the card-balance API on revisit and keep the last known amount
/// for a silent eye-button refresh. Cleared on logout via [clear].
abstract final class ProfileWalletCache {
  ProfileWalletCache._();

  /// True after the first successful (or empty) wallet fetch this session.
  static bool isLoaded = false;

  /// Whether the amount is currently shown; always reset to hidden on screen entry.
  static bool isBalanceVisible = false;
  static bool isWalletLinked = false;
  static String balance = '';
  static String currency = '';
  static String walletNumber = '';
  static String walletNumberRaw = '';
  static double reserved = 0;

  static void save({
    required bool linked,
    required String balanceValue,
    required String currencyValue,
    required String walletNumberValue,
    String? walletNumberRawValue,
    double reservedValue = 0,
  }) {
    isLoaded = true;
    isWalletLinked = linked;
    balance = balanceValue;
    currency = currencyValue;
    walletNumber = walletNumberValue;
    walletNumberRaw = walletNumberRawValue?.trim() ?? '';
    reserved = reservedValue;
  }

  /// Shared summary for profile and wallet screens (no network).
  static WalletSummaryEntity? toSummaryEntity() {
    if (!isLoaded || !isWalletLinked) return null;

    final rawNumber = walletNumberRaw.trim().isNotEmpty
        ? walletNumberRaw.trim()
        : walletNumber.replaceAll(RegExp(r'\s+'), '');
    if (rawNumber.isEmpty) return null;

    final balanceValue =
        double.tryParse(balance.replaceAll(',', '')) ?? 0;

    return WalletSummaryEntity(
      balance: balanceValue,
      walletNumber: rawNumber,
      currency: currency.trim().isNotEmpty ? currency.trim() : 'TZS',
      reserved: reserved,
    );
  }

  /// Drops cached wallet fields (logout / unlinked account).
  static void clear() {
    isLoaded = false;
    isBalanceVisible = false;
    isWalletLinked = false;
    balance = '';
    currency = '';
    walletNumber = '';
    walletNumberRaw = '';
    reserved = 0;
  }
}

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
  final RxString walletCurrency = ''.obs;
  final RxString walletNumber = ''.obs;
  final RxBool isWalletLinked = false.obs;
  /// First-visit shimmer for the wallet card (account + amount placeholders).
  final RxBool isLoadingWallet = true.obs;
  /// Eye-tap refresh: keep old amount, show loader in place of the eye icon.
  final RxBool isRefreshingWalletBalance = false.obs;
  /// Amount is hidden by default; revealed only when the user taps the eye.
  final RxBool isBalanceVisible = false.obs;
  final Rxn<File> pickedImage = Rxn<File>();

  Timer? _walletBalanceHideTimer;

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

    // Always mask amount when the profile screen is entered.
    resetWalletBalanceVisibilityOnScreenEntry();

    // Reuse cached wallet on revisit; call API only on the first profile open.
    _restoreWalletFromCacheIfAvailable();
    if (!ProfileWalletCache.isLoaded) {
      unawaited(fetchWalletBalance(initialLoad: true));
    }
    unawaited(_loadInitialContent());
    ever<Map<String, bool>>(appSettingsService.features, (_) {
      syncSettingsVisibility();
    });
  }

  /// Menu rows shown when not loading (must match [_buildSettingsList]).
  int get visibleMenuItemCount {
    var count = 5;
    if (showSafetyOption.value) count++;
    if (showSettingsOption.value) count++;
    return count;
  }

  Future<void> _loadInitialContent() async {
    // Home usually populates [UserProfileCache] first — skip GET + shimmer on revisit.
    final cachedUser = UserProfileCache.user;
    final hasCachedProfile =
        UserProfileCache.isLoaded && cachedUser != null;
    if (hasCachedProfile) {
      _updateLocalUserState(cachedUser);
    } else {
      isLoadingProfile.value = true;
    }
    try {
      await _syncProfileMenuVisibility();
      if (!hasCachedProfile) {
        await _fetchProfileData();
      }
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
    // Repository returns [UserProfileCache] when already loaded this session.
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

  String get displayPhone => PhoneNationalRules.formatMobileForDisplay(
    countryCode: userModel.value?.countryCode,
    mobileNumber: userModel.value?.mobileNumber,
  );

  void _updateLocalUserState(UserModel user) {
    userModel.value = user;
    nameTextController.text = user.name ?? '';
    phoneTextController.text = PhoneNationalRules.formatMobileForDisplay(
      countryCode: user.countryCode,
      mobileNumber: user.mobileNumber,
    );
  }

  @override
  void onClose() {
    _cancelWalletBalanceHideTimer();
    nameTextController.dispose();
    phoneTextController.dispose();
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    super.onClose();
  }

  /// Applies [ProfileWalletCache] without hitting the network.
  void _restoreWalletFromCacheIfAvailable() {
    if (!ProfileWalletCache.isLoaded) return;
    isWalletLinked.value = ProfileWalletCache.isWalletLinked;
    walletBalance.value = ProfileWalletCache.balance;
    walletCurrency.value = ProfileWalletCache.currency;
    walletNumber.value = ProfileWalletCache.walletNumber;
    isLoadingWallet.value = false;
  }

  /// Masks the wallet amount whenever profile is entered or a child route pops.
  void resetWalletBalanceVisibilityOnScreenEntry() {
    _cancelWalletBalanceHideTimer();
    isBalanceVisible.value = false;
    ProfileWalletCache.isBalanceVisible = false;
  }

  void _navigateAndResetWalletBalanceOnReturn(Future<dynamic>? navigation) {
    // Re-mask balance when the user returns from any child route.
    navigation?.then((_) => resetWalletBalanceVisibilityOnScreenEntry());
  }

  /// Loads wallet summary for the profile card.
  ///
  /// - [initialLoad] `true`: first visit — may show shimmer; amount stays hidden.
  /// - [initialLoad] `false`: eye / post-wallet refresh — keep previous amount,
  ///   show loader on the eye slot, then update the amount silently.
  Future<void> fetchWalletBalance({bool initialLoad = false}) async {
    if (initialLoad && ProfileWalletCache.isLoaded) {
      _restoreWalletFromCacheIfAvailable();
      return;
    }

    if (initialLoad) {
      isLoadingWallet.value = true;
    } else {
      // Silent refresh: no shimmer; UI shows spinner instead of the eye icon.
      isRefreshingWalletBalance.value = true;
    }

    try {
      final summary = await getWalletSummaryUseCase();
      final account = summary.walletNumber.trim();
      if (account.isEmpty) {
        _setWalletUnlinked();
        return;
      }
      isWalletLinked.value = true;
      walletBalance.value =
          NumberFormat('#,##0', 'en_US').format(summary.balance);
      walletCurrency.value = summary.currency.trim();
      walletNumber.value = formatWalletAccountNumber(account);
      ProfileWalletCache.save(
        linked: true,
        balanceValue: walletBalance.value,
        currencyValue: walletCurrency.value,
        walletNumberValue: walletNumber.value,
        walletNumberRawValue: account,
        reservedValue: summary.reserved,
      );
      ProfileWalletCache.isBalanceVisible = isBalanceVisible.value;
    } catch (_) {
      // Keep last known amount on refresh failure; only clear on first load.
      if (initialLoad) {
        _setWalletUnlinked();
      }
    } finally {
      isLoadingWallet.value = false;
      isRefreshingWalletBalance.value = false;
    }
  }

  /// Hides the amount, or reveals the cached amount and refreshes from the API.
  ///
  /// Hide is local only (no network). Show reveals the last known amount and
  /// then refreshes once from card balance.
  void toggleWalletBalanceVisibility() {
    if (isRefreshingWalletBalance.value) return;

    // Already visible → hide only; do not call the card-balance API.
    if (isBalanceVisible.value) {
      _hideWalletBalance();
      return;
    }

    // Show old/cached amount immediately; API updates it when the call completes.
    isBalanceVisible.value = true;
    ProfileWalletCache.isBalanceVisible = true;
    _scheduleWalletBalanceHide();
    unawaited(fetchWalletBalance(initialLoad: false));
  }

  /// Masks the amount and cancels the auto-hide timer.
  void _hideWalletBalance() {
    resetWalletBalanceVisibilityOnScreenEntry();
  }

  /// Auto-hides the revealed amount after [BalanceVisibilityPolicy.autoHideAfterReveal].
  void _scheduleWalletBalanceHide() {
    _cancelWalletBalanceHideTimer();
    _walletBalanceHideTimer = Timer(BalanceVisibilityPolicy.autoHideAfterReveal, () {
      _hideWalletBalance();
    });
  }

  void _cancelWalletBalanceHideTimer() {
    _walletBalanceHideTimer?.cancel();
    _walletBalanceHideTimer = null;
  }

  void _setWalletUnlinked() {
    _cancelWalletBalanceHideTimer();
    isWalletLinked.value = false;
    walletBalance.value = '';
    walletCurrency.value = '';
    walletNumber.value = '';
    isBalanceVisible.value = false;
    ProfileWalletCache.clear();
  }

  /// Clears profile-card wallet fields when the session ends.
  ///
  /// Separate from [WalletController] — this screen fetches summary on its own.
  void clearWalletDisplayOnLogout() {
    _cancelWalletBalanceHideTimer();
    _setWalletUnlinked();
    isLoadingWallet.value = false;
    isRefreshingWalletBalance.value = false;
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
          name: nameTextController.text.trim(),
          image: pickedImage.value,
        ),
      );

      await result.fold(
        (failure) async {
          failureMessage = failure.message;
        },
        (updatedUser) async {
          // Repository already updated [UserProfileCache] from edit_profile response.
          final merged = updatedUser.toUserModel(
            preserveUserId: userModel.value?.id ?? '',
          );
          if (merged != null) {
            _updateLocalUserState(merged);
          }
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

  /// Unformatted wallet account digits for clipboard (no display spacing).
  String get walletNumberForCopy {
    final raw = ProfileWalletCache.walletNumberRaw.trim();
    if (raw.isNotEmpty) return raw;
    return walletNumber.value.replaceAll(RegExp(r'\s+'), '');
  }

  /// Copies wallet number; iOS shows snackbar via [copyToClipboardWithFeedback].
  void copyWalletNumber() {
    final number = walletNumberForCopy;
    if (number.isEmpty) return;
    unawaited(
      copyToClipboardWithFeedback(
        text: number,
        message: AppStrings.walletNumberCopied.tr,
      ),
    );
  }

  void openMyRides() {
    _navigateAndResetWalletBalanceOnReturn(
      Get.toNamed(AppRoutes.myRides),
    );
  }

  void openPaymentMethods() {
    _navigateAndResetWalletBalanceOnReturn(
      Get.toNamed(AppRoutes.paymentMethods),
    );
  }

  void openWallet() {
    _navigateAndResetWalletBalanceOnReturn(Get.toNamed(AppRoutes.wallet));
  }

  void openContactUs() {
    _navigateAndResetWalletBalanceOnReturn(Get.toNamed(AppRoutes.contactUs));
  }

  void openFavoriteLocations() {
    _navigateAndResetWalletBalanceOnReturn(
      Get.toNamed(AppRoutes.favoriteLocations),
    );
  }

  void openPrivacyPolicy() {
    _navigateAndResetWalletBalanceOnReturn(
      WebViewScreen.open(
        title: AppStrings.privacyPolicy.tr,
        url: AppConfig.versionedApiUrl(URLS.common.privacy),
      ),
    );
  }

  void openTermsAndConditions() {
    _navigateAndResetWalletBalanceOnReturn(
      WebViewScreen.open(
        title: AppStrings.termsAndConditions.tr,
        url: AppConfig.versionedApiUrl(URLS.common.termsAndConditions),
      ),
    );
  }

  void openSafety() {
    _navigateAndResetWalletBalanceOnReturn(Get.toNamed(AppRoutes.safety));
  }

  void openNotifications() {
    _navigateAndResetWalletBalanceOnReturn(
      Get.toNamed(AppRoutes.notifications),
    );
  }

  void openSettings() {
    _navigateAndResetWalletBalanceOnReturn(Get.toNamed(AppRoutes.settings));
  }

  void logout() {
    AppDialogs.showConfirmationDialog(
      title: AppStrings.logout.tr,
      message: AppStrings.areYouSureYouWantToLogoutFromTheApp.tr,
      confirmText: AppStrings.logout.tr,
      onConfirm: () async {
        // Best-effort: revoke backend session before clearing local tokens.
        final logoutResult = await di.sl<AuthRepository>().logout();
        logoutResult.fold((_) {}, (_) {});
        // Clear wallet caches/controllers before wiping tokens/storage.
        WalletSession.teardownOnLogout();
        SessionExpiryService.teardownOnLogout();
        await di.sl<AuthRepository>().signOutFirebase();
        await StorageService().deleteAll();
        SessionAuthService.instance.clearInMemorySession();
        Get.offAllNamed(AppRoutes.login);
      },
    );
  }
}
