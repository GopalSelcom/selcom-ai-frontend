import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';

enum SelcomPesaLaunchFailureReason {
  emptyShortCode,
  noHandler,
  launchFailed,
}

class SelcomPesaLaunchResult {
  const SelcomPesaLaunchResult._({
    required this.launched,
    this.reason,
  });

  final bool launched;
  final SelcomPesaLaunchFailureReason? reason;

  factory SelcomPesaLaunchResult.success() {
    return const SelcomPesaLaunchResult._(launched: true);
  }

  factory SelcomPesaLaunchResult.failure(SelcomPesaLaunchFailureReason reason) {
    return SelcomPesaLaunchResult._(launched: false, reason: reason);
  }
}

class SelcomPesaAppLauncherService {
  SelcomPesaAppLauncherService();

  static const Duration pcodeLaunchDelay = Duration(milliseconds: 1500);

  static const String androidPackageProd = 'com.selcompesa';
  static const String androidPackageDev = 'com.selcompesa'; // com.selcombank.dev

  static const MethodChannel _androidChannel = MethodChannel(
    'com.selcom.go/selcom_pesa',
  );

  static final Uri _schemeProbe = Uri.parse('selcompesa://pcode/');

  Future<bool> isSelcomPesaInstalled() async {
    try {
      if (Platform.isAndroid) {
        final installed = await _androidChannel.invokeMethod<bool>('isInstalled');
        return installed == true;
      }

      // iOS: LSApplicationQueriesSchemes includes selcompesa — do not probe https
      // (the browser would make canLaunchUrl return true without Selcom Pesa).
      return canLaunchUrl(_schemeProbe);
    } catch (_) {
      return false;
    }
  }

  Future<SelcomPesaLaunchResult> openPcodePayment(String shortCode) async {
    final trimmed = shortCode.trim();
    if (trimmed.isEmpty) {
      return SelcomPesaLaunchResult.failure(
        SelcomPesaLaunchFailureReason.emptyShortCode,
      );
    }

    await Future<void>.delayed(pcodeLaunchDelay);

    for (final uri in _pcodeLaunchUris(trimmed)) {
      if (await _tryLaunchUri(uri)) {
        return SelcomPesaLaunchResult.success();
      }
    }

    return SelcomPesaLaunchResult.failure(
      SelcomPesaLaunchFailureReason.launchFailed,
    );
  }

  Future<bool> openDownloadPage() async {
    final uri = Uri.parse(AppConfig.selcomPesaDownloadUrl);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<Uri> _pcodeLaunchUris(String shortCode) {
    const host = AppConfig.selcomPesaDeepLinkHostDefault;
    final httpsPath = '$host/pcode/$shortCode';
    final uris = <Uri>[
      Uri.parse('https://$httpsPath'),
    ];

    if (!Platform.isAndroid) {
      return uris;
    }

    // Target Selcom Pesa directly — https handoff alone often opens the browser.
    return [
      for (final package in [androidPackageProd, androidPackageDev]) ...[
        Uri.parse(
          'intent://$httpsPath#Intent;scheme=https;package=$package;end',
        ),
        Uri.parse(
          'intent://pcode/$shortCode#Intent;scheme=selcompesa;package=$package;end',
        ),
      ],
      ...uris,
    ];
  }

  Future<bool> _tryLaunchUri(Uri uri) async {
    try {
      if (await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      )) {
        return true;
      }

      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
