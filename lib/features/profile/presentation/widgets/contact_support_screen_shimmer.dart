import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/app_shimmer.dart';
import 'contact_support_screen_layout.dart';

/// Content-section shimmer for [ContactSupportScreen] initial load.
abstract final class ContactSupportScreenShimmer {
  ContactSupportScreenShimmer._();

  static Widget formContent() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ContactSupportScreenLayout.horizontalPadding,
      ),
      child: SizedBox(
        height: ContactSupportScreenLayout.contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppShimmer(child: _fieldLabel()),
            SizedBox(height: ContactSupportScreenLayout.labelFieldGap),
            _reasonField(),
            SizedBox(height: ContactSupportScreenLayout.labelFieldGap),
            AppShimmer(child: _fieldLabel()),
            SizedBox(height: ContactSupportScreenLayout.labelFieldGap),
            _messageField(),
          ],
        ),
      ),
    );
  }

  static Widget _fieldLabel() {
    return Align(
      alignment: Alignment.centerLeft,
      child: AppShimmerBox(
        width: 140.w,
        height: ContactSupportScreenLayout.fieldLabelLineHeight,
        borderRadius: 4.r,
      ),
    );
  }

  static Widget _reasonField() {
    return AppShimmer(
      child: AppShimmerBox(
        width: double.infinity,
        height: ContactSupportScreenLayout.reasonFieldHeight,
        borderRadius: ContactSupportScreenLayout.reasonFieldBorderRadius,
      ),
    );
  }

  static Widget _messageField() {
    return AppShimmer(
      child: AppShimmerBox(
        width: double.infinity,
        height: ContactSupportScreenLayout.messageFieldHeight,
        borderRadius: ContactSupportScreenLayout.messageFieldBorderRadius,
      ),
    );
  }
}
