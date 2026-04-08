import 'package:flutter/foundation.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/requests/create_saved_place_request.dart';
import '../../../../core/data/models/responses/saved_places_response.dart';
import '../../../../core/data/models/responses/create_saved_place_response.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile();
  Future<bool> updateProfile(Map<String, dynamic> data);
  Future<GetSavedPlacesResponseModel?> getSavedPlaces();
  Future<bool> addSavedPlace(CreateSavedPlaceRequest request);
  Future<bool> deleteSavedPlace(String id);
  Future<WalletBalanceModel> getWalletBalance();
  Future<List<PaymentMethodModel>> getPaymentMethods();
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
      return UserModel.fromJson(response.data['data'] ?? response.data['response'] ?? {});
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
  Future<GetSavedPlacesResponseModel?> getSavedPlaces() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.address.getSavedPlaces,
          // Postman uses v4/go/user/saved-places
          method: ApiMethod.get,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final savedResponse = GetSavedPlacesResponseModel.fromJson(response.data);
        return savedResponse;
      }
      return null;
    }catch(e){
      debugPrint("this is error -> $e");
    }
  }

  @override
  Future<bool> addSavedPlace(CreateSavedPlaceRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.addUserAddress, // Registry uses same for POST/GET sometimes
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.data != null) {
      final createResponse = CreateSavedPlaceResponseModel.fromJson(response.data);
      return createResponse.isSuccess;
    }
    return response.statusCode == 200;
  }

  @override
  Future<bool> deleteSavedPlace(String id) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.address.delete}/$id",
        method: ApiMethod.delete,
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<WalletBalanceModel> getWalletBalance() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "go/wallet/balance",
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return WalletBalanceModel.fromJson(response.data['data'] ?? {});
    }
    throw Exception('Failed to get wallet balance');
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "go/user/payment-methods",
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final List data = response.data['data'] ?? [];
      return data.map((e) => PaymentMethodModel.fromJson(e)).toList();
    }
    return [];
  }
}
