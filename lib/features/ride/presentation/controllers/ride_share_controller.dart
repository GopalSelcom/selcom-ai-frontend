import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/usecases/generate_share_link_use_case.dart';
import '../../domain/usecases/revoke_share_link_use_case.dart';

class RideShareController extends GetxController {
  RideShareController({
    required GenerateShareLinkUseCase generateShareLinkUseCase,
    required RevokeShareLinkUseCase revokeShareLinkUseCase,
    this.enableRevokeLink = true,
  }) : _generateShareLinkUseCase = generateShareLinkUseCase,
       _revokeShareLinkUseCase = revokeShareLinkUseCase;

  final GenerateShareLinkUseCase _generateShareLinkUseCase;
  final RevokeShareLinkUseCase _revokeShareLinkUseCase;

  final bool enableRevokeLink;

  final shareUrl = RxnString();
  final isSharing = false.obs;
  final isRevoking = false.obs;

  Future<void> shareRide(String rideId) async {
    if (rideId.trim().isEmpty) return;

    isSharing.value = true;
    final result = await _generateShareLinkUseCase(rideId);
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
    final result = await _revokeShareLinkUseCase(rideId);
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
