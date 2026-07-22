import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/requests/send_email_request.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/responses/send_email_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../data/models/contact_us_models.dart';
import '../../data/models/request/update_profile_request.dart';
import '../../data/models/update_profile_response.dart';

abstract class ProfileRepository {
  /// Returns [UserProfileCache] when loaded; pass [forceRefresh] to bypass cache.
  Future<Either<Failure, UserModel>> getProfile({bool forceRefresh = false});

  /// Drops cached profile (logout / session expiry).
  void invalidateProfileCache();

  Future<Either<Failure, UserProfileUpdateResponse>> updateProfile(
    UserProfileUpdateRequest profileRequest,
  );

  Future<Either<Failure, GetSavedPlacesResponseModel?>> getSavedPlaces();

  Future<Either<Failure, bool>> saveRecentAsFavorite(
    SaveRecentAsFavoriteRequest request,
  );

  Future<Either<Failure, bool>> deleteSavedPlace(String id);

  Future<Either<Failure, GoCardBalanceResponseModel>> getWalletBalance();

  Future<Either<Failure, EmailSubjectResponseModel>> getEmailSubjects();

  Future<Either<Failure, SendEmailResponse>> sendEmail(
    SendEmailRequest request,
  );
}
