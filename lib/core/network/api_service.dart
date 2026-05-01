import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:http_parser/http_parser.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../constants/app_assets.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/storage_service.dart';
import 'failed_request_queue.dart';
import 'retry_manager.dart';
import '../../shared/utils/app_dialogs.dart';
import '../services/error_reporting/error_reporter.dart';
import '../services/error_reporting/models/error_constants.dart';

// ─────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────

enum ApiEnvironment { local, staging, production }

enum ApiMethod { get, post, put, delete, patch, multipart }

enum ErrorPresentationType { none, dialog, snackbar }

// ─────────────────────────────────────────────────────────
// Multipart File Model
// ─────────────────────────────────────────────────────────

class LocalMultipartFile {
  final String name;
  final String path;
  final String? contentType;

  LocalMultipartFile({
    required this.name,
    required this.path,
    this.contentType,
  });
}

// ─────────────────────────────────────────────────────────
// API Request Model
// ─────────────────────────────────────────────────────────

class ApiRequest {
  final String endpoint;
  final String version;
  final String route;
  final String customBaseUrl;
  final ApiMethod method;
  final Map<String, dynamic>? body;
  final Map<String, dynamic>? queryParams;
  final Map<String, dynamic>? headers;
  final ErrorPresentationType errorPresentationType;
  final bool showLoader;
  final bool skipAuthInterceptor;
  final List<LocalMultipartFile>? multipartFiles;
  final bool shouldQueue;

  ApiRequest({
    required this.endpoint,
    required this.method,
    this.version = "v4",
    this.route = "",
    this.body,
    this.customBaseUrl = "",
    this.queryParams,
    this.headers,
    this.showLoader = false,
    this.errorPresentationType = ErrorPresentationType.dialog,
    this.skipAuthInterceptor = false,
    this.multipartFiles,
    this.shouldQueue = true,
  });
}

// ─────────────────────────────────────────────────────────
// API Service (Singleton)
// ─────────────────────────────────────────────────────────

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  late Dio _defaultDio;
  late Dio _customDio;
  late String _baseUrl;
  late AuthInterceptor _authInterceptor;

  Map<String, dynamic> _commonBodyParams = {};

  static late ApiEnvironment currentEnvironment;

  late final Future<Map<String, String>> Function() _commonHeadersBuilder;

  // ── Initialization ──

  void init({
    required String stagingBaseUrl,
    required String productionBaseUrl,
    required ApiEnvironment environment,
    required Future<Map<String, String>> Function() commonHeadersBuilder,
    String? localBaseUrl,
    Map<String, dynamic>? commonBodyParams,
  }) {
    currentEnvironment = environment;
    _commonHeadersBuilder = commonHeadersBuilder;

    switch (environment) {
      case ApiEnvironment.local:
        _baseUrl = localBaseUrl ?? stagingBaseUrl;
        break;
      case ApiEnvironment.staging:
        _baseUrl = stagingBaseUrl;
        break;
      case ApiEnvironment.production:
        _baseUrl = productionBaseUrl;
        break;
    }

    _commonBodyParams = commonBodyParams ?? {};

    _defaultDio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
      ),
    );

    _customDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
      ),
    );

    // Add auth interceptor
    _authInterceptor = AuthInterceptor(apiService: this);
    _defaultDio.interceptors.add(_authInterceptor);
  }

  // ── Getters ──

  String get baseUrl => _baseUrl;

  // ── Internet Check ──

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  // ── Dio Client Selection ──

  Dio _getClient(ApiRequest request) {
    if (request.customBaseUrl.isNotEmpty) {
      _customDio.options.baseUrl = request.customBaseUrl;
      return _customDio;
    }
    return _defaultDio;
  }

  // ── Main API Call ──

  Future<Response> call({required ApiRequest request}) async {
    final String route = request.route.isEmpty ? "api" : request.route;
    final client = _getClient(request);

    // ── No Internet ──
    if (!await _checkInternetConnection()) {
      developer.log(
        "🌐 No Internet → ${client.options.baseUrl}${request.endpoint}",
        name: 'ApiService',
      );

      if (request.shouldQueue && !request.skipAuthInterceptor) {
        final completer = Completer<Response>();
        await FailedRequestQueue.instance.add(request, completer);

        if (!RetryManager.instance.isPopupShowing) {
          RetryManager.instance.showRetryPopup();
        }

        return completer.future;
      }

      return Response(
        requestOptions: RequestOptions(path: request.endpoint),
        statusCode: 503,
        data: {'message': 'No Internet Connection'},
      );
    }

    final stopwatch = Stopwatch()..start();

    // ── Build Endpoint ──
    final String endpoint;
    if (request.customBaseUrl.isNotEmpty) {
      endpoint = request.endpoint;
    } else {
      final parts = <String>[];
      if (route.isNotEmpty) parts.add(route);
      if (request.version.isNotEmpty) parts.add(request.version);
      parts.add(request.endpoint);
      endpoint = '/${parts.join('/')}';
    }

    final fullUrl = '${client.options.baseUrl}$endpoint';

    // ── Merge Body ──
    final Map<String, dynamic> finalBody = {
      ..._commonBodyParams,
      if (request.body != null) ...request.body!,
    };

    // ── Merge Headers ──
    final Map<String, dynamic> finalHeaders = Map<String, dynamic>.from(
      await _commonHeadersBuilder(),
    );
    if (request.headers != null) finalHeaders.addAll(request.headers!);

    if (request.method == ApiMethod.multipart) {
      finalHeaders['Content-Type'] = 'multipart/form-data';
    }

    if (kDebugMode) _logRequest(fullUrl, request, finalHeaders, finalBody);

    try {
      // Skip auth interceptor flag
      if (request.skipAuthInterceptor) {
        finalHeaders['skip-auth-interceptor'] = 'true';
      }

      // ── Multipart ──
      if (request.method == ApiMethod.multipart) {
        return await _handleMultipartRequest(
          dioInstance: client,
          endpoint: fullUrl,
          request: request,
          finalHeaders: finalHeaders,
          finalBody: finalBody,
          stopwatch: stopwatch,
          fullUrl: fullUrl,
        );
      }

      // ── Standard Request ──
      final response = await client.request(
        fullUrl,
        data: finalBody.isNotEmpty ? finalBody : null,
        queryParameters: request.queryParams,
        options: Options(
          method: _methodToString(request.method),
          headers: finalHeaders,
        ),
      );

      stopwatch.stop();

      if (kDebugMode) {
        _logResponse(
          fullUrl: fullUrl,
          statusCode: response.statusCode,
          duration: stopwatch.elapsedMilliseconds,
          data: response.data,
          isError: false,
        );
      }

      return response;
    } on DioException catch (e) {
      stopwatch.stop();

      if (kDebugMode) {
        _logResponse(
          fullUrl: fullUrl,
          statusCode: e.response?.statusCode,
          duration: stopwatch.elapsedMilliseconds,
          data: e.response?.data,
          isError: true,
          errorMessage: e.message,
        );
      }

      return _handleDioError(e, request);
    } catch (e) {
      stopwatch.stop();
      developer.log("💥 [API EXCEPTION] $fullUrl | $e", name: 'ApiService');
      return Response(
        requestOptions: RequestOptions(path: request.endpoint),
        statusCode: 500,
        data: {'error': 'Unexpected error occurred: $e'},
      );
    }
  }

  // ── Multipart Handling ──

  Future<Response> _handleMultipartRequest({
    required Dio dioInstance,
    required String endpoint,
    required ApiRequest request,
    required Map<String, dynamic> finalHeaders,
    required Map<String, dynamic> finalBody,
    required Stopwatch stopwatch,
    required String fullUrl,
  }) async {
    FormData formData = FormData();

    // Add regular fields
    finalBody.forEach((key, value) {
      formData.fields.add(MapEntry(key, value?.toString() ?? ''));
    });

    // Add files
    if (request.multipartFiles != null && request.multipartFiles!.isNotEmpty) {
      for (LocalMultipartFile file in request.multipartFiles!) {
        if (file.name.isNotEmpty && file.path.isNotEmpty) {
          String contentType = file.contentType ?? _getContentType(file.path);

          MultipartFile multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
            contentType: MediaType.parse(contentType),
          );

          formData.files.add(MapEntry(file.name, multipartFile));
        }
      }
    }

    developer.log(
      "📦 Multipart files count: ${formData.files.length}",
      name: 'ApiService',
    );

    final response = await dioInstance.request(
      endpoint,
      data: formData,
      queryParameters: request.queryParams,
      options: Options(method: 'POST', headers: finalHeaders),
      onSendProgress: (sent, total) {
        if (kDebugMode) {
          int percentage = ((sent / total) * 100).toInt();
          developer.log(
            "📤 Upload Progress: $percentage% ($sent/$total bytes)",
            name: 'ApiService',
          );
        }
      },
    );

    stopwatch.stop();

    if (kDebugMode) {
      _logResponse(
        fullUrl: fullUrl,
        statusCode: response.statusCode,
        duration: stopwatch.elapsedMilliseconds,
        data: response.data,
        isError: false,
      );
    }

    return response;
  }

  // ── Content Type Detection ──

  String _getContentType(String path) {
    String extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // ── Logging ──

  void _logRequest(
    String fullUrl,
    ApiRequest request,
    Map<String, dynamic> headers,
    Map<String, dynamic> body,
  ) {
    final safeHeaders = _redactSensitiveMap(headers);
    final safeQuery = _redactSensitiveMap(request.queryParams);
    final safeBody = _redactSensitiveMap(body);
    developer.log(
      "🚀 REQUEST >> ${request.method.name.toUpperCase()} $fullUrl",
      name: 'ApiService',
    );
    developer.log(
      "$fullUrl [Headers] ${_safeJsonEncode(safeHeaders)}",
      name: 'ApiService',
    );
    developer.log(
      "$fullUrl [Query] ${_safeJsonEncode(safeQuery)}",
      name: 'ApiService',
    );
    developer.log(
      "$fullUrl [Body] ${_safeJsonEncode(safeBody)}",
      name: 'ApiService',
    );

    ErrorReporter.instance.addLog(
      "🚀 API REQUEST: ${request.method.name.toUpperCase()} $fullUrl | Query: ${jsonEncode(safeQuery)} | Body: ${jsonEncode(safeBody)}",
      tag: 'API',
    );
  }

  void _logResponse({
    required String fullUrl,
    required int? statusCode,
    required int duration,
    required dynamic data,
    required bool isError,
    String? errorMessage,
  }) {
    final prefix = isError ? '❌ ERROR' : '✅ SUCCESS';
    developer.log(
      "$prefix >> $fullUrl | ${statusCode ?? 'N/A'} | ${duration}ms",
      name: 'ApiService',
    );
    if (isError && errorMessage != null) {
      developer.log("$fullUrl Message: $errorMessage", name: 'ApiService');
    }
    developer.log(
      "$fullUrl [Response] ${_safeJsonEncode(_redactSensitiveData(data))}",
      name: 'ApiService',
    );

    ErrorReporter.instance.addLog(
      "✅ API RESPONSE: $fullUrl | Status: ${statusCode ?? 'N/A'} | Error: $isError | Message: ${errorMessage ?? 'None'}",
      tag: 'API',
    );
  }

  String _methodToString(ApiMethod method) {
    switch (method) {
      case ApiMethod.get:
        return 'GET';
      case ApiMethod.post:
        return 'POST';
      case ApiMethod.put:
        return 'PUT';
      case ApiMethod.delete:
        return 'DELETE';
      case ApiMethod.patch:
        return 'PATCH';
      case ApiMethod.multipart:
        return 'POST';
    }
  }

  // ── Error Handling ──

  Future<Response> _handleDioError(DioException e, ApiRequest request) async {
    String message = 'Something went wrong';
    int statusCode = e.response?.statusCode ?? 500;

    // Let the interceptor handle 401 errors
    if (statusCode == 401) {
      return Response(
        requestOptions: e.requestOptions,
        statusCode: statusCode,
        data: e.response?.data ?? {'message': 'Unauthorized'},
      );
    }

    if (statusCode == 400) {
      return Response(
        requestOptions: e.requestOptions,
        statusCode: statusCode,
        data: e.response?.data ?? {'message': 'Bad request'},
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        try {
          final data = e.response?.data;
          if (data is Map) {
            message = data['message'] ?? 'Bad response from server';
          } else {
            message = 'Server Error ($statusCode)';
          }
        } catch (_) {
          message = 'Bad response from server';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Network is unreachable';
        break;
      case DioExceptionType.unknown:
        message = 'No internet or unexpected error';
        break;
      default:
        message = 'Unexpected network error';
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      developer.log(
        "⏳ Server slow response (receive timeout)",
        name: 'ApiService',
      );

      if (request.errorPresentationType == ErrorPresentationType.dialog) {
        AppDialogs.showErrorDialog(
          title: AppStrings.timeout.tr,
          message: 'Server is taking too long to respond. Please try again.',
        );
      }

      return Response(
        requestOptions: e.requestOptions,
        statusCode: 408,
        data: {'message': 'Server timeout'},
      );
    }

    // Check for network-related error that should be retried
    final isNetworkError =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;

    if (isNetworkError && request.shouldQueue && !request.skipAuthInterceptor) {
      developer.log(
        "📥 Queueing failed request: ${request.endpoint}",
        name: 'ApiService',
      );
      final completer = Completer<Response>();
      final added = await FailedRequestQueue.instance.add(request, completer);

      if (added) {
        if (!RetryManager.instance.isPopupShowing) {
          developer.log("📱 Showing retry popup", name: 'ApiService');
          unawaited(RetryManager.instance.showRetryPopup());
        }
      }

      return completer.future;
    }

    if (request.errorPresentationType == ErrorPresentationType.dialog) {
      AppDialogs.showErrorDialog(message: message);
    }

    // Automatically report significant errors (Server errors, timeouts, etc.)
    if (statusCode >= 500 || statusCode == 408 || isNetworkError) {
      ErrorReporter.instance.report(
        error: e,
        customMessage: "API Error at ${request.endpoint} | Status: $statusCode",
        errorKey: isNetworkError ? ErrorKeys.apiTimeout : ErrorKeys.logicError,
      );
    }

    return Response(
      requestOptions: e.requestOptions,
      statusCode: statusCode,
      data: {'message': message},
    );
  }

  static String _safeJsonEncode(dynamic data) {
    try {
      if (data == null) return '{}';
      return jsonEncode(data);
    } catch (_) {
      return data?.toString() ?? '{}';
    }
  }

  static const Set<String> _sensitiveKeys = {
    'authorization',
    'access_token',
    'refresh_token',
    'authorization_token',
    'token',
    'otp',
    'pin',
    'phone',
    'mobile',
    'mobile_number',
    'email',
    'nida',
  };

  static dynamic _redactSensitiveData(dynamic data) {
    if (data is Map) {
      return _redactSensitiveMap(data);
    }
    if (data is List) {
      return data.map(_redactSensitiveData).toList();
    }
    return data;
  }

  static Map<String, dynamic> _redactSensitiveMap(Map? source) {
    if (source == null) return {};
    final out = <String, dynamic>{};
    source.forEach((key, value) {
      final keyText = key.toString();
      final normalized = keyText.toLowerCase();
      if (_sensitiveKeys.any((s) => normalized.contains(s))) {
        out[keyText] = kDebugMode ? value : '***REDACTED***';
        return;
      }
      out[keyText] = _redactSensitiveData(value);
    });
    return out;
  }

  // ── Session Expired Popup ──

  void showLogoutPopup() {
    if (AuthInterceptor.isLoggingOutDueToAuthFailure) return;
    AuthInterceptor.isLoggingOutDueToAuthFailure = true;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        backgroundColor: AppColors.cardBackground,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo
              SvgPicture.asset(AppAssets.selcomGoLogo, height: 48.h),
              SizedBox(height: 24.h),

              // Title
              Text(
                AppStrings.sessionExpired.tr,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 22.sp,
                  color: AppColors.textHeading,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                AppStrings.yourSessionHasExpiredPleaseLoginAgainToContinue.tr,
                style: AppTextStyles.onboardingSubtitle.copyWith(
                  fontSize: 15.sp,
                  color: AppColors.textBody,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Login Button
              InkWell(
                onTap: () async {
                  // Clear tokens
                  await StorageService().deleteAll();
                  AuthInterceptor.isLoggingOutDueToAuthFailure = false;
                  Get.back();
                  // Navigate to phone input screen
                  Get.offAllNamed(AppRoutes.phone);
                },
                child: Container(
                  height: 54.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.login.tr,
                      style: AppTextStyles.onboardingButton.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Auth Interceptor (Token Refresh + 401 Handling)
// ─────────────────────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final ApiService apiService;

  // Static variables for global refresh coordination
  static Completer<bool>? _refreshCompleter;
  static bool _isRefreshing = false;
  static bool isLoggingOutDueToAuthFailure = false;

  static bool _isAuthErrorCode(String? errorCode) {
    switch (errorCode) {
      case 'AUTH_NO_TOKEN':
      case 'AUTH_INVALID_TOKEN':
      case 'AUTH_SESSION_REVOKED':
      case 'AUTH_TOKEN_EXPIRED':
        return true;
      default:
        return false;
    }
  }

  AuthInterceptor({required this.apiService});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService().read(StorageKeys.authorizationToken);

    final currentAuth = options.headers['Authorization'];
    final hasAuthHeader =
        currentAuth != null && currentAuth.toString().trim().isNotEmpty;

    if ((token?.isNotEmpty ?? false) && !hasAuthHeader) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    developer.log("dioError => ${err.error}", name: 'AuthInterceptor');
    final responseData = err.response?.data;
    final errorCode = (responseData is Map<String, dynamic>)
        ? responseData['error_code'] as String?
        : null;
    if (_isAuthErrorCode(errorCode)) {
      developer.log(
        "❌ Auth error_code detected ($errorCode) - logging out",
        name: 'AuthInterceptor',
      );
      apiService.showLogoutPopup();
      return handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          statusCode: 401,
          data: {'message': 'Session expired, please login again'},
        ),
      );
    }

    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for requests that should skip auth
    final skipAuth = err.requestOptions.headers['skip-auth-interceptor'];
    if (skipAuth == 'true') {
      developer.log(
        "⏭️ Skipping auth interceptor for this request",
        name: 'AuthInterceptor',
      );
      return handler.next(err);
    }

    // Prevent infinite retry loops
    if (err.requestOptions.headers['retry-after-refresh'] == 'true') {
      developer.log(
        "❌ Request already retried after refresh, logging out",
        name: 'AuthInterceptor',
      );
      apiService.showLogoutPopup();
      return handler.next(err);
    }

    developer.log(
      "🔄 401 Unauthorized detected, attempting token refresh...",
      name: 'AuthInterceptor',
    );

    try {
      final refreshSuccess = await _handleTokenRefresh();

      if (refreshSuccess) {
        developer.log(
          "✅ Token refreshed successfully, retrying request",
          name: 'AuthInterceptor',
        );

        final newToken = await StorageService().read(
          StorageKeys.authorizationToken,
        );

        // Update headers with new token
        final updatedHeaders = Map<String, dynamic>.from(
          err.requestOptions.headers,
        );

        updatedHeaders['Authorization'] = 'Bearer $newToken';
        updatedHeaders['retry-after-refresh'] = 'true';

        // Also update access_token if present
        if (updatedHeaders.containsKey('access_token')) {
          final newAccessToken = await StorageService().read(
            StorageKeys.accessToken,
          );
          updatedHeaders['access_token'] = newAccessToken;
        }

        developer.log(
          "✅ Headers updated with new token for retry",
          name: 'AuthInterceptor',
        );

        // Create new RequestOptions with updated token
        final newOptions = err.requestOptions.copyWith(headers: updatedHeaders);

        // Retry the request
        try {
          developer.log(
            "🔄 Retrying request to: ${newOptions.uri.toString()}",
            name: 'AuthInterceptor',
          );

          final response = await Dio().request(
            newOptions.uri.toString(),
            data: newOptions.data,
            queryParameters: newOptions.queryParameters,
            options: Options(
              method: newOptions.method,
              headers: newOptions.headers,
              contentType: newOptions.contentType,
              responseType: newOptions.responseType,
              validateStatus: newOptions.validateStatus,
            ),
            cancelToken: newOptions.cancelToken,
            onSendProgress: newOptions.onSendProgress,
            onReceiveProgress: newOptions.onReceiveProgress,
          );
          developer.log(
            "✅ Retry succeeded with status: ${response.statusCode}",
            name: 'AuthInterceptor',
          );
          return handler.resolve(response);
        } catch (retryError) {
          developer.log(
            "❌ Retry request failed: $retryError",
            name: 'AuthInterceptor',
          );

          // If retry also fails with 401 — session truly expired
          if (retryError is DioException &&
              retryError.response?.statusCode == 401) {
            developer.log(
              "❌ Retry failed with 401, token refresh ineffective - logging out",
              name: 'AuthInterceptor',
            );

            apiService.showLogoutPopup();

            return handler.resolve(
              Response(
                requestOptions: err.requestOptions,
                statusCode: 401,
                data: {'message': 'Session expired, please login again'},
              ),
            );
          }

          if (retryError is DioException) {
            return handler.next(retryError);
          }
          return handler.next(err);
        }
      } else {
        developer.log(
          "❌ Token refresh failed, logging out",
          name: 'AuthInterceptor',
        );

        apiService.showLogoutPopup();

        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            statusCode: 401,
            data: {'message': 'Session expired, please login again'},
          ),
        );
      }
    } catch (e) {
      developer.log(
        "💥 Unexpected error during refresh: $e",
        name: 'AuthInterceptor',
      );

      apiService.showLogoutPopup();

      return handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          statusCode: 401,
          data: {'message': 'Session expired, please login again'},
        ),
      );
    }
  }

  static Future<bool> _handleTokenRefresh() async {
    // If refresh is already in progress, wait for it
    if (_isRefreshing && _refreshCompleter != null) {
      developer.log(
        "⏳ Token refresh already in progress, waiting...",
        name: 'AuthInterceptor',
      );
      return await _refreshCompleter!.future;
    }

    // Start new refresh process
    developer.log("🔄 Starting token refresh", name: 'AuthInterceptor');
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await StorageService().read(
        StorageKeys.refreshToken,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        developer.log("❌ No refresh token available", name: 'AuthInterceptor');
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(false);
        }
        return false;
      }

      // Call refresh token API (skip auth interceptor to avoid loop)
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: 'refresh_token',
          method: ApiMethod.post,
          body: {'refresh_token': refreshToken},
          skipAuthInterceptor: true,
          shouldQueue: false,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final newAccessToken =
            data['authorization_token'] ?? data['access_token'];
        final newRefreshToken = data['refresh_token'];

        if (newAccessToken != null) {
          await StorageService().write(
            StorageKeys.authorizationToken,
            newAccessToken,
          );
        }
        if (data['access_token'] != null) {
          await StorageService().write(
            StorageKeys.accessToken,
            data['access_token'],
          );
        }
        if (newRefreshToken != null) {
          await StorageService().write(
            StorageKeys.refreshToken,
            newRefreshToken,
          );
        }

        developer.log("✅ Tokens refreshed and saved", name: 'AuthInterceptor');

        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(true);
        }
        return true;
      }

      developer.log(
        "❌ Refresh API returned non-200: ${response.statusCode}",
        name: 'AuthInterceptor',
      );
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      return false;
    } catch (e) {
      developer.log("❌ Token refresh exception: $e", name: 'AuthInterceptor');
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }
}
