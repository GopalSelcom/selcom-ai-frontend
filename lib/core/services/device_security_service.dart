import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:safe_device/safe_device.dart';
import 'package:safe_device/safe_device_config.dart';

import '../routes/app_routes.dart';

/// Why the app was blocked (shown on the security screen).
enum DeviceSecurityIssue {
  /// Fake GPS / mock location provider is feeding a mocked fix.
  mockLocation,

  /// Android Developer Options are turned on.
  developerOptions,

  /// Device is rooted (Android) or jailbroken (iOS).
  jailbreakOrRoot,

  /// Spoofed movement path (mocked GPS used as route injection).
  routeSpoofing,
}

/// Outcome of one integrity pass: blocked or allowed.
class DeviceSecurityVerdict {
  const DeviceSecurityVerdict._({
    required this.isBlocked,
    this.issue,
  });

  /// Device passed checks — app may continue.
  const DeviceSecurityVerdict.ok() : this._(isBlocked: false);

  /// Device failed a check — [issue] drives the block-screen copy.
  const DeviceSecurityVerdict.blocked(DeviceSecurityIssue issue)
      : this._(isBlocked: true, issue: issue);

  /// `true` when the app must stop and show the block screen.
  final bool isBlocked;

  /// Which check failed; `null` when [isBlocked] is false.
  final DeviceSecurityIssue? issue;
}

/// Release-only device integrity gate (mock GPS, developer options, root/jailbreak).
///
/// Location checks never request permission or open the system
/// "improve location accuracy" dialog — they only read an existing last-known fix.
class DeviceSecurityService {
  DeviceSecurityService._();

  static final DeviceSecurityService instance = DeviceSecurityService._();

  /// Master switch: `true` only in release builds ([kReleaseMode]).
  /// When `false` (debug), all checks are skipped and the app never blocks.
  static const bool isDeviceSecurityEnabled = kReleaseMode;

  /// How often [startMonitoring] re-runs [evaluate] while the app is open.
  static const Duration _monitorInterval = Duration(seconds: 8);

  /// Last result from [evaluate] (used by the block screen / guards).
  DeviceSecurityVerdict _lastVerdict = const DeviceSecurityVerdict.ok();

  /// Periodic timer started by [startMonitoring]; cancelled by [stopMonitoring].
  Timer? _monitorTimer;

  /// Prevents overlapping [Get.offAllNamed] calls to the block screen.
  bool _isNavigatingToBlock = false;

  /// Ensures [SafeDevice.init] runs once (mock GPS auto-check disabled).
  bool _safeDeviceConfigured = false;

  /// Shares one in-flight [evaluate] so Try again / monitor do not stack work.
  Completer<DeviceSecurityVerdict>? _evaluateInFlight;

  /// Latest cached verdict (synchronous).
  DeviceSecurityVerdict get lastVerdict => _lastVerdict;

  /// Convenience: same as [lastVerdict.isBlocked].
  bool get isBlocked => _lastVerdict.isBlocked;

  /// Runs root / developer-options / mock-location checks.
  /// Concurrent callers await the same in-flight result.
  Future<DeviceSecurityVerdict> evaluate() async {
    if (!isDeviceSecurityEnabled) {
      _lastVerdict = const DeviceSecurityVerdict.ok();
      return _lastVerdict;
    }

    final inFlight = _evaluateInFlight;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<DeviceSecurityVerdict>();
    _evaluateInFlight = completer;

    try {
      final verdict = await _evaluateOnce();
      completer.complete(verdict);
      return verdict;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _evaluateInFlight = null;
    }
  }

  /// Single evaluation body used by [evaluate].
  Future<DeviceSecurityVerdict> _evaluateOnce() async {
    _ensureSafeDeviceConfigured();

    try {
      // Root (Android) / jailbreak (iOS).
      final isJailBroken = await SafeDevice.isJailBroken;
      if (isJailBroken) {
        return _cache(const DeviceSecurityVerdict.blocked(
          DeviceSecurityIssue.jailbreakOrRoot,
        ));
      }

      // Android-only: Developer Options toggle.
      if (Platform.isAndroid) {
        final isDevMode = await SafeDevice.isDevelopmentModeEnable;
        if (isDevMode) {
          return _cache(const DeviceSecurityVerdict.blocked(
            DeviceSecurityIssue.developerOptions,
          ));
        }
      }

      // Mock GPS / spoofed route — last-known only (no location prompts).
      final mockedIssue = await _mockedLocationIssueIfAny();
      if (mockedIssue != null) {
        return _cache(DeviceSecurityVerdict.blocked(mockedIssue));
      }
    } catch (_) {
      // Fail open if a plugin throws — do not brick the user.
    }

    return _cache(const DeviceSecurityVerdict.ok());
  }

  /// Block-screen "Try again": re-run checks; if clear, return to splash.
  /// Returns `true` when the block was cleared.
  Future<bool> recheckAndResume() async {
    if (!isDeviceSecurityEnabled) {
      _lastVerdict = const DeviceSecurityVerdict.ok();
      Get.offAllNamed(AppRoutes.splash);
      return true;
    }

    final verdict = await evaluate();
    if (verdict.isBlocked) return false;

    stopMonitoring();
    Get.offAllNamed(AppRoutes.splash);
    return true;
  }

  /// Splash entry: evaluate once and navigate to the block screen if needed.
  /// Returns `true` when the user was sent to the block screen.
  Future<bool> enforceOrBlock() async {
    if (!isDeviceSecurityEnabled) return false;
    final verdict = await evaluate();
    if (!verdict.isBlocked) return false;
    _navigateToBlocked(verdict);
    return true;
  }

  /// Starts periodic [evaluate] after the gate has passed.
  /// No-op on the block screen or when [isDeviceSecurityEnabled] is false.
  void startMonitoring() {
    if (!isDeviceSecurityEnabled) return;
    if (Get.currentRoute == AppRoutes.deviceSecurityBlocked) return;
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(_monitorInterval, (_) {
      unawaited(_monitorTick());
    });
  }

  /// Stops the periodic integrity timer.
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// One monitor pass; navigates to the block screen if a check fails.
  Future<void> _monitorTick() async {
    if (!isDeviceSecurityEnabled) return;
    if (_isNavigatingToBlock) return;
    if (Get.currentRoute == AppRoutes.deviceSecurityBlocked) return;

    final verdict = await evaluate();
    if (verdict.isBlocked) {
      _navigateToBlocked(verdict);
    }
  }

  /// Replaces the stack with the themed security block screen.
  void _navigateToBlocked(DeviceSecurityVerdict verdict) {
    if (_isNavigatingToBlock) return;
    if (Get.currentRoute == AppRoutes.deviceSecurityBlocked) return;

    _isNavigatingToBlock = true;
    stopMonitoring();
    try {
      Get.offAllNamed(
        AppRoutes.deviceSecurityBlocked,
        arguments: verdict.issue,
      );
    } finally {
      _isNavigatingToBlock = false;
    }
  }

  /// Stores and returns [verdict] as the latest result.
  DeviceSecurityVerdict _cache(DeviceSecurityVerdict verdict) {
    _lastVerdict = verdict;
    return verdict;
  }

  /// Configures SafeDevice once: disables its built-in mock-location listener
  /// (that path uses high-accuracy GPS and can show location-settings dialogs).
  void _ensureSafeDeviceConfigured() {
    if (_safeDeviceConfigured) return;
    SafeDevice.init(
      const SafeDeviceConfig(mockLocationCheckEnabled: false),
    );
    _safeDeviceConfigured = true;
  }

  /// If permission is already granted and last-known GPS is mocked, returns
  /// [DeviceSecurityIssue.mockLocation]; otherwise `null` (no prompts).
  Future<DeviceSecurityIssue?> _mockedLocationIssueIfAny() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final last = await Geolocator.getLastKnownPosition();
      if (last == null || !last.isMocked) return null;

      return DeviceSecurityIssue.mockLocation;
    } catch (_) {
      return null;
    }
  }
}
