import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  // Observables for state
  final RxBool isEditing = false.obs;
  
  // User Data
  final RxString userName = 'Chirag Panchal'.obs;
  final RxString phoneNumber = '+255 711 410 410'.obs;
  
  // Wallet Data
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
    // Initialize editing controllers with current data
    nameTextController = TextEditingController(text: userName.value);
    phoneTextController = TextEditingController(text: phoneNumber.value);
    
    nameFocusNode = FocusNode();
    phoneFocusNode = FocusNode();
  }

  @override
  void onClose() {
    nameTextController.dispose();
    phoneTextController.dispose();
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    super.onClose();
  }

  void toggleEditMode() {
    if (!isEditing.value) {
      nameTextController.text = userName.value;
      phoneTextController.text = phoneNumber.value;
      isEditing.value = true;
      
      // Delay focus slightly to allow the slide down animation to finish rendering cleanly
      Future.delayed(const Duration(milliseconds: 350), () {
        if (isEditing.value) {
          nameFocusNode.requestFocus();
        }
      });
    } else {
      isEditing.value = false;
    }
  }

  void saveProfile() {
    // Hide keyboard
    nameFocusNode.unfocus();
    phoneFocusNode.unfocus();
    
    // Save updated values
    userName.value = nameTextController.text;
    phoneNumber.value = phoneTextController.text;
    isEditing.value = false;
  }
  
  void cancelEdit() {
    nameFocusNode.unfocus();
    phoneFocusNode.unfocus();
    isEditing.value = false;
  }

  void handleBack() {
    if (isEditing.value) {
      cancelEdit();
    } else {
      Get.back();
    }
  }
}
