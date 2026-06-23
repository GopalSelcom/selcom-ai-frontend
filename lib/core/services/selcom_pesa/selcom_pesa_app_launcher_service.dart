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

  static final Uri _schemeProbe = Uri.parse('selcompesa://');

  Future<bool> isSelcomPesaInstalled() async {
    try {
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

    final uri = Uri.parse(
      'https://${AppConfig.selcomPesaDeepLinkHost}/pcode/$trimmed',
    );

    await Future<void>.delayed(pcodeLaunchDelay);

    try {
      if (!await canLaunchUrl(uri)) {
        return SelcomPesaLaunchResult.failure(
          SelcomPesaLaunchFailureReason.noHandler,
        );
      }

      final launchedInApp = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (launchedInApp) {
        return SelcomPesaLaunchResult.success();
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return SelcomPesaLaunchResult.success();
      }

      return SelcomPesaLaunchResult.failure(
        SelcomPesaLaunchFailureReason.launchFailed,
      );
    } catch (_) {
      return SelcomPesaLaunchResult.failure(
        SelcomPesaLaunchFailureReason.launchFailed,
      );
    }
  }

  Future<bool> openDownloadPage() async {
    final uri = Uri.parse(AppConfig.selcomPesaDownloadUrl);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
