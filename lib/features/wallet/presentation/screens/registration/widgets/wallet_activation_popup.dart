import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../controllers/wallet_controller.dart';
import '../../../widgets/common_button.dart';



class WalletActivationPopup extends StatefulWidget {
  WalletActivationPopup({super.key, this.isFromLipa = false});

  final bool? isFromLipa;

  @override
  State<WalletActivationPopup> createState() => _WalletActivationPopupState();
}

class _WalletActivationPopupState extends State<WalletActivationPopup> {
  WalletController? get walletController =>
      Get.isRegistered<WalletController>()
          ? Get.find<WalletController>()
          : null;

  Future<void> setLanguage() async {
    walletController?.lang.value =
         "en";
  }

  @override
  void initState() {
    walletController.isNidaRegistrationDialogVisible = true;
    super.initState();
    setLanguage();
  }

  @override
  void dispose() {
    walletController.isNidaRegistrationDialogVisible = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.0.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(Images.walletActivationPopupIcon, height: 100.0.sp),
            SizedBox(height: 13.0.sp),
            Obx(
              () => RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Simplify your shopping on " ,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                    // fontFamily: FontName.NunitoSansRegular,
                    fontSize: 18.0.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'duka.direct ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.loaderColor,
                        // fontFamily: FontName.NunitoSansRegular,
                        fontSize: 18.0.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: walletController.lang.value == "en"
                          ? 'and beyond!'
                          : "na kwingineko!",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGrey,
                        // fontFamily: FontName.NunitoSansRegular,
                        fontSize: 18.0.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 13.0.sp),
            Obx(
              () => RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: walletController.lang.value == "en"
                      ? 'Register for a duka.direct Prepaid Mastercard with your '
                      : "Jisajili kwa duka.direct Prepaid Mastercard ukitumia ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                    // fontFamily: FontName.NunitoSansRegular,
                    fontSize: 15.0.sp,
                  ),
                  children: (widget.isFromLipa ?? false)
                      ? <TextSpan>[
                          TextSpan(
                            text: walletController.lang.value == "en"
                                ? 'NIDA ID or Passport '
                                : "NIDA ID au Pasipoti ",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textGrey,
                                  // fontFamily: FontName.NunitoSansRegular,
                                  fontSize: 15.0.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          TextSpan(
                            text: walletController.lang.value == "en"
                                ? 'today'
                                : "leo",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textGrey,
                                  // fontFamily: FontName.NunitoSansRegular,
                                  fontSize: 15.0.sp,
                                ),
                          ),
                          TextSpan(
                            text: walletController.lang.value == "en"
                                ? ' to use Lipa!'
                                : " Tumia Lipa!",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textGrey,
                                  // fontFamily: FontName.NunitoSansRegular,
                                  fontSize: 15.0.sp,
                                ),
                          ),
                        ]
                      : <TextSpan>[
                          TextSpan(
                            text: walletController.lang.value == "en"
                                ? 'NIDA ID or Passport '
                                : "NIDA ID au Pasipoti ",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textGrey,
                                  // fontFamily: FontName.NunitoSansRegular,
                                  fontSize: 15.0.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          TextSpan(
                            text: walletController.lang.value == "en"
                                ? 'today!'
                                : "leo!",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textGrey,
                                  // fontFamily: FontName.NunitoSansRegular,
                                  fontSize: 15.0.sp,
                                ),
                          ),
                        ],
                ),
              ),
            ),
            SizedBox(height: 13.0.sp),

            CommonButton(
              bottomSpace: 13.sp,
              enabledColor:AppColors.primary,
              label: "Activate Wallet",
              isButtonAnimationEnable: false,
              // labelTextStyle: TextStyle(
              //   fontFamily: Fonts.plusJakartaSansBold,
              //   color: context.textColors.white,
              //   fontSize: 15.sp,
              // ),
              onTap: () {
                Get.back(result: true);
              },
              isEnabled: true,
            ),

            CommonButton(
              label: "Remind Me Later",
              bottomSpace: 16.sp,
              enabledColor: AppColors.white,
              borderColor: AppColors.textGrayAskleois,
              iconColor: Colors.transparent,
              labelTextStyle: TextStyle(
                // fontFamily: Fonts.plusJakartaSansBold,
                color: AppColors.textGrayAskleois,
                fontSize: 15.sp,
              ),

              isButtonAnimationEnable: false,
              onTap: () {
                Get.back();
              },
              isEnabled: true,
            ),
          ],
        ),
      ),
    );
  }
}
