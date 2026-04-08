import 'package:dartz/dartz.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/requests/create_saved_place_request.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserModel>> getProfile();
  Future<Either<Failure, bool>> updateProfile(Map<String, dynamic> data);
  Future<Either<Failure, GetSavedPlacesResponseModel?>> getSavedPlaces();
  Future<Either<Failure, bool>> addSavedPlace(CreateSavedPlaceRequest request);
  Future<Either<Failure, bool>> deleteSavedPlace(String id);
  Future<Either<Failure, WalletBalanceModel>> getWalletBalance();
  Future<Either<Failure, List<PaymentMethodModel>>> getPaymentMethods();
}
