import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/requests/save_user_additional_details_request.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/responses/onboarding_banners_response.dart';

abstract class AuthRemoteDataSource {
  Future<SendOtpResponseModel?> sendOtp({required SendOtpRequest request});

  Future<SendOtpResponseModel?> resendOtp({required SendOtpRequest request});

  Future<VerifyOtpResponseModel?> verifyOtp({
    required VerifyOtpRequest request,
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
      // Intentionally avoid logging request payload details.
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
      // Intentionally avoid logging request payload details.
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
      // Intentionally avoid logging request payload details.
    }
    return null;
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
}
