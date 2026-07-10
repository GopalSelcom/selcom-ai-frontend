import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_animated_reveal.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/add_card_controller.dart';
import 'country_select_screen.dart';
import 'state_select_screen.dart';
import '../../../../shared/widgets/phone_country_picker_chip.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../data/models/country_response.dart';
import '../../data/models/state_model.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  late final AddCardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddCardController());
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS ? 0 : 8.h)
        : 24.h;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.addNewCard.tr, onBack: Get.back),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION 1: Card Information
                          Text(
                            "Card Information",
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 16.h,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeading,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.borderDefault, width: 1.w),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Obx(
                                      () => Expanded(
                                        child: AppTextField(
                                          label: "First Name",
                                          hintText: AppStrings.eGJohnDoe.tr,
                                          controller: controller.cardHolderController,
                                          focusNode: controller.fullNameFocus,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) =>
                                              controller.lastNameFocus.requestFocus(),
                                          onChanged: (_) => controller.onFieldChanged(),
                                          errorText: controller.fullNameError.value,
                                          fontSize: 15.h,
                                          fontWeight: FontWeight.w500,
                                          textFieldBackgroundColor:
                                              AppColors.pageBackground,
                                          textColor: AppColors.textHeading,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Obx(
                                      () => Expanded(
                                        child: AppTextField(
                                          label: "Last Name",
                                          hintText: AppStrings.eGJohnDoe.tr,
                                          controller: controller.lastNameController,
                                          focusNode: controller.lastNameFocus,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) =>
                                              controller.focusCardNumber(),
                                          onChanged: (_) => controller.onFieldChanged(),
                                          errorText: controller.lastNameError.value,
                                          fontSize: 15.h,
                                          fontWeight: FontWeight.w500,
                                          textFieldBackgroundColor:
                                              AppColors.pageBackground,
                                          textColor: AppColors.textHeading,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Obx(
                                  () => AppTextField(
                                    label: AppStrings.cardNumber.tr,
                                    hintText: AppStrings.value0000000000000000.tr,
                                    controller: controller.cardNumberController,
                                    focusNode: controller.cardNumberFocus,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => controller.focusExpiry(),
                                    onChanged: (_) => controller.onFieldChanged(),
                                    errorText: controller.cardNumberError.value,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(16),
                                      _CardNumberFormatter(),
                                    ],
                                    fontSize: 15.h,
                                    fontWeight: FontWeight.w500,
                                    textFieldBackgroundColor:
                                        AppColors.pageBackground,
                                    textColor: AppColors.textHeading,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Obx(
                                        () => AppTextField(
                                          label: AppStrings.expiry.tr,
                                          hintText: AppStrings.mmYy.tr,
                                          controller: controller.expiryController,
                                          focusNode: controller.expiryFocus,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) => controller.focusCvv(),
                                          onChanged: (_) =>
                                              controller.onFieldChanged(),
                                          errorText: controller.expiryError.value,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                            _CardExpiryFormatter(),
                                          ],
                                          fontSize: 15.h,
                                          fontWeight: FontWeight.w500,
                                          textFieldBackgroundColor:
                                              AppColors.pageBackground,
                                          textColor: AppColors.textHeading,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Obx(
                                        () => AppTextField(
                                          label: AppStrings.cvv.tr,
                                          hintText: AppStrings.eG123.tr,
                                          controller: controller.cvvController,
                                          focusNode: controller.cvvFocus,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) => controller.phoneFocus.requestFocus(),
                                          onChanged: (_) =>
                                              controller.onFieldChanged(),
                                          errorText: controller.cvvError.value,
                                          isPassword: controller.isCvvHidden.value,
                                          suffixIcon: IconButton(
                                            onPressed: controller.toggleCvvVisibility,
                                            icon: Icon(
                                              controller.isCvvHidden.value
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppColors.textBody.withValues(
                                                alpha: 0.7,
                                              ),
                                              size: 20.w,
                                            ),
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(3),
                                          ],
                                          fontSize: 15.h,
                                          fontWeight: FontWeight.w500,
                                          textFieldBackgroundColor:
                                              AppColors.pageBackground,
                                          textColor: AppColors.textHeading,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // SECTION 2: Billing & Address Details
                          Text(
                            "Billing Details",
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 16.h,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeading,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.borderDefault, width: 1.w),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 // Country Picker Dropdown field
                                 GestureDetector(
                                   onTap: () async {
                                     final result = await Get.to(() => CountrySelectScreen(
                                           countries: controller.countriesList,
                                           selectedCountry: controller.selectedCountry.value,
                                         ));
                                     if (result != null && result is CountriesResponse) {
                                       controller.selectCountry(result);
                                     }
                                   },
                                   child: AbsorbPointer(
                                     child: Obx(
                                       () => AppTextField(
                                         label: "Country",
                                         hintText: "Select Country",
                                         controller: TextEditingController(
                                           text: controller.selectedCountry.value != null
                                               ? (controller.selectedCountry.value!.name ?? '').trim()
                                               : '',
                                         ),
                                         errorText: controller.countryError.value,
                                         readOnly: true,
                                         suffixIcon: Icon(
                                           Icons.arrow_drop_down,
                                           color: AppColors.textMutedStrong,
                                           size: 26.h,
                                         ),
                                         fontSize: 15.h,
                                         fontWeight: FontWeight.w500,
                                         textFieldBackgroundColor: AppColors.pageBackground,
                                         textColor: AppColors.textHeading,
                                       ),
                                     ),
                                   ),
                                 ),
 
                                 // State Picker Dropdown field (Visible once country is selected)
                                 Obx(() {
                                   if (controller.selectedCountry.value == null) {
                                     return const SizedBox.shrink();
                                   }
                                   return Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       SizedBox(height: 12.h),
                                       GestureDetector(
                                         onTap: () async {
                                           final result = await Get.to(() => StateSelectScreen(
                                                 states: controller.statesList,
                                                 selectedState: controller.selectedStateResponse.value,
                                               ));
                                           if (result != null && result is StateResponse) {
                                             controller.selectState(result);
                                           }
                                         },
                                         child: AbsorbPointer(
                                           child: Obx(
                                             () => AppTextField(
                                               label: "State",
                                               hintText: "Select State",
                                               controller: TextEditingController(
                                                 text: controller.selectedState.value ?? '',
                                               ),
                                               errorText: controller.stateError.value,
                                               readOnly: true,
                                               suffixIcon: Icon(
                                                 Icons.arrow_drop_down,
                                                 color: AppColors.textMutedStrong,
                                                 size: 26.h,
                                               ),
                                               fontSize: 15.h,
                                               fontWeight: FontWeight.w500,
                                               textFieldBackgroundColor: AppColors.pageBackground,
                                               textColor: AppColors.textHeading,
                                             ),
                                           ),
                                         ),
                                       ),
                                     ],
                                   );
                                 }),
                                SizedBox(height: 12.h),

                                // Phone number field with country prefix picker
                                Obx(() {
                                  final country = controller.selectedPhoneCountry.value;
                                  final iso = country.code;
                                  final resetV = controller.phoneFieldResetVersion.value;
                                  return AppTextField(
                                    key: ValueKey('add-card-phone-$iso-$resetV'),
                                    label: "Phone Number",
                                    hintText: PhoneNationalRules.hintForIso(iso),
                                    controller: controller.phoneController,
                                    focusNode: controller.phoneFocus,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: PhoneNationalRules.inputFormattersForIso(iso),
                                    maxLength: PhoneNationalRules.maxDisplayCharactersForIso(iso),
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => controller.emailFocus.requestFocus(),
                                    onChanged: (_) => controller.onFieldChanged(),
                                    errorText: controller.phoneError.value,
                                    fontSize: 15.h,
                                    fontWeight: FontWeight.w500,
                                    prefixIcon: Container(
                                      padding: EdgeInsets.only(left: 12.w, right: 2.w),
                                      child: PhoneCountryPickerChip(
                                        inline: true,
                                        selected: country,
                                        onChanged: controller.selectPhoneCountry,
                                      ),
                                    ),
                                    textFieldBackgroundColor: AppColors.pageBackground,
                                    textColor: AppColors.textHeading,
                                  );
                                }),
                                SizedBox(height: 12.h),

                                // Email field
                                Obx(
                                  () => AppTextField(
                                    label: "Email",
                                    hintText: "e.g. user@example.com",
                                    controller: controller.emailController,
                                    focusNode: controller.emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => controller.addressFocus.requestFocus(),
                                    onChanged: (_) => controller.onFieldChanged(),
                                    errorText: controller.emailError.value,
                                    fontSize: 15.h,
                                    fontWeight: FontWeight.w500,
                                    textFieldBackgroundColor: AppColors.pageBackground,
                                    textColor: AppColors.textHeading,
                                  ),
                                ),
                                SizedBox(height: 12.h),

                                // Address field
                                Obx(
                                  () => AppTextField(
                                    label: "Address",
                                    hintText: "Street name / House number",
                                    controller: controller.addressController,
                                    focusNode: controller.addressFocus,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => controller.cityFocus.requestFocus(),
                                    onChanged: (_) => controller.onFieldChanged(),
                                    errorText: controller.addressError.value,
                                    fontSize: 15.h,
                                    fontWeight: FontWeight.w500,
                                    textFieldBackgroundColor: AppColors.pageBackground,
                                    textColor: AppColors.textHeading,
                                  ),
                                ),
                                SizedBox(height: 12.h),

                                // City field
                                Obx(
                                  () => AppTextField(
                                    label: "City",
                                    hintText: "e.g. Dar es Salaam",
                                    controller: controller.cityController,
                                    focusNode: controller.cityFocus,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => controller.submitCard(),
                                    onChanged: (_) => controller.onFieldChanged(),
                                    errorText: controller.cityError.value,
                                    fontSize: 15.h,
                                    fontWeight: FontWeight.w500,
                                    textFieldBackgroundColor: AppColors.pageBackground,
                                    textColor: AppColors.textHeading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),

                  SafeArea(
                    top: false,
                    bottom: true,
                    child: Obx(() {
                      final shouldShow =
                          controller.isSubmitting.value ||
                          controller.canSubmitForm.value;
                      return AppAnimatedReveal(
                        show: shouldShow,
                        visibleKey: const ValueKey('add-card-button-visible'),
                        hiddenKey: const ValueKey('add-card-button-hidden'),
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: computedBottomPadding,
                          ),
                          child: AppPrimaryButton(
                            label: AppStrings.addCard.tr,
                            iconAsset: AppAssets.locationIcArrowRight,
                            isLoading: controller.isSubmitting.value,
                            onPressed: controller.isSubmitting.value
                                ? null
                                : controller.submitCard,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 < digits.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    final month = digits.substring(0, 2);
    final year = digits.substring(2);
    final formatted = '$month/$year';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
