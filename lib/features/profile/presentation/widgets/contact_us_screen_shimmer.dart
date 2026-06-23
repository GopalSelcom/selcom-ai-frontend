import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/app_shimmer.dart';
import 'contact_us_screen_layout.dart';

/// Content-section shimmer for [ContactUsScreen] initial load.
abstract final class ContactUsScreenShimmer {
  ContactUsScreenShimmer._();

  static Widget formContent() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ContactUsScreenLayout.horizontalPadding,
      ),
      child: SizedBox(
        height: ContactUsScreenLayout.contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppShimmer(child: _fieldLabel()),
            SizedBox(height: ContactUsScreenLayout.labelFieldGap),
            _reasonField(),
            SizedBox(height: ContactUsScreenLayout.labelFieldGap),
            AppShimmer(child: _fieldLabel()),
            SizedBox(height: ContactUsScreenLayout.labelFieldGap),
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
        height: ContactUsScreenLayout.fieldLabelLineHeight,
        borderRadius: 4.r,
      ),
    );
  }

  static Widget _reasonField() {
    return AppShimmer(
      child: AppShimmerBox(
        width: double.infinity,
        height: ContactUsScreenLayout.reasonFieldHeight,
        borderRadius: ContactUsScreenLayout.reasonFieldBorderRadius,
      ),
    );
  }

  static Widget _messageField() {
    return AppShimmer(
      child: AppShimmerBox(
        width: double.infinity,
        height: ContactUsScreenLayout.messageFieldHeight,
        borderRadius: ContactUsScreenLayout.messageFieldBorderRadius,
      ),
    );
  }
}
