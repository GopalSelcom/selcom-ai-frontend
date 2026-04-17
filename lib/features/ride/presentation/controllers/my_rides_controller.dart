import 'package:get/get.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../domain/usecases/ride_usecase.dart';

class MyRidesController extends GetxController {
  final RideUseCase rideUseCase;

  MyRidesController({required this.rideUseCase});

  final pastRides = <RideModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
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
        (failure) => Get.snackbar('Error', failure.message),
        (rides) {
          pastRides.assignAll(rides);
          hasMoreData.value = rides.length >= _limit;
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
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
        (failure) => Get.snackbar('Error', failure.message),
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
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
    } finally {
      isLoadingMore.value = false;
    }
  }
}
