import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/local_bank_instructions_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../wallet/presentation/utils/wallet_format_utils.dart';

class LocalBankInstructionsBottomSheet extends StatelessWidget {
  const LocalBankInstructionsBottomSheet({super.key});

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      sheet: const LocalBankInstructionsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructionsData =
        sl<LocalBankInstructionsService>().instructionsData;
    if (instructionsData == null) {
      return AppStandardBottomSheet(
        title: AppStrings.addMoneyToWallet.tr,
        headerTextAlign: TextAlign.center,
        showHeaderDivider: true,
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: Text(
              "Instructions not loaded",
              style: AppTextStyles.body.copyWith(color: AppColors.textBody),
            ),
          ),
        ),
        footer: AppPrimaryButton(
          label: AppStrings.ok.tr,
          onPressed: () => Get.back<void>(),
          borderRadius: 16.r,
          height: 56.h,
        ),
      );
    }

    final model = LocalBankInstructions.fromJson(
      Map<String, dynamic>.from(instructionsData),
    );
    final locale = Get.locale?.languageCode ?? 'en';

    if (model.items.isEmpty) {
      return AppStandardBottomSheet(
        title: AppStrings.addMoneyToWallet.tr,
        headerTextAlign: TextAlign.center,
        showHeaderDivider: true,
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: Text(
              "No instructions available",
              style: AppTextStyles.body.copyWith(color: AppColors.textBody),
            ),
          ),
        ),
        footer: AppPrimaryButton(
          label: AppStrings.ok.tr,
          onPressed: () => Get.back<void>(),
          borderRadius: 16.r,
          height: 56.h,
        ),
      );
    }

    final item = model.items.first;
    final title = item.getDisplayTitle(locale);
    final description = item.getDisplayDescription(locale);
    final steps = item.getDisplaySteps(locale);

    return AppStandardBottomSheet(
      title: AppStrings.addMoneyToWallet.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.homeTitle.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: AppTextStyles.homeSubtitle.copyWith(
              fontSize: 14.sp,
              color: AppColors.textBody,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ...steps.map((stepItem) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12.r,
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    child: Text(
                      stepItem.step,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final message = stepItem.instruction;
                        final regex = RegExp(r'\b\d{8,20}\b');
                        final match = regex.firstMatch(message);

                        if (match == null) {
                          return Text(
                            message,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textHeading,
                              fontSize: 14.sp,
                            ),
                          );
                        }

                        final accountNumber = match.group(0)!;
                        final before = message.substring(0, match.start);
                        final after = message.substring(match.end);

                        return RichText(
                          text: TextSpan(
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textHeading,
                              fontSize: 14.sp,
                            ),
                            children: [
                              TextSpan(text: before),
                              TextSpan(
                                text: formatWalletAccountNumber(accountNumber),
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.green,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: accountNumber),
                                    );
                                    if(Platform.isIOS){
                                      AppDialogs.showSuccessDialog(message: "${formatWalletAccountNumber(accountNumber)} copied",confirmLabel: 'Okay');
                                    }
                                  },
                              ),
                              TextSpan(text: after),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 24.h),
        ],
      ),
      footer: AppPrimaryButton(
        label: AppStrings.ok.tr,
        onPressed: () => Get.back<void>(),
        borderRadius: 16.r,
        height: 56.h,
      ),
    );
  }
}
