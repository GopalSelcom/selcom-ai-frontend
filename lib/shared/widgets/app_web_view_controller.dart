import 'dart:async';

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
    this.baseUrl,
  });

  final String? url;
  final String? htmlData;
  final String? language;
  final String? baseUrl;

  final isLoading = true.obs;
  late final WebViewController webController;

  static const _logTag = 'AppWebView';

  /// Hosted checkout success page (top-up / add-card URL flow).
  static const _redirectHtmlMarker = 'redirect.html';

  /// Native SOP / Selcom gateway payment result page.
  static const _checkoutReturnMarker = 'checkout-return';

  /// Brief pause so the gateway message is visible before closing.
  static const _completionDelay = Duration(seconds: 2);

  bool _hasCompleted = false;
  bool _isOnTerminalPage = false;
  Timer? _completionTimer;
  String? _currentUrl;

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
            // Hosted checkout: close immediately on redirect.html (legacy signal).
            if (_isRedirectHtml(request.url)) {
              unawaited(_completePayment(success: true, delay: Duration.zero));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (pageUrl) {
            isLoading.value = true;
            _currentUrl = pageUrl;
            _isOnTerminalPage = _isTerminalUrl(pageUrl);
            _logPageEvent('started', pageUrl);
          },
          onPageFinished: (pageUrl) {
            isLoading.value = false;
            _currentUrl = pageUrl;
            _isOnTerminalPage = _isTerminalUrl(pageUrl);
            _logPageEvent('finished', pageUrl);
            unawaited(_logPageResponseSuccess(pageUrl));
            if (_isTerminalUrl(pageUrl)) {
              unawaited(_handleTerminalPageFinished(pageUrl));
            }
          },
          onHttpError: _logHttpResponseError,
          onUrlChange: (change) {
            final nextUrl = change.url;
            if (nextUrl != null && nextUrl.isNotEmpty) {
              _currentUrl = nextUrl;
              _isOnTerminalPage = _isTerminalUrl(nextUrl);
              _logUrlChange(nextUrl);
            }
          },
          onWebResourceError: (error) {
            _logWebResourceError(error);
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
      webController.loadHtmlString(htmlData!, baseUrl: baseUrl);
    }
  }

  @override
  void onClose() {
    _completionTimer?.cancel();
    _completionTimer = null;
    super.onClose();
  }

  /// Same `language` header as API calls: `en` (default) or `sw`.
  String _resolvedLanguageHeader() {
    return apiLanguageHeaderValue(language ?? Get.locale?.languageCode);
  }

  bool _isRedirectHtml(String pageUrl) =>
      pageUrl.toLowerCase().contains(_redirectHtmlMarker);

  bool _isCheckoutReturn(String pageUrl) =>
      pageUrl.toLowerCase().contains(_checkoutReturnMarker);

  /// Payment finished — either hosted redirect or Selcom checkout-return.
  bool _isTerminalUrl(String pageUrl) =>
      _isRedirectHtml(pageUrl) || _isCheckoutReturn(pageUrl);

  /// On checkout-return: read page text, decide success/failure, then close.
  Future<void> _handleTerminalPageFinished(String pageUrl) async {
    if (_hasCompleted) return;

    // redirect.html is already handled in onNavigationRequest; if it still
    // loads, treat as success.
    if (_isRedirectHtml(pageUrl)) {
      await _completePayment(success: true);
      return;
    }

    final pageText = await _readPageBodyText();
    final success = _inferPaymentSuccess(
      pageUrl: pageUrl,
      pageText: pageText,
    );
    AppLogger.d(
      'TERMINAL >> $pageUrl | success=$success | '
      'snippet=${_snippet(pageText)}',
      tag: _logTag,
    );
    await _completePayment(success: success);
  }

  Future<String> _readPageBodyText() async {
    try {
      final raw = await webController.runJavaScriptReturningResult(
        '(function(){try{return document.body?document.body.innerText:"";}catch(e){return "";}})()',
      );
      return _normalizeJsString(raw);
    } catch (_) {
      return '';
    }
  }

  String _normalizeJsString(Object raw) {
    var text = raw.toString().trim();
    // Android often wraps the result in quotes.
    if (text.length >= 2 &&
        ((text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith("'") && text.endsWith("'")))) {
      text = text.substring(1, text.length - 1);
    }
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', ' ')
        .replaceAll(r'\"', '"')
        .trim();
  }

  String _snippet(String text) {
    if (text.isEmpty) return '(empty)';
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ');
    return oneLine.length <= 120 ? oneLine : '${oneLine.substring(0, 120)}…';
  }

  /// Infer success from page body / URL query. Ambiguous → false (close safely).
  bool _inferPaymentSuccess({
    required String pageUrl,
    required String pageText,
  }) {
    final haystack = '${pageUrl.toLowerCase()} ${pageText.toLowerCase()}';

    const failureSignals = [
      'transaction failed',
      'payment failed',
      'payment declined',
      'card declined',
      'declined',
      'failed',
      'failure',
      'unsuccessful',
      'error',
      'reject',
      'denied',
      'cancel',
      'cancelled',
      'canceled',
    ];
    const successSignals = [
      'transaction successful',
      'payment successful',
      'payment success',
      'successfully',
      'approved',
      'accepted',
      'completed',
      'success',
    ];

    final hasFailure = failureSignals.any(haystack.contains);
    final hasSuccess = successSignals.any(haystack.contains);

    if (hasFailure && !hasSuccess) return false;
    if (hasSuccess && !hasFailure) return true;
    // Mixed or empty: prefer failure so we do not show a false success.
    return false;
  }

  Future<void> _completePayment({
    required bool success,
    Duration delay = _completionDelay,
  }) async {
    if (_hasCompleted) return;
    _hasCompleted = true;
    _isOnTerminalPage = true;
    _completionTimer?.cancel();

    if (delay <= Duration.zero) {
      _popWithResult(success);
      return;
    }

    _completionTimer = Timer(delay, () {
      _popWithResult(success);
    });
  }

  void _popWithResult(bool success) {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back(result: success);
    }
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

  void _logUrlChange(String nextUrl) {
    if (!AppLogger.enabled) return;
    AppLogger.d('URL CHANGE >> $nextUrl', tag: _logTag);
  }

  void _logHttpResponseError(HttpResponseError error) {
    if (!AppLogger.enabled) return;
    final response = error.response;
    final request = error.request;
    final uri = response?.uri ?? request?.uri;
    final url = uri?.toString() ?? 'unknown';
    final statusCode = response?.statusCode;
    AppLogger.e(
      '❌ RESPONSE >> $url | status=${statusCode ?? 'N/A'}',
      tag: _logTag,
    );
    final headers = response?.headers;
    if (headers != null && headers.isNotEmpty) {
      AppLogger.d('$url [Response Headers] $headers', tag: _logTag);
    }
  }

  void _logWebResourceError(WebResourceError error) {
    if (!AppLogger.enabled) return;
    final failingUrl = error.url;
    AppLogger.e(
      '❌ RESPONSE >> ${failingUrl ?? 'unknown'} | '
      'resource_error=${error.description} | '
      'type=${error.errorType} | code=${error.errorCode}',
      tag: _logTag,
    );
  }

  Future<void> _logPageResponseSuccess(String pageUrl) async {
    if (!AppLogger.enabled) return;
    try {
      final title = await webController.getTitle();
      AppLogger.d(
        '✅ RESPONSE >> $pageUrl | status=loaded | title=${title ?? ''}',
        tag: _logTag,
      );
    } catch (_) {
      AppLogger.d(
        '✅ RESPONSE >> $pageUrl | status=loaded',
        tag: _logTag,
      );
    }
  }

  /// System / header back: leave Flutter route on result pages; else WebView history.
  Future<bool> handleWillPop() async {
    final current = _currentUrl;
    if (_hasCompleted ||
        _isOnTerminalPage ||
        (current != null && _isTerminalUrl(current))) {
      _completionTimer?.cancel();
      _hasCompleted = true;
      return true;
    }
    if (await webController.canGoBack()) {
      webController.goBack();
      return false;
    }
    return true;
  }
}
