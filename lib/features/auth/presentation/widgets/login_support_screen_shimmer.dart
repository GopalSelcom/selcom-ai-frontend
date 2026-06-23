import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'login_support_screen_layout.dart';

/// Content-section shimmer for [LoginSupportScreen] initial load.
abstract final class LoginSupportScreenShimmer {
  LoginSupportScreenShimmer._();

  static Widget formContent() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: LoginSupportScreenLayout.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labeledField(_singleLineField()),
          SizedBox(height: LoginSupportScreenLayout.sectionGap),
          _labeledField(_singleLineField()),
          SizedBox(height: LoginSupportScreenLayout.sectionGap),
          _labeledField(_phoneField()),
          SizedBox(height: LoginSupportScreenLayout.sectionGap),
          _labeledField(_reasonField()),
          SizedBox(height: LoginSupportScreenLayout.sectionGap),
          _labeledField(_messageField()),
        ],
      ),
    );
  }

  static Widget _labeledField(Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppShimmer(child: _fieldLabel()),
        SizedBox(height: LoginSupportScreenLayout.labelFieldGap),
        field,
      ],
    );
  }

  static Widget _fieldLabel() {
    return Align(
      alignment: Alignment.centerLeft,
      child: AppShimmerBox(
        width: 120.w,
        height: LoginSupportScreenLayout.fieldLabelLineHeight,
        borderRadius: 4.r,
      ),
    );
  }

  static Widget _singleLineField() {
    return AppShimmer(
      child: AppShimmerBox(
        width: double.infinity,
        height: LoginSupportScreenLayout.singleLineFieldHeight,
        borderRadius: LoginSupportScreenLayout.singleLineFieldBorderRadius,
      ),
    );
  }

  static Widget _phoneField() {
    return AppShimmer(
      child: Container(
        width: double.infinity,
        height: LoginSupportScreenLayout.singleLineFieldHeight,
        padding: EdgeInsets.symmetric(
          horizontal: LoginSupportScreenLayout.phoneFieldInnerPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(
            LoginSupportScreenLayout.singleLineFieldBorderRadius,
          ),
        ),
        child: Row(
          children: [
            AppShimmerBox(
              width: LoginSupportScreenLayout.phoneChipWidth,
              height: LoginSupportScreenLayout.phoneChipHeight,
              borderRadius: 100.r,
            ),
            SizedBox(width: LoginSupportScreenLayout.phoneChipGap),
            Expanded(
              child: AppShimmerBox(
                width: double.infinity,
                height: LoginSupportScreenLayout.phoneChipHeight,
                borderRadius: 4.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _reasonField() {
    return AppShimmer(
      child: AppShimmerBox(
        width: double.infinity,
        height: LoginSupportScreenLayout.reasonFieldHeight,
        borderRadius: LoginSupportScreenLayout.reasonFieldBorderRadius,
      ),
    );
  }

  static Widget _messageField() {
    return AppShimmer(
      child: AppShimmerBox(
        width: double.infinity,
        height: LoginSupportScreenLayout.messageFieldHeight,
        borderRadius: LoginSupportScreenLayout.messageFieldBorderRadius,
      ),
    );
  }
}
