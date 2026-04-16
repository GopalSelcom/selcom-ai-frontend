import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/analytics_service.dart';
import '../../domain/usecases/get_review_tags_usecase.dart';
import '../../domain/usecases/get_last_completed_ride_usecase.dart';
import '../../domain/usecases/skip_ride_rating_usecase.dart';
import '../../domain/usecases/submit_ride_rating_usecase.dart';
import '../controllers/ride_rating_controller.dart';

class RideRatingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RideRatingController>(
      () => RideRatingController(
        getLastCompletedRideUseCase: di.sl<GetLastCompletedRideUseCase>(),
        getReviewTagsUseCase: di.sl<GetReviewTagsUseCase>(),
        submitRideRatingUseCase: di.sl<SubmitRideRatingUseCase>(),
        skipRideRatingUseCase: di.sl<SkipRideRatingUseCase>(),
        analyticsService: di.sl<AnalyticsService>(),
      ),
      fenix: true,
    );
  }
}
