import '../models/auth_models.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/network/api_constants.dart';

abstract class AuthRemoteDataSource {
  Future<bool> sendOtp({
    required String mobileNumber,
    required String countryCode,
    String? email,
  });

  Future<bool> resendOtp({
    required String mobileNumber,
    required String countryCode,
  });

  Future<AuthModel> verifyOtp({
    required String mobileNumber,
    required String countryCode,
    required String otp,
  });

  Future<String> refreshToken();

  Future<bool> saveUserAdditionalDetails({
    required String name,
    required String email,
    required String dob,
    required String gender,
  });

  Future<bool> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl();

  @override
  Future<bool> sendOtp({
    required String mobileNumber,
    required String countryCode,
    String? email,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.sendOtp,
        method: ApiMethod.post,
        body: {
          Params.mobileNumber: mobileNumber,
          Params.countryCode: countryCode,
          if (email != null) 'email': email,
        },
      ),
    );

    return response.statusCode == 200;
  }

  @override
  Future<bool> resendOtp({
    required String mobileNumber,
    required String countryCode,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.resendOtp,
        method: ApiMethod.post,
        body: {
          Params.mobileNumber: mobileNumber,
          Params.countryCode: countryCode,
        },
      ),
    );

    return response.statusCode == 200;
  }

  @override
  Future<AuthModel> verifyOtp({
    required String mobileNumber,
    required String countryCode,
    required String otp,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.verifyOtp,
        method: ApiMethod.post,
        body: {
          Params.mobileNumber: mobileNumber,
          Params.countryCode: countryCode,
          'otp': otp,
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return AuthModel.fromJson(response.data);
    } else {
      throw Exception(response.data?['message'] ?? 'OTP verification failed');
    }
  }

  @override
  Future<String> refreshToken() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.refreshToken,
        method: ApiMethod.post,
        body: {},
        skipAuthInterceptor: true, // Crucial for refresh
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data['accessToken'] ?? '';
    }
    return '';
  }

  @override
  Future<bool> saveUserAdditionalDetails({
    required String name,
    required String email,
    required String dob,
    required String gender,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.saveUserDetails,
        method: ApiMethod.post,
        body: {
          'name': name,
          'emailId': email,
          'dob': dob,
          'gender': gender,
        },
      ),
    );

    return response.statusCode == 200;
  }

  @override
  Future<bool> logout() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.logout,
        method: ApiMethod.post,
      ),
    );

    return response.statusCode == 200;
  }
}
