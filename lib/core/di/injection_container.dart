import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/apple_auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_data_source.dart';
import '../../features/auth/data/datasources/support_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/support_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/support_repository.dart';
import '../../features/notification/data/datasources/notification_remote_data_source.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/presentation/controllers/notification_controller.dart';
import '../../features/profile/presentation/controllers/payment_methods_controller.dart';
import '../../features/payment/presentation/controllers/payment_method_controller.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/datasources/selcom_pesa_link_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/data/repositories/selcom_pesa_link_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/repositories/selcom_pesa_link_repository.dart';
import '../../features/profile/domain/usecases/profile_usecase.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/ride/data/datasources/ride_remote_data_source.dart';
import '../../features/ride/data/datasources/ride_share_remote_datasource.dart';
import '../../features/ride/data/repositories/ride_repository_impl.dart';
import '../../features/ride/data/repositories/ride_share_repository_impl.dart';
import '../../features/ride/domain/repositories/ride_repository.dart';
import '../../features/ride/domain/repositories/ride_share_repository.dart';
import '../../features/ride/domain/usecases/generate_share_link_use_case.dart';
import '../../features/ride/domain/usecases/revoke_share_link_use_case.dart';
import '../../features/ride/domain/usecases/ride_usecase.dart';
import '../../features/ride/presentation/controllers/my_rides_controller.dart';
import '../../features/ride_rating/data/datasources/ride_rating_remote_data_source.dart';
import '../../features/ride_rating/data/repositories/ride_rating_repository_impl.dart';
import '../../features/ride_rating/domain/repositories/ride_rating_repository.dart';
import '../../features/ride_rating/domain/usecases/get_last_completed_ride_usecase.dart';
import '../../features/ride_rating/domain/usecases/get_review_tags_usecase.dart';
import '../../features/ride_rating/domain/usecases/skip_ride_rating_usecase.dart';
import '../../features/ride_rating/domain/usecases/submit_ride_rating_usecase.dart';
import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/settings_usecase.dart';
import '../../features/payment/data/datasources/selcom_pesa_topup_remote_data_source.dart';
import '../../features/payment/data/datasources/wallet_payment_remote_data_source.dart';
import '../../features/wallet/data/datasources/wallet_remote_data_source.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallet_details_usecase.dart';
import '../../features/wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../features/wallet/domain/usecases/email_wallet_statement_usecase.dart';
import '../../features/wallet/domain/usecases/get_wallet_transactions_usecase.dart';
import '../network/api_service.dart';
import '../network/headers.dart';
import '../network/network_connectivity_service.dart';
import '../network/retry_manager.dart';
import '../services/analytics_service.dart';
import '../services/app_region_service.dart';
import '../services/app_settings_service.dart';
import '../services/live_activity/live_activity_manager.dart';
import '../services/nearby_drivers_socket_service.dart';
import '../services/notification_service.dart';
import '../services/apple_sign_in_service.dart';
import '../services/google_sign_in_service.dart';
import '../services/facebook_sign_in_service.dart';
import '../services/selcom_pesa/selcom_pesa_app_launcher_service.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  // ── Services ──
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => AppRegionService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => AppSocketService());
  sl.registerLazySingleton(() => LiveActivityManager());
  sl.registerLazySingleton(() => SelcomPesaAppLauncherService());
  sl.registerLazySingleton(() => GoogleSignInService());
  sl.registerLazySingleton(() => AppleSignInService());
  sl.registerLazySingleton(() => FacebookSignInService());
  sl.registerLazySingleton(() => FirebaseAuthDataSource());
  sl.registerLazySingleton<AppleAuthLocalDataSource>(
    () => AppleAuthLocalDataSourceImpl(),
  );

  // ── Network — ApiService initialization ──
  ApiService().init(
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
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      appleSignInService: sl(),
      facebookSignInService: sl(),
      googleSignInService: sl(),
      firebaseAuthDataSource: sl(),
      appleAuthLocalDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<SupportRemoteDataSource>(
    () => SupportRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(remoteDataSource: sl()),
  );

  // ── Ride Feature ──
  sl.registerLazySingleton<RideRemoteDataSource>(
    () => RideRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<RideRepository>(
    () => RideRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<RideShareRemoteDataSource>(
    () => RideShareRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<RideShareRepository>(
    () => RideShareRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GenerateShareLinkUseCase(sl()));
  sl.registerLazySingleton(() => RevokeShareLinkUseCase(sl()));

  // ── Profile Feature ──
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SelcomPesaLinkRemoteDataSource>(
    () => SelcomPesaLinkRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SelcomPesaLinkRepository>(
    () => SelcomPesaLinkRepositoryImpl(remoteDataSource: sl()),
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
  sl.registerLazySingleton(() => AppSettingsService(settingsUseCase: sl()));

  // BLoCs / Controllers
  sl.registerFactory(() => MyRidesController(rideUseCase: sl()));
  sl.registerFactory(
    () => ProfileController(
      profileUseCase: sl(),
      appSettingsService: sl(),
      getWalletSummaryUseCase: sl(),
    ),
  );
  sl.registerFactory(() => PaymentMethodController(profileRepository: sl()));
  sl.registerFactory(() => PaymentMethodsController());

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

  // ── Wallet Feature (dummy local data until API) ──
  sl.registerLazySingleton<WalletPaymentRemoteDataSource>(
    () => WalletPaymentRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<SelcomPesaTopupRemoteDataSource>(
    () => SelcomPesaTopupRemoteDataSourceImpl(),
  );
  // ── Wallet Feature ──
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(
      remoteDataSource: sl(),
      paymentRemoteDataSource: sl(),
      selcomPesaTopupRemoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetWalletDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetWalletSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetWalletTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => EmailWalletStatementUseCase(sl()));

  await sl<AppRegionService>().restore();
}
