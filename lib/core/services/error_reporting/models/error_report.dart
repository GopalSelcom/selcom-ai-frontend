import 'dart:convert';

class ErrorReport {
  final String id;
  final String errorKey;
  final String? customMessage;
  final String exception;
  final String stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appInfo;
  final Map<String, dynamic> userContext;
  final Map<String, dynamic> appState;
  final List<Map<String, dynamic>>? extraData;
  final String? screenshotPath;
  final List<String> logs;
  final bool isSynced;

  ErrorReport({
    required this.id,
    required this.errorKey,
    this.customMessage,
    required this.exception,
    required this.stackTrace,
    required this.timestamp,
    required this.deviceInfo,
    required this.appInfo,
    required this.userContext,
    required this.appState,
    this.extraData,
    this.screenshotPath,
    this.logs = const [],
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'error_key': errorKey,
      if (customMessage != null) 'custom_message': customMessage,
      'exception': exception,
      'stack_trace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'device': deviceInfo,
      'app': appInfo,
      'user': userContext,
      'state': appState,
      if (extraData != null) 'extra_data': extraData,
      'screenshot_path': screenshotPath,
      'logs': logs,
      'is_synced': isSynced,
    };
  }

  factory ErrorReport.fromMap(Map<String, dynamic> map) {
    return ErrorReport(
      id: map['id'],
      errorKey: map['error_key'],
      customMessage: map['custom_message'],
      exception: map['exception'],
      stackTrace: map['stack_trace'],
      timestamp: DateTime.parse(map['timestamp']),
      deviceInfo: Map<String, dynamic>.from(map['device'] ?? {}),
      appInfo: Map<String, dynamic>.from(map['app'] ?? {}),
      userContext: Map<String, dynamic>.from(map['user'] ?? {}),
      appState: Map<String, dynamic>.from(map['state'] ?? {}),
      extraData: map['extra_data'] != null
          ? List<Map<String, dynamic>>.from(map['extra_data'])
          : null,
      screenshotPath: map['screenshot_path'],
      logs: List<String>.from(map['logs'] ?? []),
      isSynced: map['is_synced'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ErrorReport.fromJson(String source) =>
      ErrorReport.fromMap(json.decode(source));

  ErrorReport copyWith({
    String? id,
    String? errorKey,
    String? customMessage,
    String? exception,
    String? stackTrace,
    DateTime? timestamp,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? appInfo,
    Map<String, dynamic>? userContext,
    Map<String, dynamic>? appState,
    List<Map<String, dynamic>>? extraData,
    String? screenshotPath,
    List<String>? logs,
    bool? isSynced,
  }) {
    return ErrorReport(
      id: id ?? this.id,
      errorKey: errorKey ?? this.errorKey,
      customMessage: customMessage ?? this.customMessage,
      exception: exception ?? this.exception,
      stackTrace: stackTrace ?? this.stackTrace,
      timestamp: timestamp ?? this.timestamp,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appInfo: appInfo ?? this.appInfo,
      userContext: userContext ?? this.userContext,
      appState: appState ?? this.appState,
      extraData: extraData ?? this.extraData,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      logs: logs ?? this.logs,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
