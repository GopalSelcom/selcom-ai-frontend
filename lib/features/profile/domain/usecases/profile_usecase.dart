import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../data/models/request/update_profile_request.dart';
import '../../data/models/update_profile_response.dart';
import '../repositories/profile_repository.dart';

class ProfileUseCase {
  final ProfileRepository repository;

  ProfileUseCase(this.repository);

  Future<Either<Failure, UserModel>> getProfile() {
    return repository.getProfile();
  }

  Future<Either<Failure, UserProfileUpdateResponse>> updateProfile(UserProfileUpdateRequest profileRequest) {
    return repository.updateProfile(profileRequest);
  }

  Future<Either<Failure, UserModel>> saveUserAdditionalDetails({
    required String name,
    required String emailId,
    String? imagePath,
  }) {
    return repository.saveUserAdditionalDetails(
      name: name,
      emailId: emailId,
      imagePath: imagePath,
    );
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
