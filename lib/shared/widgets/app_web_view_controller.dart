import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/network/api_constants.dart';
import '../../core/theme/app_colors.dart';

class AppWebViewController extends GetxController {
  AppWebViewController({
    this.url,
    this.htmlData,
    this.language,
  });

  final String? url;
  final String? htmlData;
  final String? language;

  final isLoading = true.obs;
  late final WebViewController webController;

  @override
  void onInit() {
    super.onInit();
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => NavigationDecision.navigate,
          onPageStarted: (_) => isLoading.value = true,
          onPageFinished: (_) => isLoading.value = false,
          onWebResourceError: (error) {
            debugPrint('WebView Error: ${error.description}');
            isLoading.value = false;
          },
        ),
      );

    if (url != null) {
      webController.loadRequest(
        Uri.parse(url!),
        headers: language != null ? {Params.language: language!} : {},
      );
    } else if (htmlData != null) {
      webController.loadHtmlString(htmlData!);
    }
  }

  Future<bool> handleWillPop() async {
    if (await webController.canGoBack()) {
      webController.goBack();
      return false;
    }
    return true;
  }
}
