import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/settings_models.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AppSettingsModel>> getAppSettings();
  Future<Either<Failure, RidePinPreferenceModel>> getRidePinPreference();
  Future<Either<Failure, RidePinPreferenceModel>> updateRidePinPreference({
    required bool enabled,
  });
}
