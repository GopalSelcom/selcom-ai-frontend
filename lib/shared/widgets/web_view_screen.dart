import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/network/api_constants.dart';
import '../../core/theme/app_colors.dart';
import 'app_profile_header.dart';

class WebViewScreen extends StatefulWidget {
  final String? title;
  final String? url;
  final String? htmlData;
  final String? language;

  const WebViewScreen({
    super.key,
    this.title,
    this.url,
    this.htmlData,
    this.language,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController webController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    /// 🔥 Initialize controller synchronously (IMPORTANT)
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            /// Allow all navigation
            return NavigationDecision.navigate;
          },

          /// When page starts
          onPageStarted: (url) {
            setState(() => isLoading = true);
          },

          /// When page finishes
          onPageFinished: (url) {
            setState(() => isLoading = false);
          },

          /// 🔴 VERY IMPORTANT (fix loader stuck issue)
          onWebResourceError: (error) {
            debugPrint("WebView Error: ${error.description}");
            setState(() => isLoading = false);
          },
        ),
      );

    /// ✅ Load URL with language header
    if (widget.url != null) {
      webController.loadRequest(
        Uri.parse(widget.url!),
        headers: widget.language != null
            ? {Params.language: widget.language!}
            : {},
      );
    } else if (widget.htmlData != null) {
      webController.loadHtmlString(widget.htmlData!);
    }
  }

  /// Back handling
  Future<bool> _onWillPop() async {
    if (await webController.canGoBack()) {
      webController.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,

        /// Body
        body: Column(
          children: [
            AppProfileHeader(title: widget.title),
            Expanded(
              child: Stack(
                children: [
                  /// WebView
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          width: 1.0.sp,
                          color: AppColors.inputBorderDefault,
                        ),
                      ),
                    ),
                    child: WebViewWidget(controller: webController),
                  ),

                  /// Loader
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
