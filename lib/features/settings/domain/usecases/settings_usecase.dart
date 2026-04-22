import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/settings_models.dart';
import '../repositories/settings_repository.dart';

class SettingsUseCase {
  final SettingsRepository repository;

  SettingsUseCase(this.repository);

  Future<Either<Failure, AppSettingsModel>> getAppSettings() {
    return repository.getAppSettings();
  }

  Future<Either<Failure, RidePinPreferenceModel>> getRidePinPreference() {
    return repository.getRidePinPreference();
  }

  Future<Either<Failure, RidePinPreferenceModel>> updateRidePinPreference({
    required bool enabled,
  }) {
    return repository.updateRidePinPreference(enabled: enabled);
  }
}
