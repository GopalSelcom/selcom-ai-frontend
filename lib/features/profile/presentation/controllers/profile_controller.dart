import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../ride/presentation/screens/my_rides_screen.dart';
import '../../domain/usecases/profile_usecase.dart';
import '../../../../core/data/models/user_model.dart';

class ProfileController extends GetxController {
  final ProfileUseCase profileUseCase;

  ProfileController({required this.profileUseCase});

  // Observables for state
  final RxBool isEditing = false.obs;
  final RxBool isLoading = false.obs;
  
  // User Data
  final Rxn<UserModel> userModel = Rxn<UserModel>();
  final RxString walletBalance = '43,829'.obs;
  final RxString walletNumber = '16010 00000 034'.obs;

  // Controllers for text fields
  late TextEditingController nameTextController;
  late TextEditingController phoneTextController;

  // Focus nodes
  late FocusNode nameFocusNode;
  late FocusNode phoneFocusNode;

  @override
  void onInit() {
    super.onInit();
    nameTextController = TextEditingController(text: 'Chirag Panchal');
    phoneTextController = TextEditingController(text: '+255 711 410 410');
    
    nameFocusNode = FocusNode();
    phoneFocusNode = FocusNode();

    // TODO: Skip API call for now
    // fetchProfile(); 
    // fetchWalletBalance(); 
    
    // Initialize with static data for now
    userModel.value = const UserModel(
      id: 'static_id',
      uniqueId: 'Chirag Panchal',
      mobileNumber: 711410410,
      accountNumber: 1601000000034,
    );
  }

  @override
  void onClose() {
    nameTextController.dispose();
    phoneTextController.dispose();
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    super.onClose();
  }

  Future<void> fetchProfile() async {
    // TODO: Skip API call for now
    /*
    isLoading.value = true;
    final result = await profileUseCase.getProfile();
    result.fold(
      (failure) => Get.snackbar('Error', failure.message),
      (user) {
        userModel.value = user;
        nameTextController.text = user.uniqueId ?? ''; 
        phoneTextController.text = user.mobileNumber?.toString() ?? '';
        walletNumber.value = user.accountNumber?.toString() ?? '';
      },
    );
    isLoading.value = false;
    */
  }

  Future<void> fetchWalletBalance() async {
    // TODO: Skip API call for now
    /*
    final result = await profileUseCase.getWalletBalance();
    result.fold(
      (failure) => null, // Silently fail for now
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
    nameFocusNode.unfocus();
    phoneFocusNode.unfocus();
    
    // Simulate static save
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    
    userModel.value = UserModel(
      id: 'static_id',
      uniqueId: nameTextController.text,
      mobileNumber: int.tryParse(phoneTextController.text.replaceAll('+', '').replaceAll(' ', '')),
      accountNumber: userModel.value?.accountNumber,
    );
    
    isEditing.value = false;
    isLoading.value = false;
    Get.snackbar('Success', 'Profile updated locally');

    // TODO: Skip API call for now
    /*
    final result = await profileUseCase.updateProfile({
      'name': nameTextController.text,
      'mobile_number': phoneTextController.text,
    });

    result.fold(
      (failure) => Get.snackbar('Error', failure.message),
      (success) {
        if (success) {
          isEditing.value = false;
          fetchProfile();
        }
      },
    );
    isLoading.value = false;
    */
  }
  
  void cancelEdit() {
    nameFocusNode.unfocus();
    phoneFocusNode.unfocus();
    if (userModel.value != null) {
      nameTextController.text = userModel.value!.uniqueId ?? '';
      phoneTextController.text = '+255 ${userModel.value!.mobileNumber}';
    }
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

  void openContactUs() {
    Get.toNamed(AppRoutes.contactUs);
  }
}
