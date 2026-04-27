import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/ride_active_navigation.dart';
import '../../domain/usecases/ride_usecase.dart';
import '../screens/ride_details_screen.dart';
import 'ride_details_controller.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';

class MyRidesController extends GetxController {
  final RideUseCase rideUseCase;

  MyRidesController({required this.rideUseCase});

  final pastRides = <RideModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
  final isOpeningRide = false.obs;
  final _page = 1.obs;
  static const int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchPastRides();
  }

  Future<void> fetchPastRides() async {
    try {
      _page.value = 1;
      hasMoreData.value = true;
      isLoading.value = true;
      final result = await rideUseCase.getRideHistory(
        page: _page.value,
        limit: _limit,
      );
      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (rides) {
          pastRides.assignAll(rides);
          hasMoreData.value = rides.length >= _limit;
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
  Future<void> onRideTap(RideModel ride) async {
    if (isOpeningRide.value) return;
    isOpeningRide.value = true;
    try {
      final result = await rideUseCase.getRideDetails(ride.id);
      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (freshRide) {
          if (rideStatusIsOngoingActive(freshRide.status)) {
            navigateToDriverAcceptedForRide(freshRide);
            return;
          }
          if (Get.isRegistered<RideDetailsController>()) {
            Get.delete<RideDetailsController>();
          }
          Get.put(RideDetailsController(ride: freshRide));
          Get.to(() => RideDetailsScreen(ride: freshRide));
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
          if (rides.isEmpty) {
            hasMoreData.value = false;
            return;
          }
          pastRides.addAll(rides);
          _page.value = nextPage;
          hasMoreData.value = rides.length >= _limit;
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
