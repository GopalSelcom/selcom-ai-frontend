import '../../../../core/constants/currency_code.dart';
import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/create_saved_place_response.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../models/contact_us_models.dart';
import '../models/profile_response_model.dart';
import '../models/request/update_profile_request.dart';
import '../models/update_profile_response.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile();

  Future<UserProfileUpdateResponse> updateProfile(
    UserProfileUpdateRequest profileRequest,
  );

  Future<GetSavedPlacesResponseModel?> getSavedPlaces();

  Future<bool> saveRecentAsFavorite(SaveRecentAsFavoriteRequest request);

  Future<bool> deleteSavedPlace(String id);

  Future<GoCardBalanceResponseModel> getWalletBalance();

  Future<EmailSubjectResponseModel> getEmailSubjects();

  Future<SendEmailResponseModel> sendEmail(SendEmailRequestModel request);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl();

  @override
  Future<UserModel> getProfile() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.getProfile,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final profileResponse = UserProfileResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      return profileResponse.data.toUserModel();
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return const UserModel(id: '');
    }
    throw Exception('Failed to get profile');
  }

  @override
  Future<UserProfileUpdateResponse> updateProfile(
    UserProfileUpdateRequest profileRequest,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.updateProfile,
        method: profileRequest.image != null
            ? ApiMethod.multipart
            : ApiMethod.post,
        body: profileRequest.toJson(),
        multipartFiles: profileRequest.image != null
            ? [
                LocalMultipartFile(
                  name: "image",
                  path: profileRequest.image?.path ?? "",
                ),
              ]
            : null,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return UserProfileUpdateResponse.fromJson(response.data);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      final d = response.data;
      if (d is Map<String, dynamic>) {
        return UserProfileUpdateResponse.fromJson(d);
      }
      if (d is Map) {
        return UserProfileUpdateResponse.fromJson(Map<String, dynamic>.from(d));
      }
      return UserProfileUpdateResponse(
        statusCode: response.statusCode,
        message: null,
        data: null,
      );
    }
    throw Exception(response.data['message'] ?? 'Failed to update profile');
  }

  @override
  /// `GET go/user/saved-places` — full list; `saved_places: []` when empty.
  Future<GetSavedPlacesResponseModel?> getSavedPlaces() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.address.savedPlaces,
          method: ApiMethod.get,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return GetSavedPlacesResponseModel.fromJson(
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d('Error fetching saved places: $e', tag: 'ProfileRemoteDataSource');
      return null;
    }
  }

  @override
  /// `POST go/user/saved-places/from-recent` — creates saved place (favourite by default).
  Future<bool> saveRecentAsFavorite(SaveRecentAsFavoriteRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.saveRecentAsFavorite,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.data != null) {
      final createResponse = CreateSavedPlaceResponseModel.fromJson(
        response.data,
      );
      return createResponse.isSuccess;
    }
    return response.statusCode == 200;
  }

  @override
  /// `DELETE go/user/saved-places/{id}` — remove saved place (no unfavourite-only API).
  Future<bool> deleteSavedPlace(String id) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.deleteSavedPlace(id),
        method: ApiMethod.delete,
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<GoCardBalanceResponseModel> getWalletBalance() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.cardBalance,
          method: ApiMethod.get,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return GoCardBalanceResponseModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d('getWalletBalance error (suppressed): $e', tag: 'ProfileRemoteDataSource');
    }
    return GoCardBalanceResponseModel(
      response: BalanceResponse(
        data: [
          BalanceDatum(balance: 0, currency: CurrencyCode.tzs),
        ],
      ),
    );
  }

  @override
  Future<EmailSubjectResponseModel> getEmailSubjects() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.getEmailSubject,
        method: ApiMethod.get,
        skipAuthInterceptor: true,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return EmailSubjectResponseModel.fromJson(response.data);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return EmailSubjectResponseModel.fromJson({
        'status_code': response.statusCode,
        'message': '',
        'response': <String>[],
      });
    }
    throw Exception('Failed to get email subject');
  }

  @override
  Future<SendEmailResponseModel> sendEmail(
    SendEmailRequestModel request,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.sendEmail,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.data != null) {
      return SendEmailResponseModel.fromJson(response.data);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return SendEmailResponseModel(
        statusCode: response.statusCode ?? 400,
        message: '',
      );
    }
    throw Exception('Failed to send email');
  }
}
