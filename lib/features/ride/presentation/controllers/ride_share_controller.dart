import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_strings.dart';
import '../../domain/repositories/ride_share_repository.dart';

class RideShareController extends GetxController {
  RideShareController({
    required RideShareRepository rideShareRepository,
    this.enableRevokeLink = true,
  }) : _rideShareRepository = rideShareRepository;

  final RideShareRepository _rideShareRepository;

  final bool enableRevokeLink;

  final shareUrl = RxnString();
  final isSharing = false.obs;
  final isRevoking = false.obs;

  Future<void> shareRide(String rideId) async {
    if (rideId.trim().isEmpty) return;

    isSharing.value = true;
    final result = await _rideShareRepository.generateShareLink(rideId);
    await result.fold(
      (failure) async {
        Get.snackbar(AppStrings.share.tr, failure.message);
      },
      (link) async {
        shareUrl.value = link.shareUrl;
        await SharePlus.instance.share(
          ShareParams(
            text: 'Track my Selcom Go ride live: ${link.shareUrl}',
            subject: AppStrings.shareRideStatus.tr,
          ),
        );
      },
    );
    isSharing.value = false;
  }

  Future<void> revokeShareLink(String rideId) async {
    if (!enableRevokeLink || rideId.trim().isEmpty || isRevoking.value) return;

    isRevoking.value = true;
    final result = await _rideShareRepository.revokeShareLink(rideId);
    result.fold(
      (failure) => Get.snackbar(AppStrings.share.tr, failure.message),
      (_) {
        shareUrl.value = null;
        Get.snackbar(AppStrings.share.tr, AppStrings.done.tr);
      },
    );
    isRevoking.value = false;
  }
}
