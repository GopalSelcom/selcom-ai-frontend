import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/notification/data/datasources/notification_remote_data_source.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/presentation/controllers/notification_controller.dart';
import '../../features/ride_rating/data/datasources/ride_rating_remote_data_source.dart';
import '../../features/ride_rating/data/repositories/ride_rating_repository_impl.dart';
import '../../features/ride_rating/domain/repositories/ride_rating_repository.dart';
import '../../features/ride_rating/domain/usecases/get_review_tags_usecase.dart';
import '../../features/ride_rating/domain/usecases/get_last_completed_ride_usecase.dart';
import '../../features/ride_rating/domain/usecases/skip_ride_rating_usecase.dart';
import '../../features/ride_rating/domain/usecases/submit_ride_rating_usecase.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecase.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/settings_usecase.dart';
import '../services/nearby_drivers_socket_service.dart';
import '../../features/ride/data/datasources/ride_remote_data_source.dart';
import '../../features/ride/data/repositories/ride_repository_impl.dart';
import '../../features/ride/domain/repositories/ride_repository.dart';
import '../../features/ride/domain/usecases/ride_usecase.dart';
import '../../features/ride/presentation/controllers/my_rides_controller.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/promotions/presentation/controllers/promocode_controller.dart';
import '../../features/payment/presentation/controllers/payment_method_controller.dart';
import '../config/app_config.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../network/api_service.dart';
import '../network/headers.dart';
import '../network/network_connectivity_service.dart';
import '../network/retry_manager.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  // ── Services ──
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => AppSocketService());

  // ── External ──
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // ── Network — ApiService initialization ──
  final environment = _mapEnvironment(AppConfig.environment);

  ApiService().init(
    stagingBaseUrl: 'https://dukastaging.selcom.dev:7443',
    productionBaseUrl: 'https://api.duka.direct',
    environment: environment,
    commonHeadersBuilder: () => commonHeaders(accessTokenRequired: true),
  );

  // ── Network — Connectivity & Retry ──
  NetworkConnectivityService.instance.startMonitoring();
  RetryManager.instance.initialize();

  // ── Repository ──
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // ── Ride Feature ──
  sl.registerLazySingleton<RideRemoteDataSource>(
    () => RideRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(remoteDataSource: sl()),
  );

  // ── Profile Feature ──
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => RideUseCase(sl()));
  sl.registerLazySingleton(() => ProfileUseCase(sl()));
  sl.registerLazySingleton(() => SettingsUseCase(sl()));

  // BLoCs / Controllers
  sl.registerFactory(() => MyRidesController(rideUseCase: sl()));
  sl.registerFactory(() => ProfileController(profileUseCase: sl()));
  sl.registerFactory(() => PromocodeController());
  sl.registerFactory(() => PaymentMethodController(profileRepository: sl()));

  // ── Notification Feature ──
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerFactory(() => NotificationController(repository: sl()));

  // ── Ride Rating Feature ──
  sl.registerLazySingleton<RideRatingRemoteDataSource>(
    () => RideRatingRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<RideRatingRepository>(
    () => RideRatingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetLastCompletedRideUseCase(sl()));
  sl.registerLazySingleton(() => GetReviewTagsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRideRatingUseCase(sl()));
  sl.registerLazySingleton(() => SkipRideRatingUseCase(sl()));
}

/// Maps the app's Environment enum to ApiService's ApiEnvironment enum
ApiEnvironment _mapEnvironment(Environment env) {
  switch (env) {
    case Environment.dev:
      return ApiEnvironment.local;
    case Environment.staging:
      return ApiEnvironment.staging;
    case Environment.prod:
      return ApiEnvironment.production;
  }
}
