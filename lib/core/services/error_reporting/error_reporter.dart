import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../network/api_service.dart';
import '../../network/network_connectivity_service.dart';
import '../storage_service.dart';
import '../../config/app_config.dart';
import '../../data/models/user_model.dart';
import 'models/error_report.dart';
import 'models/error_constants.dart';

class ErrorReporter {
  static final ErrorReporter instance = ErrorReporter._();
  ErrorReporter._();

  final _screenshotController = ScreenshotController();
  ScreenshotController get screenshotController => _screenshotController;

  final _connectivity = NetworkConnectivityService.instance;

  bool _isSyncing = false;
  final _uuid = const Uuid();
  final DateTime _startTime = DateTime.now();

  // Initialization safety
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get _waitUntilInitialized => _initCompleter.future;

  // To prevent flooding: last combined signature (error + message)
  String? _lastErrorSignature;
  DateTime? _lastErrorTime;

  // Rolling buffer for network history (max 20)
  final List<String> _logsBuffer = [];
  final int _maxLogsSize = 20;

  static const String _boxName = 'error_reports_box';
  static const String _reportsKey = 'pending_reports';

  /// Initialize the reporter
  Future<void> init() async {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        // We use Map storage for simplicity instead of registering custom adapters
      }

      await Hive.initFlutter();
      await Hive.openBox(_boxName);

      _connectivity.connectivityStream.listen((isOnline) {
        if (isOnline) {
          sync();
        }
      });

      debugPrint("🚨 ErrorReporter initialized");
      sync();
    } catch (e) {
      debugPrint("🚨 ErrorReporter initialization failed: $e");
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  /// Add a log entry to the history buffer
  void addLog(String log, {String? tag}) {
    if (_logsBuffer.length >= _maxLogsSize) {
      _logsBuffer.removeAt(0);
    }
    final prefix = tag != null ? "[$tag] " : "";
    _logsBuffer.add("[${DateTime.now().toIso8601String()}] $prefix$log");
  }

  /// Main method to report an error
  Future<void> report({
    required dynamic error,
    StackTrace? stackTrace,
    String? customMessage,
    String? errorKey,
    List<Map<String, dynamic>>? extraData,
    bool fatal = false,
  }) async {
    try {
      final errorStr = error.toString();
      final signature = "$errorStr|$customMessage";

      // De-duplication logic (60 seconds for identical signature)
      if (_lastErrorSignature == signature &&
          _lastErrorTime != null &&
          DateTime.now().difference(_lastErrorTime!) <
              const Duration(seconds: 60)) {
        return;
      }

      _lastErrorSignature = signature;
      _lastErrorTime = DateTime.now();

      await _waitUntilInitialized.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            debugPrint("🚨 ErrorReporter: Init timeout, proceeding anyway"),
      );

      final id = _uuid.v4();
      debugPrint("🚨 ErrorReporter: Capturing error report $id");

      // 1. Capture Screenshot
      String? screenshotPath;
      try {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/error_screenshot_$id.png';
        final Uint8List? imageBytes = await _screenshotController.capture(
          pixelRatio: 1.5,
          delay: const Duration(milliseconds: 100),
        );

        if (imageBytes != null) {
          final file = File(path);
          await file.writeAsBytes(imageBytes);
          screenshotPath = path;
        }
      } catch (e) {
        debugPrint("🚨 ErrorReporter: Failed to capture screenshot: $e");
      }

      // 2. Gather Context
      final report = ErrorReport(
        id: id,
        errorKey: errorKey ?? _deriveErrorKey(error),
        customMessage: customMessage,
        exception: errorStr,
        stackTrace: stackTrace?.toString() ?? StackTrace.current.toString(),
        timestamp: DateTime.now(),
        deviceInfo: await _getDeviceInfo(),
        appInfo: await _getAppInfo(),
        userContext: await _getUserContext(),
        appState: _getAppState(),
        extraData: extraData,
        screenshotPath: screenshotPath,
        logs: List<String>.from(_logsBuffer),
      );

      // 3. Save to Local Storage (Hive)
      await _saveReportLocally(report);

      // 4. Mirror to Crashlytics
      try {
        if (!kIsWeb && Firebase.apps.isNotEmpty) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: customMessage ?? "App Error",
            fatal: fatal,
            information: [
              "ErrorKey: ${report.errorKey}",
              "Route: ${Get.currentRoute}",
            ],
            printDetails: false,
          );
        }
      } catch (e) {
        debugPrint("ErrorReporter: Crashlytics mirroring failed: $e");
      }

      // 5. Trigger Sync
      sync();
    } catch (e) {
      debugPrint("🚨 ErrorReporter critical failure: $e");
    }
  }

  Future<void> sync() async {
    if (_isSyncing || !_connectivity.isOnline) return;
    _isSyncing = true;

    try {
      final pendingReports = await _getPendingReports();
      if (pendingReports.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (var report in pendingReports) {
        final success = await _uploadReport(report);
        if (success) {
          await _deleteReportLocally(report);
        } else {
          debugPrint("🚨 ErrorReporter: Upload failed for ${report.id}");
          continue;
        }
      }
    } catch (e) {
      debugPrint("🚨 ErrorReporter: Sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _uploadReport(ErrorReport report) async {
    try {
      final String errorBaseUrl = AppConfig.environment == Environment.prod
          ? 'https://app2.duka.direct'
          : 'https://dukastaging.selcom.dev:7443';

      final request = ApiRequest(
        endpoint: "report-error",
        method: ApiMethod.multipart,
        customBaseUrl: errorBaseUrl,
        skipAuthInterceptor: true,
        body: {
          "error_key": report.errorKey,
          if (report.customMessage != null)
            "custom_message": report.customMessage,
          "exception": report.exception,
          "stack_trace": report.stackTrace,
          "timestamp": report.timestamp.toIso8601String(),
          "device": jsonEncode(report.deviceInfo),
          "app": jsonEncode(report.appInfo),
          "user": jsonEncode(report.userContext),
          "state": jsonEncode(report.appState),
          if (report.extraData != null)
            "extra_data": jsonEncode(report.extraData),
          "logs": report.logs.join("\n"),
        },
        multipartFiles:
            report.screenshotPath != null &&
                File(report.screenshotPath!).existsSync()
            ? [
                LocalMultipartFile(
                  name: "screenshot",
                  path: report.screenshotPath!,
                ),
              ]
            : null,
      );

      final response = await ApiService().call(request: request);
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      debugPrint("🚨 ErrorReporter: Upload failed: $e");
      return false;
    }
  }

  // --- Hive Persistence ---

  Future<void> _saveReportLocally(ErrorReport report) async {
    final box = Hive.box(_boxName);
    final List<dynamic> rawReports = box.get(_reportsKey, defaultValue: []);
    final reports = List<Map<String, dynamic>>.from(rawReports);

    reports.add(report.toMap());
    await box.put(_reportsKey, reports);
  }

  Future<List<ErrorReport>> _getPendingReports() async {
    final box = Hive.box(_boxName);
    final List<dynamic> rawReports = box.get(_reportsKey, defaultValue: []);

    return rawReports
        .map((e) => ErrorReport.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _deleteReportLocally(ErrorReport report) async {
    final box = Hive.box(_boxName);
    final List<dynamic> rawReports = box.get(_reportsKey, defaultValue: []);
    final reports = List<Map<String, dynamic>>.from(rawReports);

    reports.removeWhere((e) => e['id'] == report.id);
    await box.put(_reportsKey, reports);

    if (report.screenshotPath != null) {
      final file = File(report.screenshotPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  // --- Context Helpers ---

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final devicePlugin = DeviceInfoPlugin();
    final Map<String, dynamic> data = {};

    if (Platform.isAndroid) {
      final androidInfo = await devicePlugin.androidInfo;
      data.addAll({
        "platform": "android",
        "model": androidInfo.model,
        "brand": androidInfo.brand,
        "version": androidInfo.version.release,
        "sdk": androidInfo.version.sdkInt,
        "manufacturer": androidInfo.manufacturer,
        "is_physical": androidInfo.isPhysicalDevice,
      });
    } else if (Platform.isIOS) {
      final iosInfo = await devicePlugin.iosInfo;
      data.addAll({
        "platform": "ios",
        "name": iosInfo.name,
        "system": iosInfo.systemName,
        "version": iosInfo.systemVersion,
        "model": iosInfo.model,
        "is_physical": iosInfo.isPhysicalDevice,
      });
    }
    return data;
  }

  Future<Map<String, dynamic>> _getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return {
      "version": info.version,
      "build": info.buildNumber,
      "package": info.packageName,
    };
  }

  Future<Map<String, dynamic>> _getUserContext() async {
    try {
      final data = await StorageService().read(StorageKeys.user);
      if (data != null) {
        final user = UserModel.fromJson(jsonDecode(data));
        return {
          "id": user.id.toString(),
          "name": user.name ?? "Guest User",
          "phone": user.mobileNumber ?? "N/A",
        };
      }
    } catch (_) {}
    return {"id": "guest", "name": "Guest User", "phone": "N/A"};
  }

  Map<String, dynamic> _getAppState() {
    final uptime = DateTime.now().difference(_startTime);
    return {
      "theme": Get.isDarkMode ? "dark" : "light",
      "locale": Get.locale?.toString(),
      "env": AppConfig.environment.toString(),
      "current_route": Get.currentRoute,
      "uptime":
          "${uptime.inHours}h ${uptime.inMinutes % 60}m ${uptime.inSeconds % 60}s",
      "is_online": _connectivity.isOnline,
    };
  }

  String _deriveErrorKey(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return ErrorKeys.apiTimeout;
      }
      return ErrorKeys.logicError;
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) return ErrorKeys.apiTimeout;
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('storage') ||
        errorString.contains('camera') ||
        errorString.contains('location')) {
      return ErrorKeys.permissionError;
    }
    if (errorString.contains('render') ||
        errorString.contains('overflow') ||
        errorString.contains('widget')) {
      return ErrorKeys.uiError;
    }
    if (errorString.contains('crash') ||
        errorString.contains('fatal') ||
        errorString.contains('stack overflow')) {
      return ErrorKeys.crash;
    }

    return ErrorKeys.exception;
  }
}
