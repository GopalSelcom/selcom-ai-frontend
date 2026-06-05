import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/localization/languages/languages.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/registration_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/common_button.dart';
import '../wallet_main_screen.dart';

class VerificationSuccessScreen extends StatefulWidget {
  const VerificationSuccessScreen({super.key});

  @override
  State<VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen> {
  WalletController walletController = WalletController();
  RegistrationController registrationController = RegistrationController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future(() => false);
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 15.0.sp),
            child: Column(
              children: [
                SizedBox(height: 200.0.sp),
                Image.asset(Images.successPayment, height: Get.height * 0.15),
                SizedBox(height: 50.0.sp),
                Text(
                  "Registration complete",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    // fontFamily: FontName.NunitoSansRegular,
                    fontSize: 18.0.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.0.sp),
                Text(
                  "Your duka.direct Prepaid Mastercard wallet \nis now ready for use.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                    // fontFamily: FontName.NunitoSansRegular,
                    fontSize: 15.0.sp,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: CommonButton(
                    label: Languages.of(context).continueLabel,
                    onTap: () async {
                      if (walletController.isWalletCreated &&
                          (walletController
                                  .walletData
                                  .value
                                  ?.response
                                  ?.clientId !=
                              null)) {
                        Get.offAll(() => WalletMainScreen());
                      }
                    },
                    enabledColor: AppColors.primary,
                    isEnabled: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
