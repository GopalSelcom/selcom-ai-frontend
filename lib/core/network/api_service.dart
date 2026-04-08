import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:http_parser/http_parser.dart';

import 'failed_request_queue.dart';
import 'retry_manager.dart';
import '../../shared/utils/app_dialogs.dart';

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
      debugPrint(
        "🌐 No Internet → ${client.options.baseUrl}${request.endpoint}",
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
    final Map<String, dynamic> finalHeaders = await _commonHeadersBuilder();
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
      debugPrint("💥 [API EXCEPTION] $fullUrl | $e");
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

    debugPrint("📦 Multipart files count: ${formData.files.length}");

    final response = await dioInstance.request(
      endpoint,
      data: formData,
      queryParameters: request.queryParams,
      options: Options(
        method: 'POST',
        headers: finalHeaders,
      ),
      onSendProgress: (sent, total) {
        if (kDebugMode) {
          int percentage = ((sent / total) * 100).toInt();
          debugPrint("📤 Upload Progress: $percentage% ($sent/$total bytes)");
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
    debugPrint(
      "🚀 REQUEST >> ${request.method.name.toUpperCase()} $fullUrl",
    );
    debugPrint("$fullUrl [Headers] ${_safeJsonEncode(headers)}");
    debugPrint("$fullUrl [Query] ${_safeJsonEncode(request.queryParams)}");
    debugPrint("$fullUrl [Body] ${_safeJsonEncode(body)}");
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
    debugPrint(
      "$prefix >> $fullUrl | ${statusCode ?? 'N/A'} | ${duration}ms",
    );
    if (isError && errorMessage != null) {
      debugPrint("$fullUrl Message: $errorMessage");
    }
    debugPrint("$fullUrl [Response] ${_safeJsonEncode(data)}");
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
          message = e.response?.data['message'] ?? 'Bad response from server';
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
      debugPrint("⏳ Server slow response (receive timeout)");

      if (request.errorPresentationType == ErrorPresentationType.dialog) {
        AppDialogs.showErrorDialog(
          title: 'Timeout',
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
      debugPrint("📥 Queueing failed request: ${request.endpoint}");
      final completer = Completer<Response>();
      final added = await FailedRequestQueue.instance.add(request, completer);

      if (added) {
        if (!RetryManager.instance.isPopupShowing) {
          debugPrint("📱 Showing retry popup");
          unawaited(RetryManager.instance.showRetryPopup());
        }
      }

      return completer.future;
    }

    if (request.errorPresentationType == ErrorPresentationType.dialog) {
      AppDialogs.showErrorDialog(message: message);
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

  // ── Session Expired Popup ──

  void showLogoutPopup() {
    Get.defaultDialog(
      title: 'Session Expired',
      middleText: 'Your session has expired. Please login again to continue.',
      textConfirm: 'Login',
      barrierDismissible: false,
      onConfirm: () async {
        // Clear tokens
        const secureStorage = FlutterSecureStorage();
        await secureStorage.delete(key: 'authorization_token');
        await secureStorage.delete(key: 'access_token');
        await secureStorage.delete(key: 'refresh_token');
        Get.back();
        // Navigate to login - adjust route as needed
        Get.offAllNamed('/login');
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Auth Interceptor (Token Refresh + 401 Handling)
// ─────────────────────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final ApiService apiService;
  static const _secureStorage = FlutterSecureStorage();

  // Static variables for global refresh coordination
  static Completer<bool>? _refreshCompleter;
  static bool _isRefreshing = false;
  static bool isLoggingOutDueToAuthFailure = false;

  AuthInterceptor({required this.apiService});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.read(key: 'authorization_token');

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
    debugPrint("dioError => ${err.error}");
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for requests that should skip auth
    final skipAuth = err.requestOptions.headers['skip-auth-interceptor'];
    if (skipAuth == 'true') {
      debugPrint("⏭️ Skipping auth interceptor for this request");
      return handler.next(err);
    }

    // Prevent infinite retry loops
    if (err.requestOptions.headers['retry-after-refresh'] == 'true') {
      debugPrint("❌ Request already retried after refresh, logging out");
      apiService.showLogoutPopup();
      return handler.next(err);
    }

    debugPrint("🔄 401 Unauthorized detected, attempting token refresh...");

    try {
      final refreshSuccess = await _handleTokenRefresh();

      if (refreshSuccess) {
        debugPrint("✅ Token refreshed successfully, retrying request");

        final newToken = await _secureStorage.read(key: 'authorization_token');

        // Update headers with new token
        final updatedHeaders = Map<String, dynamic>.from(
          err.requestOptions.headers,
        );

        updatedHeaders['Authorization'] = 'Bearer $newToken';
        updatedHeaders['retry-after-refresh'] = 'true';

        // Also update access_token if present
        if (updatedHeaders.containsKey('access_token')) {
          final newAccessToken = await _secureStorage.read(key: 'access_token');
          updatedHeaders['access_token'] = newAccessToken;
        }

        debugPrint("✅ Headers updated with new token for retry");

        // Create new RequestOptions with updated token
        final newOptions = err.requestOptions.copyWith(headers: updatedHeaders);

        // Retry the request
        try {
          debugPrint("🔄 Retrying request to: ${newOptions.uri.toString()}");

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
          debugPrint("✅ Retry succeeded with status: ${response.statusCode}");
          return handler.resolve(response);
        } catch (retryError) {
          debugPrint("❌ Retry request failed: $retryError");

          // If retry also fails with 401 — session truly expired
          if (retryError is DioException &&
              retryError.response?.statusCode == 401) {
            debugPrint(
              "❌ Retry failed with 401, token refresh ineffective - logging out",
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
        debugPrint("❌ Token refresh failed, logging out");

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
      debugPrint("💥 Unexpected error during refresh: $e");

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
      debugPrint("⏳ Token refresh already in progress, waiting...");
      return await _refreshCompleter!.future;
    }

    // Start new refresh process
    debugPrint("🔄 Starting token refresh");
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint("❌ No refresh token available");
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
        final newAccessToken = data['authorization_token'] ?? data['access_token'];
        final newRefreshToken = data['refresh_token'];

        if (newAccessToken != null) {
          await _secureStorage.write(
            key: 'authorization_token',
            value: newAccessToken,
          );
        }
        if (data['access_token'] != null) {
          await _secureStorage.write(
            key: 'access_token',
            value: data['access_token'],
          );
        }
        if (newRefreshToken != null) {
          await _secureStorage.write(
            key: 'refresh_token',
            value: newRefreshToken,
          );
        }

        debugPrint("✅ Tokens refreshed and saved");

        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(true);
        }
        return true;
      }

      debugPrint("❌ Refresh API returned non-200: ${response.statusCode}");
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      return false;
    } catch (e) {
      debugPrint("❌ Token refresh exception: $e");
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
