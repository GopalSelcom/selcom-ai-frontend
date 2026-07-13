import '../../../../core/constants/currency_code.dart';
import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/create_saved_place_response.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/user_profile_models.dart';
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

  Future<GetSavedPlacesResponseModel?> getFavoritePlaces();

  Future<bool> saveRecentAsFavorite(SaveRecentAsFavoriteRequest request);

  Future<bool> deleteSavedPlace(String id);

  Future<GoCardBalanceResponseModel> getWalletBalance();

  Future<List<PaymentMethodModel>> getPaymentMethods();

  Future<EmailSubjectResponseModel> getEmailSubjects();

  Future<SendEmailResponseModel> sendEmail(SendEmailRequestModel request);

  Future<bool> toggleFavorite(String id, bool isFavorite);
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
  Future<GetSavedPlacesResponseModel?> getSavedPlaces() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.address.savedPlaces,
          method: ApiMethod.get,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final savedResponse = GetSavedPlacesResponseModel.fromJson(
          response.data,
        );
        return savedResponse;
      }
      return null;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d('Error fetching saved places: $e', tag: 'ProfileRemoteDataSource');
      return null;
    }
  }

  @override
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
  Future<bool> deleteSavedPlace(String id) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.address.savedPlaces}/$id",
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
      response: GoCardBalanceData(balance: "0", currency: CurrencyCode.tzs),
    );
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.paymentMethods,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      // API shape (go/user/payment-methods):
      // { "data": { "default": "wallet", "methods": [ { "type", "label", ... } ] } }
      // Legacy: { "data": [ { ... }, ... ] }
      final rawData = response.data['data'];
      final List<dynamic> rows;
      if (rawData is List) {
        rows = rawData;
      } else if (rawData is Map) {
        final methods = rawData['methods'];
        rows = methods is List ? methods : <dynamic>[];
      } else {
        rows = <dynamic>[];
      }
      final models = rows
          .map((e) {
            if (e is! Map) {
              return null;
            }
            return PaymentMethodModel.fromJson(Map<String, dynamic>.from(e));
          })
          .whereType<PaymentMethodModel>()
          .toList();

      if (rawData is Map) {
        final def = rawData['default']?.toString().trim();
        if (def != null && def.isNotEmpty) {
          final idx = models.indexWhere((m) => m.type == def || m.id == def);
          if (idx > 0) {
            models.insert(0, models.removeAt(idx));
          }
        }
      }

      return models;
    }
    return [];
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

  @override
  Future<GetSavedPlacesResponseModel?> getFavoritePlaces() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.address.savedPlaces}/favourites",
        method: ApiMethod.get,
        version: "v4",
      ),
    );
    if (response.statusCode == 200) {
      return GetSavedPlacesResponseModel.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final endpoint = isFavorite
        ? "${URLS.address.savedPlaces}/$id/favourite"
        : "${URLS.address.savedPlaces}/$id";
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: endpoint,
        method: isFavorite ? ApiMethod.put : ApiMethod.delete,
        version: "v4",
      ),
    );
    return response.statusCode == 200;
  }
}
