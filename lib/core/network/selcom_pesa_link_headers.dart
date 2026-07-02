import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';

import '../di/injection_container.dart';
import '../services/notification_service.dart';
import 'api_constants.dart';

/// Device/session headers required by [URLS.selcomPesa.sendLinkRequest].
///
/// These are sent in addition to the standard [commonHeaders] map (JWT, etc.).
Future<Map<String, String>> selcomPesaLinkRequestHeaders() async {
  final deviceInfo = DeviceInfoPlugin();
  String? intUdid;
  if (Platform.isAndroid) {
    intUdid = (await deviceInfo.androidInfo).id;
  } else if (Platform.isIOS) {
    intUdid = (await deviceInfo.iosInfo).identifierForVendor;
  }

  final pushToken = sl<NotificationService>().deviceToken.trim();
  final languageCode = Get.locale?.languageCode ?? 'en';

  return {
    Params.deviceType: Platform.isAndroid ? '1' : '2',
    if (pushToken.isNotEmpty) Params.deviceToken: pushToken,
    Params.languageCode: languageCode,
    if (intUdid != null && intUdid.isNotEmpty) Params.intUdid: intUdid,
  };
}
