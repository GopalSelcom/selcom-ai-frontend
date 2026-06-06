import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';

class SelcomPesaAppLauncherService {
  SelcomPesaAppLauncherService();

  static final Uri _schemeProbe = Uri.parse('selcompesa://');

  Future<bool> isSelcomPesaInstalled() async {
    try {
      return canLaunchUrl(_schemeProbe);
    } catch (_) {
      return false;
    }
  }

  Future<bool> openPcodePayment(String shortCode) async {
    final trimmed = shortCode.trim();
    if (trimmed.isEmpty) return false;

    final uri = Uri.parse(
      'https://${AppConfig.selcomPesaDeepLinkHost}/pcode/$trimmed',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openDownloadPage() async {
    final uri = Uri.parse(AppConfig.selcomPesaDownloadUrl);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
