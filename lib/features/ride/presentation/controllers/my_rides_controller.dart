import 'package:get/get.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../domain/usecases/ride_usecase.dart';

class MyRidesController extends GetxController {
  final RideUseCase rideUseCase;

  MyRidesController({required this.rideUseCase});

  final pastRides = <RideModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPastRides();
  }

  Future<void> fetchPastRides() async {
    try {
      isLoading.value = true;
      final result = await rideUseCase.getRideHistory();
      result.fold(
        (failure) => Get.snackbar('Error', failure.message),
        (rides) => pastRides.assignAll(rides),
      );
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }
}
