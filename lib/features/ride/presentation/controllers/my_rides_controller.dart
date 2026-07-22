import 'package:get/get.dart';
import 'package:selcom_rides_frontend/features/ride/data/models/ride_history_model.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/mid_ride_cancel_navigation.dart';
import '../../../../shared/utils/ride_active_navigation.dart';
import '../../domain/usecases/ride_usecase.dart';
import '../screens/ride_details_screen.dart';
import 'ride_details_controller.dart';

class MyRidesController extends GetxController {
  final RideUseCase rideUseCase;

  MyRidesController({required this.rideUseCase});

  final pastRides = <Ride>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
  final isOpeningRide = false.obs;
  final _page = 1.obs;
  static const int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchPastRides(isLoader: true);
  }

  Future<void> fetchPastRides({bool? isLoader = false}) async {
    try {
      _page.value = 1;
      hasMoreData.value = true;
      isLoading.value = isLoader ?? true;
      final result = await rideUseCase.getRideHistory(
        page: _page.value,
        limit: _limit,
      );
      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (rides) {
          pastRides.assignAll((rides?.data?.rides ?? []));
          hasMoreData.value =
              (rides?.data?.pagination?.page ?? 1) <
              (rides?.data?.pagination?.totalPages ?? 1);
        },
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: AppStrings.anUnexpectedErrorOccurred.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Always fetch latest ride details first, then route the tap behavior.
  /// - Ongoing (active) ride statuses -> navigate like Home active ride
  /// - Terminal statuses -> open details screen
  Future<void> onRideTap(Ride ride) async {
    if (isOpeningRide.value) return;
    final rideId = ride.id ?? '';
    if (rideId.isEmpty) return;
    isOpeningRide.value = true;
    try {
      final result = await rideUseCase.getRideDetails(rideId);
      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (freshRide) {
          if (rideNeedsMidRideCancelScreen(freshRide)) {
            final block = freshRide.midRideCancel;
            if (block != null) {
              showMidRideDriverCancelledDialog(
                rideId: freshRide.id,
                cancel: block,
                navigateHomeOnDismiss: false,
              );
              return;
            }
          }
          if (rideStatusIsOngoingActive(freshRide.status)) {
            // Caller already called getRideDetails — live screens must not fetch again.
            navigateToOngoingRide(freshRide, skipInitialRideDetailsFetch: true);
            return;
          }
          // My Rides entry must always use non-completion mode.
          // This keeps screen title/layout/back behavior unchanged here.
          if (Get.isRegistered<RideDetailsController>()) {
            Get.delete<RideDetailsController>();
          }
          // onRideTap already fetched freshRide — skip controller init reload.
          Get.put(
            RideDetailsController(
              ride: freshRide,
              openedFromCompletionFlow: false,
              refreshOnInit: false,
            ),
          );
          Get.to(
            () => RideDetailsScreen(
              ride: freshRide,
              openedFromCompletionFlow: false,
              refreshOnInit: false,
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: AppStrings.anUnexpectedErrorOccurred.tr,
      );
    } finally {
      isOpeningRide.value = false;
    }
  }

  Future<void> loadMorePastRides() async {
    if (isLoading.value || isLoadingMore.value || !hasMoreData.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      final nextPage = _page.value + 1;
      final result = await rideUseCase.getRideHistory(
        page: nextPage,
        limit: _limit,
      );

      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (rides) {
          if ((rides?.data?.rides ?? []).isEmpty) {
            hasMoreData.value = false;
            return;
          }
          pastRides.addAll((rides?.data?.rides ?? []));
          _page.value = nextPage;
          hasMoreData.value =
              (rides?.data?.pagination?.page ?? 1) <
              (rides?.data?.pagination?.totalPages ?? 1);
        },
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: AppStrings.anUnexpectedErrorOccurred.tr,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }
}
