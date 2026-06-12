import 'package:dio/dio.dart';

import '../../../../core/data/models/requests/firebase_login_request.dart';
import '../../../../core/data/models/requests/go_phone_otp_request.dart';
import '../../../../core/data/models/requests/go_phone_verify_otp_request.dart';
import '../../../../core/data/models/requests/save_user_additional_details_request.dart';
import '../../../../core/data/models/responses/onboarding_banners_response.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';

abstract class AuthRemoteDataSource {
  Future<VerifyOtpResponseModel?> firebaseLogin({
    required FirebaseLoginRequest request,
  });

  Future<SendOtpResponseModel?> sendPhoneOtp({
    required GoPhoneOtpRequest request,
  });

  Future<SendOtpResponseModel?> resendPhoneOtp({
    required GoPhoneOtpRequest request,
  });

  Future<VerifyOtpResponseModel?> verifyPhoneOtp({
    required GoPhoneVerifyOtpRequest request,
  });

  Future<UserModel> saveUserAdditionalDetails({
    required SaveUserAdditionalDetailsRequest request,
  });

  Future<String> refreshToken();

  Future<bool> logout();

  /// Public onboarding carousel; no auth token required.
  Future<List<OnboardingBannerItem>> getOnboardingBanners();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl();

  @override
  Future<VerifyOtpResponseModel?> firebaseLogin({
    required FirebaseLoginRequest request,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.firebaseLogin,
        method: ApiMethod.post,
        body: request.toJson(),
        skipAuthInterceptor: true,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return VerifyOtpResponseModel.fromJson(
        _responseMap(response.data),
      );
    }

    _throwIfErrorResponse(response, URLS.auth.firebaseLogin);
  }

  @override
  Future<SendOtpResponseModel?> sendPhoneOtp({
    required GoPhoneOtpRequest request,
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.phoneSendOtp,
          method: ApiMethod.post,
          body: request.toJson(),
          skipAuthInterceptor: true,
        ),
      );

      if (response.data != null) {
        return SendOtpResponseModel.fromJson(_responseMap(response.data));
      }
    } catch (_) {
      // Intentionally avoid logging request payload details.
    }
    return null;
  }

  @override
  Future<SendOtpResponseModel?> resendPhoneOtp({
    required GoPhoneOtpRequest request,
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.auth.phoneResendOtp,
          method: ApiMethod.post,
          body: request.toJson(),
          skipAuthInterceptor: true,
        ),
      );

      if (response.data != null) {
        return SendOtpResponseModel.fromJson(_responseMap(response.data));
      }
    } catch (_) {
      // Intentionally avoid logging request payload details.
    }
    return null;
  }

  @override
  Future<VerifyOtpResponseModel?> verifyPhoneOtp({
    required GoPhoneVerifyOtpRequest request,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.phoneVerifyOtp,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return VerifyOtpResponseModel.fromJson(
        _responseMap(response.data),
      );
    }

    _throwIfErrorResponse(response, URLS.auth.phoneVerifyOtp);
  }

  @override
  Future<UserModel> saveUserAdditionalDetails({
    required SaveUserAdditionalDetailsRequest request,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.auth.saveUserDetails,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return UserModel.fromJson(response.data['response'] ?? {});
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return UserModel.fromJson({});
    }
    throw Exception(
      response.data?['message'] ?? 'Failed to save additional details',
    );
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
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return (payload['authorization_token'] ??
              payload['access_token'] ??
              payload['accessToken'] ??
              '')
          .toString();
    }
    return '';
  }

  @override
  Future<bool> logout() async {
    final response = await ApiService().call(
      request: ApiRequest(endpoint: URLS.auth.logout, method: ApiMethod.post),
    );

    return response.statusCode == 200;
  }

  @override
  Future<List<OnboardingBannerItem>> getOnboardingBanners() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.common.onboardingBanner,
          method: ApiMethod.get,
          skipAuthInterceptor: true,
          shouldQueue: false,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseOnboardingBannersFromResponse(
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (_) {}
    return const [];
  }

  Map<String, dynamic> _responseMap(dynamic data) {
    return data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
  }

  Never _throwIfErrorResponse(Response<dynamic> response, String endpoint) {
    throw DioException(
      requestOptions: RequestOptions(path: endpoint),
      response: response,
      type: DioExceptionType.badResponse,
    );
  }
}
