import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/analytics_service.dart';
import '../../domain/repositories/ride_rating_repository.dart';
import '../controllers/ride_rating_controller.dart';

class RideRatingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RideRatingController>(
      () => RideRatingController(
        rideRatingRepository: di.sl<RideRatingRepository>(),
        analyticsService: di.sl<AnalyticsService>(),
      ),
      fenix: true,
    );
  }
}
