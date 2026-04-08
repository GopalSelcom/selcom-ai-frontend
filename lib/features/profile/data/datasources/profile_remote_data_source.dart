import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile();
  Future<bool> updateProfile(Map<String, dynamic> data);
  Future<List<SavedPlaceModel>> getSavedPlaces();
  Future<bool> addSavedPlace(SavedPlaceModel place);
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
  Future<List<SavedPlaceModel>> getSavedPlaces() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.getSavedPlaces, // Postman uses v4/go/user/saved-places
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final List data = response.data['data'] ?? response.data['response'] ?? [];
      return data.map((e) => SavedPlaceModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<bool> addSavedPlace(SavedPlaceModel place) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.getSavedPlaces, // Registry uses same for POST/GET sometimes
        method: ApiMethod.post,
        body: place.toJson(),
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> deleteSavedPlace(String id) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "${URLS.address.getSavedPlaces}/$id",
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
