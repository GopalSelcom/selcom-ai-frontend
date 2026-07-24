import 'package:dartz/dartz.dart';

import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../data/models/request/update_profile_request.dart';
import '../../data/models/update_profile_response.dart';
import '../repositories/profile_repository.dart';

class ProfileUseCase {
  final ProfileRepository repository;

  ProfileUseCase(this.repository);

  Future<Either<Failure, UserModel>> getProfile({bool forceRefresh = false}) {
    // Cached after first fetch; use forceRefresh only when a hard reload is needed.
    return repository.getProfile(forceRefresh: forceRefresh);
  }

  Future<Either<Failure, UpdateProfileResponse>> updateProfile(
    UserProfileUpdateRequest profileRequest,
  ) {
    return repository.updateProfile(profileRequest);
  }

  Future<Either<Failure, GoCardBalanceResponseModel>> getWalletBalance() {
    return repository.getWalletBalance();
  }

  Future<Either<Failure, SavedPlacesResponse?>> getSavedPlaces() {
    return repository.getSavedPlaces();
  }
}
