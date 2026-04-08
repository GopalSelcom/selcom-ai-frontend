import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../errors/failures.dart';
import '../../errors/error_mapper.dart';
import '../../network/api_service.dart';
import '../../network/urls.dart';
import '../models/user_model.dart';
import '../models/requests/auth_requests.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, void>> sendOtp(SendOtpRequest request) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.sendOtp,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      if (response.statusCode == 200) {
        return const Right(null);
      }

      final message = response.data?['message'] ?? 'Failed to send OTP';
      return Left(ServerFailure(message));
    } on DioException catch (e) {
      return Left(ErrorMapper.mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.verifyOtp,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data['user']);

        // Store tokens securely
        if (response.data['authorization_token'] != null) {
          await secureStorage.write(
            key: 'authorization_token',
            value: response.data['authorization_token'],
          );
        }
        if (response.data['access_token'] != null) {
          await secureStorage.write(
            key: 'access_token',
            value: response.data['access_token'],
          );
        }
        if (response.data['refresh_token'] != null) {
          await secureStorage.write(
            key: 'refresh_token',
            value: response.data['refresh_token'],
          );
        }

        return Right(user);
      }

      final message = response.data?['message'] ?? 'OTP verification failed';
      return Left(ServerFailure(message));
    } on DioException catch (e) {
      return Left(ErrorMapper.mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call logout API
      await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.logout,
          method: ApiMethod.post,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      // Clear tokens
      await secureStorage.delete(key: 'authorization_token');
      await secureStorage.delete(key: 'access_token');
      await secureStorage.delete(key: 'refresh_token');

      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final rToken = await secureStorage.read(key: 'refresh_token');

      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.refreshToken,
          method: ApiMethod.post,
          body: {'refresh_token': rToken},
          skipAuthInterceptor: true,
          shouldQueue: false,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final newToken = response.data['authorization_token'];
        if (newToken != null) {
          await secureStorage.write(
            key: 'authorization_token',
            value: newToken,
          );
        }
        if (response.data['access_token'] != null) {
          await secureStorage.write(
            key: 'access_token',
            value: response.data['access_token'],
          );
        }
        if (response.data['refresh_token'] != null) {
          await secureStorage.write(
            key: 'refresh_token',
            value: response.data['refresh_token'],
          );
        }
        return Right(newToken ?? '');
      }

      return const Left(AuthFailure('Token refresh failed'));
    } on DioException catch (e) {
      return Left(ErrorMapper.mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
