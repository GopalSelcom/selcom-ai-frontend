import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/headers.dart';
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

  static const _logTag = 'AppWebView';

  @override
  void onInit() {
    super.onInit();
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            _logNavigationRequest(request.url);
            return NavigationDecision.navigate;
          },
          onPageStarted: (pageUrl) {
            isLoading.value = true;
            _logPageEvent('started', pageUrl);
          },
          onPageFinished: (pageUrl) {
            isLoading.value = false;
            _logPageEvent('finished', pageUrl);
          },
          onWebResourceError: (error) {
            AppLogger.e(
              'WebView error: ${error.description} | '
              'type=${error.errorType} | code=${error.errorCode}',
              tag: _logTag,
            );
            isLoading.value = false;
          },
        ),
      );

    if (url != null) {
      final headers = {Params.language: _resolvedLanguageHeader()};
      _logLoadRequest(url!, headers);
      webController.loadRequest(
        Uri.parse(url!),
        headers: headers,
      );
    } else if (htmlData != null) {
      _logHtmlLoad();
      webController.loadHtmlString(htmlData!);
    }
  }

  /// Same `language` header as API calls: `en` (default) or `sw`.
  String _resolvedLanguageHeader() {
    return apiLanguageHeaderValue(language ?? Get.locale?.languageCode);
  }

  void _logLoadRequest(String requestUrl, Map<String, String> headers) {
    if (!AppLogger.enabled) return;
    AppLogger.d('REQUEST >> GET $requestUrl', tag: _logTag);
    AppLogger.d('$requestUrl [Headers] $headers', tag: _logTag);
  }

  void _logHtmlLoad() {
    if (!AppLogger.enabled) return;
    final length = htmlData?.length ?? 0;
    AppLogger.d('REQUEST >> loadHtmlString (length=$length)', tag: _logTag);
  }

  void _logNavigationRequest(String requestUrl) {
    if (!AppLogger.enabled) return;
    AppLogger.d('NAVIGATE >> $requestUrl', tag: _logTag);
  }

  void _logPageEvent(String event, String pageUrl) {
    if (!AppLogger.enabled) return;
    AppLogger.d('PAGE $event >> $pageUrl', tag: _logTag);
  }

  Future<bool> handleWillPop() async {
    if (await webController.canGoBack()) {
      webController.goBack();
      return false;
    }
    return true;
  }
}
