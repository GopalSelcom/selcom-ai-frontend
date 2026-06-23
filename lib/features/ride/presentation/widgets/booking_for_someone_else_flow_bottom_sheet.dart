import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/grouped_phone_number_formatter.dart';
import '../../../../shared/utils/phone_contact_import.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/phone_country_picker_chip.dart';

enum BookingMode { self, other }

enum BookingFlowStep { choice, details }

class BookingForSomeoneElseFlowBottomSheet extends StatefulWidget {
  const BookingForSomeoneElseFlowBottomSheet({super.key});

  /// Opens the multi-step booking sheet via [AppDialogs.showStandardBottomSheet].
  static Future<Map<String, dynamic>?> show() {
    return AppDialogs.showStandardBottomSheet<Map<String, dynamic>>(
      sheet: const BookingForSomeoneElseFlowBottomSheet(),
      barrierDismissible: true,
    );
  }

  @override
  State<BookingForSomeoneElseFlowBottomSheet> createState() =>
      _BookingForSomeoneElseFlowBottomSheetState();
}

class _BookingForSomeoneElseFlowBottomSheetState
    extends State<BookingForSomeoneElseFlowBottomSheet> {
  BookingFlowStep _currentStep = BookingFlowStep.choice;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String? _nameError;
  String? _phoneError;
  CountryData _selectedCountry = Countries.findByIsoCode('TZ');
  int _phoneFieldKey = 0;

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  Future<void> _pickContact() async {
    try {
      if (GetPlatform.isAndroid) {
        final status = await Permission.contacts.status;
        if (status.isPermanentlyDenied) {
          AppDialogs.showPermissionDialog(
            title: AppStrings.contactsPermission.tr,
            message: AppStrings.contactsAccessNeeded.tr,
            onOpenSettings: () => openAppSettings(),
            icon: Icons.contacts_outlined,
            secondaryIcon: Icons.contacts,
          );
          return;
        } else if (!status.isGranted) {
          final requestStatus = await Permission.contacts.request();
          if (!requestStatus.isGranted) {
            return;
          }
        }
      }

      final contact = await _contactPicker.selectContact();
      if (contact != null) {
        final name = contact.fullName ?? '';
        final numbers = contact.phoneNumbers ?? [];
        if (numbers.isNotEmpty) {
          final parsed = PhoneContactImport.parse(numbers.first);

          setState(() {
            if (name.isNotEmpty) {
              _name.text = name;
            }
            // Only auto-select when contact number has + / 00 country code.
            _selectedCountry = parsed.country ?? Countries.findByIsoCode('TZ');
            _phone.text = parsed.formattedNational;
            if (parsed.country != null) {
              _phoneFieldKey++;
            }
            _nameError = null;
            _phoneError = null;
          });
        } else {
          AppDialogs.showErrorDialog(
            message: 'No phone number found for this contact',
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _name.addListener(_onFieldsChanged);
    _phone.addListener(_onFieldsChanged);
  }

  void _onCountrySelected(CountryData country) {
    if (_selectedCountry.code == country.code) return;
    setState(() {
      final existingDigits = _phone.text.replaceAll(RegExp(r'\D'), '');
      _selectedCountry = country;
      _phone.text = existingDigits.isEmpty
          ? ''
          : GroupedPhoneNumberFormatter.formatDigits(
              existingDigits,
              country.format,
            );
      _phoneFieldKey++;
      _phoneError = null;
    });
  }

  void _onFieldsChanged() {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });
  }

  bool get _canConfirm {
    return _name.text.trim().isNotEmpty &&
        PhoneNationalRules.isCompleteValidNational(
          _selectedCountry.code,
          _phone.text.replaceAll(RegExp(r'\D'), ''),
        );
  }

  @override
  void dispose() {
    _name.removeListener(_onFieldsChanged);
    _phone.removeListener(_onFieldsChanged);
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? get _sheetTitle {
    switch (_currentStep) {
      case BookingFlowStep.choice:
        return AppStrings.bookingForSomeoneElsePrompt.tr;
      case BookingFlowStep.details:
        return AppStrings.passengerDetailsTitle.tr;
    }
  }

  String? get _sheetSubtitle {
    switch (_currentStep) {
      case BookingFlowStep.choice:
        return AppStrings.bookingForSomeoneElseSubtitle.tr;
      case BookingFlowStep.details:
        return AppStrings.notificationPhoneSubtitle.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStandardBottomSheet(
      title: _sheetTitle,
      subtitle: _sheetSubtitle,
      headerTextAlign: TextAlign.start,
      maxHeightFactor: 0.92,
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: _currentStep == BookingFlowStep.choice
            ? _buildChoiceStep()
            : _buildDetailsStep(),
      ),
      footer: _currentStep == BookingFlowStep.details && _canConfirm
          ? AppPrimaryButton(
              label: AppStrings.confirm.tr,
              iconAsset: AppAssets.locationIcArrowRight,
              alignIconToTrailingEnd: true,
              onPressed: _onConfirmPressed,
            )
          : null,
    );
  }

  Widget _buildChoiceStep() {
    return Column(
      key: const ValueKey(BookingFlowStep.choice),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bookingChoiceRow(
          icon: Iconsax.user,
          title: AppStrings.bookingRideOptionForMe.tr,
          onTap: () {
            Navigator.of(context).pop({'mode': BookingMode.self});
          },
        ),
        SizedBox(height: 12.h),
        _bookingChoiceRow(
          icon: Iconsax.user_add,
          title: AppStrings.bookingRideOptionForSomeoneElse.tr,
          onTap: () {
            setState(() {
              _currentStep = BookingFlowStep.details;
            });
          },
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      key: const ValueKey(BookingFlowStep.details),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _name,
          label: AppStrings.passengerNameLabel.tr,
          hintText: AppStrings.enterPassengerFullName.tr,
          keyboardType: TextInputType.name,
          errorText: _nameError,
          onChanged: (_) {},
          suffixIcon: IconButton(
            icon: Icon(Iconsax.user_add, color: AppColors.primary, size: 22.sp),
            onPressed: _pickContact,
          ),
        ),
        SizedBox(height: 16.h),
        AppTextField(
          key: ValueKey(
            'passenger-phone-${_selectedCountry.code}-$_phoneFieldKey',
          ),
          controller: _phone,
          label: AppStrings.passengerPhoneLabel.tr,
          hintText: PhoneNationalRules.hintForIso(_selectedCountry.code),
          keyboardType: TextInputType.phone,
          inputFormatters: PhoneNationalRules.inputFormattersForIso(
            _selectedCountry.code,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.only(left: 12.w, right: 2.w),
            child: PhoneCountryPickerChip(
              inline: true,
              selected: _selectedCountry,
              onChanged: _onCountrySelected,
            ),
          ),
          errorText: _phoneError,
          onChanged: (_) {},
        ),
      ],
    );
  }

  void _onConfirmPressed() {
    final trimmedName = _name.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _nameError = AppStrings.nameIsRequired.tr;
      });
      return;
    }

    final e164 = PhoneNationalRules.e164DigitsOrNull(
      _selectedCountry.code,
      _phone.text,
    );
    if (e164 == null) {
      setState(() {
        _phoneError = _phone.text.trim().isEmpty
            ? AppStrings.notificationPhoneRequired.tr
            : AppStrings.pleaseEnterAValidPhoneNumber.tr;
      });
      return;
    }

    Navigator.of(
      context,
    ).pop({'mode': BookingMode.other, 'name': trimmedName, 'phone': e164});
  }

  Widget _bookingChoiceRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textBody,
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
