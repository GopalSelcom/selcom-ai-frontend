import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../repositories/profile_repository.dart';

class ProfileUseCase {
  final ProfileRepository repository;

  ProfileUseCase(this.repository);

  Future<Either<Failure, UserModel>> getProfile() {
    return repository.getProfile();
  }

  Future<Either<Failure, bool>> updateProfile(Map<String, dynamic> data) {
    return repository.updateProfile(data);
  }

  Future<Either<Failure, WalletBalanceModel>> getWalletBalance() {
    return repository.getWalletBalance();
  }

  Future<Either<Failure, List<PaymentMethodModel>>> getPaymentMethods() {
    return repository.getPaymentMethods();
  }

  Future<Either<Failure, GetSavedPlacesResponseModel?>> getFavoritePlaces() {
    return repository.getFavoritePlaces();
  }
}
