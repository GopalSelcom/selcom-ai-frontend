
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../controllers/wallet_controller.dart';
import '../../../utils/media_viewer.dart';
import '../../../widgets/common_button.dart';



class WalletRefundActivationPopup extends StatefulWidget {
  final bool isFromLipa;

  const WalletRefundActivationPopup({super.key, this.isFromLipa = false});

  @override
  State<WalletRefundActivationPopup> createState() =>
      _WalletActivationPopupState();
}

class _WalletActivationPopupState extends State<WalletRefundActivationPopup> {
  WalletController? get walletController =>
      Get.isRegistered<WalletController>()
          ? Get.find<WalletController>()
          : null;

  Future<void> setLanguage() async {
    walletController?.lang.value = "en";
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
                MediaViewer(path: AppAssets.icWallet,
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
                  true
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
              "+255 ${walletController.walletRefundAmountResponse.value.totalRefundAmount?.toShortScaleFormat() ?? 0}",
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
              enabledColor:AppColors.walletColor,
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
