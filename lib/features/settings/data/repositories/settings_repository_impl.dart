import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/settings_models.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AppSettingsModel>> getAppSettings() async {
    try {
      final result = await remoteDataSource.getAppSettings();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RidePinPreferenceModel>> getRidePinPreference() async {
    try {
      final result = await remoteDataSource.getRidePinPreference();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RidePinPreferenceModel>> updateRidePinPreference({
    required bool enabled,
  }) async {
    try {
      final result = await remoteDataSource.updateRidePinPreference(
        enabled: enabled,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
