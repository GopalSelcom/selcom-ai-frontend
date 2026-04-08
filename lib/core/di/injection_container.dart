import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../services/analytics_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../network/api_service.dart';
import '../network/headers.dart';
import '../network/network_connectivity_service.dart';
import '../network/retry_manager.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  // ── Services ──
  sl.registerLazySingleton(() => AnalyticsService());

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
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      secureStorage: sl(),
    ),
  );

  // Use Cases
  // sl.registerLazySingleton(() => LoginUseCase(sl()));

  // BLoCs / Controllers
  // sl.registerFactory(() => AuthBloc(loginUseCase: sl()));
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
