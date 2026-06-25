import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import 'app_profile_header.dart';
import 'app_scaffold.dart';
import 'app_web_view_controller.dart';
import 'web_view_content_shimmer.dart';

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({
    super.key,
    required this.controllerTag,
    this.title,
  });

  final String controllerTag;
  final String? title;

  AppWebViewController get controller =>
      Get.find<AppWebViewController>(tag: controllerTag);

  static Future<T?> open<T>({
    String? title,
    String? url,
    String? htmlData,
    String? language,
  }) async {
    final controllerTag = 'app_web_view_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(
      AppWebViewController(url: url, htmlData: htmlData, language: language),
      tag: controllerTag,
    );

    try {
      return await Get.to<T>(
        () => WebViewScreen(controllerTag: controllerTag, title: title),
      );
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (Get.isRegistered<AppWebViewController>(tag: controllerTag)) {
          Get.delete<AppWebViewController>(tag: controllerTag);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await controller.handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppScaffold(
        body: Column(
          children: [
            AppProfileHeader(title: title),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          width: 1.0.sp,
                          color: AppColors.inputBorderDefault,
                        ),
                      ),
                    ),
                    child: WebViewWidget(controller: controller.webController),
                  ),
                  Obx(
                    () => controller.isLoading.value
                        ? WebViewContentShimmer.content()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
