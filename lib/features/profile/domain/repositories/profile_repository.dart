import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/user_model.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserModel>> getProfile();
  Future<Either<Failure, bool>> updateProfile(Map<String, dynamic> data);
  Future<Either<Failure, List<SavedPlaceModel>>> getSavedPlaces();
  Future<Either<Failure, bool>> addSavedPlace(SavedPlaceModel place);
  Future<Either<Failure, bool>> deleteSavedPlace(String id);
  Future<Either<Failure, WalletBalanceModel>> getWalletBalance();
  Future<Either<Failure, List<PaymentMethodModel>>> getPaymentMethods();
}
