import 'package:flutter/foundation.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/requests/create_saved_place_request.dart';
import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/create_saved_place_response.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../models/contact_us_models.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile();

  Future<bool> updateProfile(Map<String, dynamic> data);

  Future<UserModel> saveUserAdditionalDetails({
    required String name,
    required String emailId,
  });

  Future<GetSavedPlacesResponseModel?> getSavedPlaces();

  Future<GetSavedPlacesResponseModel?> getFavoritePlaces();

  Future<bool> addSavedPlace(CreateSavedPlaceRequest request);

  Future<bool> saveRecentAsFavorite(SaveRecentAsFavoriteRequest request);

  Future<bool> deleteSavedPlace(String id);

  Future<WalletBalanceModel> getWalletBalance();

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
      return UserModel.fromJson(
        response.data['data'] ?? response.data['response'] ?? {},
      );
    }
    throw Exception('Failed to get profile');
  }

  @override
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.updateProfile,
        method: ApiMethod.post,
        body: data,
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<UserModel> saveUserAdditionalDetails({
    required String name,
    required String emailId,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.saveUserDetails,
        method: ApiMethod.post,
        body: {'name': name, 'emailId': emailId},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return UserModel.fromJson(response.data['response'] ?? {});
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
      debugPrint("Error fetching saved places: $e");
      return null;
    }
  }

  @override
  Future<bool> addSavedPlace(CreateSavedPlaceRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.savedPlaces,
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
  Future<bool> saveRecentAsFavorite(SaveRecentAsFavoriteRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.saveRecentAsFavorite,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );
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
  Future<WalletBalanceModel> getWalletBalance() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.balance,
          method: ApiMethod.get,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return WalletBalanceModel.fromJson(response.data['data'] ?? {});
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint("getWalletBalance error (suppressed): $e");
    }
    return WalletBalanceModel(balance: 0.0, currency: 'TZS');
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
      final List data = response.data['data'] ?? [];
      return data.map((e) => PaymentMethodModel.fromJson(e)).toList();
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
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.address.savedPlaces}/$id/favourite",
        method: isFavorite ? ApiMethod.put : ApiMethod.delete,
        version: "v4",
      ),
    );
    return response.statusCode == 200;
  }
}
