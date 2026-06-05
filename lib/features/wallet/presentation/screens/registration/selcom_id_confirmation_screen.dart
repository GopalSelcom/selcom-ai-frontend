import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:m7_livelyness_detection/index.dart';

import '../../../../../core/localization/languages/languages.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_profile_header.dart';
import '../../controllers/registration_controller.dart';
import '../../utils/media_viewer.dart';
import '../../widgets/common_button.dart';
import 'wallet_waiting_screen.dart';

class SelcomIdConfirmationScreen extends StatefulWidget {
  final String profilePicture;
  final String firstName;
  final String middleName;
  final String lastName;
  final String gender;
  final DateTime dateOfBirth;
  final String residentRegion;
  final String? residentAddress;
  final String passportNumber;
  final String nationality;
  final String placeOfBirth;
  final String expirationDate;

  const SelcomIdConfirmationScreen({
    super.key,
    required this.profilePicture,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.residentRegion,
    required this.passportNumber,
    required this.nationality,
    required this.placeOfBirth,
    required this.expirationDate,
    this.residentAddress,
  });

  @override
  State<SelcomIdConfirmationScreen> createState() =>
      _DocumentConfirmationScreenState();
}

class _DocumentConfirmationScreenState
    extends State<SelcomIdConfirmationScreen> {
  final RegistrationController _loginController = RegistrationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // appBar: CustomAppBar(
      //   title: Languages.of(context).documentConfirmation,
      //   // leadingIcon: CommonImages.IC_BACK,
      //   // onTapLeading: appNavigator.pop,
      //   showBack: true,
      // ),
      body: Column(
        children: <Widget>[
          AppProfileHeader(
            title:"Document Confirmation"
          ),
          Visibility(
            visible: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                color: Color(0xffFEE5EC),
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.all(20.0.sp),
              padding: EdgeInsets.only(
                left: 15.0.sp,
                right: 15.0.sp,
                top: 10.0.sp,
                bottom: 10.0.sp,
              ),
              child: Text(
                "You are already registered with a Selcom ID App. Kindly confirm the NIDA details.",
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle.copyWith(
                  // lineHeight: 1.5,
                  fontSize: 14.0.sp,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          Container(
            width: 150.0.sp,
            height: 160.0.sp,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: MediaViewer(
              path: widget.profilePicture,
              fit: BoxFit.cover,
              height: 160.0.sp,
              width: 150.0.sp,
              // containerHeight: 160.0.sp,
              // containerWidth: 150.0.sp,
            ),
          ),
          SizedBox(height: 30.0.sp),
          Expanded(
            child: ListView(
              physics: BouncingScrollPhysics(),
              children: [
                _LabelValue(
                  label: "First Name",
                  value: widget.firstName,
                ),
                _LabelValue(
                  label: "Middle Name",
                  value: widget.middleName,
                ),
                _LabelValue(
                  label: "Last Name",
                  value: widget.lastName,
                ),
                _LabelValue(
                  label: "Passport Number",
                  value: widget.passportNumber,
                ),
                _LabelValue(
                  label: "Nationality",
                  value: widget.nationality,
                ),
                _LabelValue(
                  label: "Place of birth",
                  value: widget.placeOfBirth,
                ),
                _LabelValue(
                  label: "Gender",
                  value: widget.gender,
                ),
                _LabelValue(
                  label: "Date Of Birth",
                  value: DateFormat("yyyy-MM-dd").format(widget.dateOfBirth),
                ),
                _LabelValue(
                  label:"City",
                  value: widget.residentRegion,
                ),
                if (widget.residentAddress?.isNotEmpty ?? false)
                  _LabelValue(
                    label: "Address",
                    value: widget.residentAddress ?? "",
                  ),
                if (widget.expirationDate.isNotEmpty)
                  _LabelValue(
                    label: "Expiration date",
                    value: DateFormat(
                      "yyyy-MM-dd",
                    ).format(DateTime.parse(widget.expirationDate)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: Platform.isAndroid ? 0 : 10,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: CommonButton(
                    label: Languages.of(context).cancel,
                    onTap: () async {
                      Get.back();
                    },
                    enabledColor: AppColors.walletColor,
                    isEnabled: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CommonButton(
                    label: Languages.of(context).confirm,
                    onTap: () async {
                      _loginController.isDataGotFromSelcomId = true;
                      Get.to(()=>const WalletWaitingScreen());
                    },
                    enabledColor: AppColors.walletColor,
                    isEnabled: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return SizedBox();
    }

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "$label:",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.lightGreyColor),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            width: Get.width,
            decoration: BoxDecoration(
              color: AppColors.textGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
