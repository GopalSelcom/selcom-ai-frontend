import 'package:duka_direct_4_flutter/core/extensions/formatting_extensions.dart';
import 'package:duka_direct_4_flutter/core/services/responsive/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/constans.dart';
import '../../../../../core/resources/images.dart';
import '../../../../../core/services/localization/language/languages.dart';
import '../../../../../core/services/localization/localization.dart';
import '../../../../../core/services/router/app_navigator.dart';
import '../../../../../core/services/theme/theme.dart';
import '../../../../../core/widgets/common_button.dart';
import 'package:duka_direct_4_flutter/core/widgets/media_viewer.dart';
import '../../../controller/wallet_controller.dart';

class WalletRefundActivationPopup extends StatefulWidget {
  final bool isFromLipa;

  const WalletRefundActivationPopup({super.key, this.isFromLipa = false});

  @override
  State<WalletRefundActivationPopup> createState() =>
      _WalletActivationPopupState();
}

class _WalletActivationPopupState extends State<WalletRefundActivationPopup> {
  WalletController walletController = WalletController();

  Future<void> setLanguage() async {
    walletController.lang.value =
        Localization.instance.currentLanguage?.languageCode ?? "en";
  }

  @override
  void initState() {
    walletController.isRefundWalletDialogVisible = true;
    super.initState();
    setLanguage();
  }

  @override
  void dispose() {
    walletController.isRefundWalletDialogVisible = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0.sp),
        child: Column(
          children: [
            SizedBox(height: 7.0.sp),
            Stack(
              alignment: Alignment.center,
              children: [
                MediaViewer(path: Images.walletIcon,
                  // Images.walletIconYellow,
                  // color: Color(0xffEC174E),
                  // color: Color.lerp(Color(0xffEC174E), Colors.black, 0.12)!,
                  height: 110.0.sp,
                ),
                Positioned(
                  bottom: 9.0.sp,
                  child: Icon(
                    Icons.warning_rounded,
                    size: 65.0.sp,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0.sp),
            RichText(
              textAlign: TextAlign.center,
              text:
                  Localization.instance.currentLanguage?.languageCode ==
                      Localization.instance.english
                  ? TextSpan(
                      text: "You have ",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGrey,
                        // fontFamily: FontName.NunitoSansRegular,
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Active Refunds ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Color(0xff5CB75E),
                                // fontFamily: FontName.NunitoSansExtraBold,
                                fontSize: 16.0.sp,
                                // fontWeight: FontWeight.w600,
                              ),
                        ),
                        TextSpan(
                          text: widget.isFromLipa
                              ? "awaiting credit into your duka.direct wallet. Complete your registration to access these funds, use Lipa, and many other benefits from duka.direct Mastercard."
                              : "awaiting credit into your duka.direct wallet. Complete your registration to access these funds and many other benefits from duka.direct Mastercard.",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textGrey,
                                // fontFamily: FontName.NunitoSansRegular,
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    )
                  : TextSpan(
                      text: widget.isFromLipa
                          ? "Una Marejesho Yenye Nguvu yanayosubiri kuingizwa kwenye pochi yako ya duka.direct. Kamilisha usajili wako ili kufikia fedha hizi, tumia Lipa, na manufaa mengine mengi kutoka kwa duka.direct Mastercard."
                          : "Una Marejesho Yenye Nguvu yanayosubiri kuingizwa kwenye pochi yako ya duka.direct. Kamilisha usajili wako ili kufikia fedha hizi na manufaa mengine mengi kutoka kwa duka.direct Mastercard.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textGrey,
                        // fontFamily: FontName.NunitoSansRegular,
                        fontSize: 16.0.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            SizedBox(height: 13.0.sp),
            Text(
              "${CommonValues.currencyCode} ${walletController.walletRefundAmountResponse.value.totalRefundAmount?.toShortScaleFormat() ?? 0}",
              style: AppTextStyles.screenTitle.copyWith(
                color: AppColors.grey535353,
                // fontName: FontName.NunitoSansBold,
                fontSize: 18.0.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 13.0.sp),

            CommonButton(
              bottomSpace: 13.sp,
              enabledColor: context.textColors.walletColor,
              label: Languages.of(context).activateWallet,
              isButtonAnimationEnable: false,
              // labelTextStyle: TextStyle(
              //   fontFamily: Fonts.plusJakartaSansBold,
              //   color: context.textColors.white,
              //   fontSize: 15.sp,
              // ),
              onTap: () {
                appNavigator.pop(result: true);
              },
              isEnabled: true,
            ),

            CommonButton(
              label: Languages.of(context).remindMeLater,
              bottomSpace: 16.sp,
              enabledColor: context.textColors.white,
              borderColor: context.textColors.textGrayAskleois,
              iconColor: Colors.transparent,
              labelTextStyle: TextStyle(
                fontFamily: Fonts.plusJakartaSansBold,
                color: context.textColors.textGrayAskleois,
                fontSize: 15.sp,
              ),

              isButtonAnimationEnable: false,
              onTap: () {
                appNavigator.pop();
              },
              isEnabled: true,
            ),
          ],
        ),
      ),
    );
  }
}
