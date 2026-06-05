import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/network/api_service.dart';

class AppInfo {
  static final AppInfo _instance = AppInfo._internal();

  factory AppInfo() {
    return _instance;
  }

  AppInfo._internal();

  Future<void> get({ApiEnvironment? debugEnvironment}) async {
    await _getPackageInfo();
    _getBuildType(debugEnvironment: debugEnvironment);
  }

  late PackageInfo _package;
  PackageInfo get package => _package;

  Future<void> _getPackageInfo() async {
    _package = await PackageInfo.fromPlatform();
  }

  late BuildType _buildType;
  BuildType get buildType => _buildType;

  late ApiEnvironment _environment;
  ApiEnvironment get environment => _environment;

  bool get isPublicVersion =>
      buildType == BuildType.LIVE &&
      ApiService.currentEnvironment == ApiEnvironment.production;

  /// It is based on [PackageNames] that are given.
  void _getBuildType({ApiEnvironment? debugEnvironment}) {
    if (kDebugMode) {
      _buildType = BuildType.TESTING;
      _environment = debugEnvironment ?? ApiEnvironment.staging;
      return;
    }

    String packageName = package.packageName;

    switch (packageName) {
      case PackageNames.androidDev || PackageNames.iosDev:
        _buildType = BuildType.TESTING;
        _environment = ApiEnvironment.staging;
        break;
      case PackageNames.androidLive || PackageNames.iosLive:
        _buildType = BuildType.LIVE;
        _environment = ApiEnvironment.production;
        break;
      default:
        _buildType = BuildType.UNKNOWN;
        _environment = ApiEnvironment.production;
        break;
    }
  }
}

enum BuildType { TESTING, LIVE, UNKNOWN }

class PackageNames {
  static const String androidDev = "com.app.dukadirect.dev";
  static const String iosDev = "com.duka.direct.dev";
  static const String androidLive = "com.app.dukadirect";
  static const String iosLive = "com.duka.direct";
}
