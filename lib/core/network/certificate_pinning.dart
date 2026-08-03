import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:certificate_pinning_httpclient/certificate_pinning_httpclient.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get/get.dart' hide Response;
import 'package:package_info_plus/package_info_plus.dart';

import '../../main.dart';
import '../../shared/utils/app_dialogs.dart';
import '../config/app_config.dart';
import '../localization/app_strings.dart';
import '../utils/app_logger.dart';
import 'connectivity_probe.dart';
import 'encryption.dart';

/// Dynamic SPKI certificate pinning (fetch pin at startup, attach to Dio).
///
/// Matches Duka Direct's CertificatePinning flow, adapted for Dio via
/// [IOHttpClientAdapter] + [CertificatePinningHttpClient].
class CertificatePinning {
  CertificatePinning._internal();

  static final CertificatePinning instance = CertificatePinning._internal();

  /// Optional static pin for local testingMode cycles only — never production.
  static const String _testingFallbackPin =
      'iy2yBocC3ymn6LjKnzQ1HhQT4DRJtV8iBmRIZntD3P4=';

  static const String _aesKey = 'QdptEEvDW7UKhXjAq1nm2BNSft09Vdlw';
  static const String _aesIv = 'pp1VI0bmpjL0FQ6z';

  String _key = '';
  HttpClient? _pinnedHttpClient;
  int _testingInitCount = 0;

  /// When true, uses a hardcoded pin for the first few inits (local QA only).
  bool get testingMode => false;

  bool get hasPin => _key.isNotEmpty;

  /// Fetches the latest pin (unless [isVAPTBuild]) and rebuilds the pinned client.
  ///
  /// Callers should then invoke [ApiService.applyCertificatePinning].
  Future<void> init({bool fromRetry = false}) async {
    if (isVAPTBuild) {
      AppLogger.d(
        'VAPT build — skipping certificate pinning',
        tag: 'CertificatePinning',
      );
      _key = '';
      _pinnedHttpClient = null;
      return;
    }

    if (testingMode) {
      _testingInitCount++;
      if (_testingInitCount > 3) {
        _key = await _getCertificateKey(fromRetry: fromRetry);
      } else {
        _key = _testingFallbackPin;
      }
    } else {
      _key = await _getCertificateKey(fromRetry: fromRetry);
    }

    _key = _key.replaceAll('\n', '').trim();
    _rebuildPinnedClient();
  }

  /// Creates / refreshes the pinned [HttpClient] from the current pin key.
  HttpClient? createPinnedHttpClient() {
    if (_key.isEmpty) return null;
    _rebuildPinnedClient();
    return _pinnedHttpClient;
  }

  HttpClient? get pinnedHttpClient => _pinnedHttpClient;

  void _rebuildPinnedClient() {
    if (_key.isEmpty) {
      _pinnedHttpClient = null;
      return;
    }
    try {
      _pinnedHttpClient?.close(force: true);
    } catch (_) {}
    _pinnedHttpClient = CertificatePinningHttpClient([_key]);
  }

  Future<String> _getCertificateKey({bool fromRetry = false}) async {
    try {
      var packageName = (await PackageInfo.fromPlatform()).packageName;
      if (testingMode) {
        packageName = 'com.selcom.go';
      }

      final encryptedPackageName = onlyAesEncryption(
        data: packageName,
        keyInString: _aesKey,
        ivInString: _aesIv,
      );

      final url = AppConfig.certificatePinningUrl;
      if (url.isEmpty) {
        AppLogger.e(
          'CERTIFICATE_PINNING_URL is empty',
          tag: 'CertificatePinning',
        );
        return await _handleFetchFailure(fromRetry: fromRetry);
      }

      AppLogger.d(
        '$url | method: post | package: $packageName',
        tag: 'CertificatePinning',
      );

      final isInternetAvailable =
          await ConnectivityProbe.instance.probeInternetConnection();
      if (!isInternetAvailable) {
        if (fromRetry) return '';
        await _showRetryDialog(
          title: AppStrings.connectionError.tr,
          message: AppStrings.noInternetConnection.tr,
        );
        return _getCertificateKey(fromRetry: true);
      }

      late final Response<dynamic> response;
      try {
        // Unpinned Dio — pin fetch must not depend on the pin itself.
        response = await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.plain,
          ),
        ).post<dynamic>(
          url,
          data: {'package_id': encryptedPackageName},
        );
      } catch (e) {
        AppLogger.e('Pin fetch request failed: $e', tag: 'CertificatePinning');
        return await _handleFetchFailure(fromRetry: fromRetry);
      }

      final encryptedResponse = response.data?.toString() ?? '';
      if (encryptedResponse.isEmpty) {
        return await _handleFetchFailure(fromRetry: fromRetry);
      }

      final decryptedResponse = aesDecrypt(
        data: encryptedResponse,
        keyInString: _aesKey,
        ivInString: _aesIv,
      );

      if (decryptedResponse.isEmpty) {
        return await _handleFetchFailure(fromRetry: fromRetry);
      }

      final decoded = json.decode(decryptedResponse);
      final certificateKey = (decoded is Map && decoded['data'] != null)
          ? decoded['data'].toString()
          : '';

      AppLogger.d(
        'Pin key fetched (length=${certificateKey.length})',
        tag: 'CertificatePinning',
      );
      return certificateKey;
    } catch (e) {
      AppLogger.e('Pin fetch parse failed: $e', tag: 'CertificatePinning');
      return await _handleFetchFailure(fromRetry: fromRetry);
    }
  }

  Future<String> _handleFetchFailure({required bool fromRetry}) async {
    if (fromRetry) return '';
    await _showRetryDialog(
      title: AppStrings.error.tr,
      message: AppStrings.somethingWentWrongPleaseTryAgain.tr,
    );
    return _getCertificateKey(fromRetry: true);
  }

  Future<void> _showRetryDialog({
    required String title,
    required String message,
  }) async {
    // Wait until GetX has a context (splash / first frame).
    for (var i = 0; i < 50 && Get.context == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (Get.context == null) return;

    final completer = Completer<void>();
    AppDialogs.showErrorDialog(
      title: title,
      message: message,
      onConfirm: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }
}

/// Attaches [CertificatePinningHttpClient] to a Dio instance.
void attachPinnedHttpClientAdapter(Dio dio, HttpClient pinnedClient) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => pinnedClient,
  );
}

/// Resets Dio to the platform default (unpinned) HttpClient adapter.
void attachDefaultHttpClientAdapter(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient(),
  );
}
