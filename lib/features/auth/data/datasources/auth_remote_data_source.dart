import 'dart:developer';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';

abstract class AuthRemoteDataSource {
  Future<SendOtpResponseModel?> sendOtp({required SendOtpRequest request});

  Future<SendOtpResponseModel?> resendOtp({required SendOtpRequest request});

  Future<VerifyOtpResponseModel?> verifyOtp({
    required VerifyOtpRequest request,
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
  Future<SendOtpResponseModel?> sendOtp({
    required SendOtpRequest request,
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.sendOtp,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      if (response.data != null) {
        return SendOtpResponseModel.fromJson(response.data);
      }
    } catch (e) {
      log("sendOtpApi Exception: $e");
    }
    return null;
  }

  @override
  Future<SendOtpResponseModel?> resendOtp({
    required SendOtpRequest request,
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.resendOtp,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      if (response.data != null) {
        return SendOtpResponseModel.fromJson(response.data);
      }
    } catch (e) {
      log("resendOtpApi Exception: $e");
    }
    return null;
  }

  @override
  Future<VerifyOtpResponseModel?> verifyOtp({
    required VerifyOtpRequest request,
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.verifyOtp,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      if (response.data != null) {
        return VerifyOtpResponseModel.fromJson(response.data);
      }
    } catch (e) {
      log("verifyOtpApi Exception: $e");
    }
    return null;
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
        body: {'name': name, 'emailId': email, 'dob': dob, 'gender': gender},
      ),
    );

    return response.statusCode == 200;
  }

  @override
  Future<bool> logout() async {
    final response = await ApiService().call(
      request: ApiRequest(endpoint: URLS.auth.logout, method: ApiMethod.post),
    );

    return response.statusCode == 200;
  }
}
