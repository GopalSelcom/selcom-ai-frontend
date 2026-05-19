import 'package:dartz/dartz.dart';
import 'package:get/get.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/login_pin_failure.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/login_pin_remote_data_source.dart';
import '../../data/models/login_pin_models.dart';
import '../../domain/repositories/login_pin_repository.dart';

/// Maps [LoginPinRemoteDataSource] to domain [Either] + [LoginPinFailure].
///
/// On successful verify/setup, persists tokens via [StorageService].
class LoginPinRepositoryImpl implements LoginPinRepository {
  LoginPinRepositoryImpl({required this.remoteDataSource});

  final LoginPinRemoteDataSource remoteDataSource;

  LoginPinFailure _mapException(LoginPinApiException e) {
    return LoginPinFailure(
      e.message,
      errorCode: e.errorCode,
      attemptsRemaining: e.attemptsRemaining,
      lockedUntil: e.lockedUntil,
    );
  }

  @override
  Future<Either<Failure, LoginPinStatusModel>> getPinStatus() async {
    try {
      final result = await remoteDataSource.getPinStatus();
      return Right(result);
    } on LoginPinApiException catch (e) {
      return Left(_mapException(e));
    } catch (e, stack) {
      ErrorReporter.instance.report(error: e, stackTrace: stack);
      return Left(
        ServerFailure(AppStrings.somethingWentWrongPleaseTryAgain.tr),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setupPin(String pin) async {
    try {
      await remoteDataSource.setupPin(pin);
      return const Right(null);
    } on LoginPinApiException catch (e) {
      return Left(_mapException(e));
    } catch (e, stack) {
      ErrorReporter.instance.report(error: e, stackTrace: stack);
      return Left(
        ServerFailure(AppStrings.somethingWentWrongPleaseTryAgain.tr),
      );
    }
  }

  @override
  Future<Either<Failure, LoginPinVerifyResultModel>> verifyPin(
    String pin,
  ) async {
    try {
      final result = await remoteDataSource.verifyPin(pin);
      await persistLoginSessionFromTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userJson: result.userJson,
      );
      return Right(result);
    } on LoginPinApiException catch (e) {
      return Left(_mapException(e));
    } catch (e, stack) {
      ErrorReporter.instance.report(error: e, stackTrace: stack);
      return Left(
        ServerFailure(AppStrings.somethingWentWrongPleaseTryAgain.tr),
      );
    }
  }

  @override
  Future<Either<Failure, void>> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    try {
      await remoteDataSource.changePin(oldPin: oldPin, newPin: newPin);
      return const Right(null);
    } on LoginPinApiException catch (e) {
      return Left(_mapException(e));
    } catch (e, stack) {
      ErrorReporter.instance.report(error: e, stackTrace: stack);
      return Left(
        ServerFailure(AppStrings.somethingWentWrongPleaseTryAgain.tr),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deletePin() async {
    try {
      await remoteDataSource.deletePin();
      return const Right(null);
    } on LoginPinApiException catch (e) {
      return Left(_mapException(e));
    } catch (e, stack) {
      ErrorReporter.instance.report(error: e, stackTrace: stack);
      return Left(
        ServerFailure(AppStrings.somethingWentWrongPleaseTryAgain.tr),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> setBiometricEnabled(bool enabled) async {
    try {
      final value = await remoteDataSource.setBiometricEnabled(enabled);
      return Right(value);
    } on LoginPinApiException catch (e) {
      return Left(_mapException(e));
    } catch (e, stack) {
      ErrorReporter.instance.report(error: e, stackTrace: stack);
      return Left(
        ServerFailure(AppStrings.somethingWentWrongPleaseTryAgain.tr),
      );
    }
  }

  @override
  Future<bool> refreshSessionTokens() async {
    try {
      final refreshToken = await StorageService().read(
        StorageKeys.refreshToken,
      );
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.refreshToken,
          method: ApiMethod.post,
          body: {'refresh_token': refreshToken},
          skipAuthInterceptor: true,
          shouldQueue: false,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode != 200 || response.data == null) return false;

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      final access =
          (payload['authorization_token'] ??
                  payload['access_token'] ??
                  payload['accessToken'] ??
                  '')
              .toString();
      final refresh =
          (payload['refresh_token'] ??
                  payload['refreshToken'] ??
                  payload['newRefreshToken'] ??
                  '')
              .toString();

      if (access.isEmpty) return false;

      await persistLoginSessionFromTokens(
        accessToken: access,
        refreshToken: refresh.isNotEmpty ? refresh : refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
