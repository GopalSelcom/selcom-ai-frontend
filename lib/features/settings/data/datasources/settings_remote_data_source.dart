import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/localization/app_strings.dart';
import 'package:get/get.dart';
import '../models/settings_models.dart';

abstract class SettingsRemoteDataSource {
  Future<AppSettingsModel> getAppSettings();
  Future<RidePinPreferenceModel> getRidePinPreference();
  Future<RidePinPreferenceModel> updateRidePinPreference({
    required bool enabled,
  });
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  @override
  Future<AppSettingsModel> getAppSettings() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.settings.appSettings,
        method: ApiMethod.get,
        skipAuthInterceptor: true,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        final settings = data['settings'];
        if (settings is Map<String, dynamic>) {
          return AppSettingsModel.fromJson(settings);
        }
      }
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return AppSettingsModel.fromJson({});
    }
    throw Exception(response.data?['message'] ?? AppStrings.failedToLoadSettings.tr);
  }

  @override
  Future<RidePinPreferenceModel> getRidePinPreference() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.settings.ridePinPreference,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final payload =
          (response.data['data'] ??
              response.data['response'] ??
              response.data) as Map<String, dynamic>;
      return RidePinPreferenceModel.fromJson(payload);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return RidePinPreferenceModel.fromJson({});
    }
    throw Exception(
      response.data?['message'] ?? AppStrings.failedToLoadRidePinPreference.tr,
    );
  }

  @override
  Future<RidePinPreferenceModel> updateRidePinPreference({
    required bool enabled,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.settings.ridePinPreference,
        method: ApiMethod.put,
        body: {'enabled': enabled},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final payload =
          (response.data['data'] ??
              response.data['response'] ??
              response.data) as Map<String, dynamic>;
      return RidePinPreferenceModel.fromJson(payload);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return RidePinPreferenceModel.fromJson({});
    }
    throw Exception(
      response.data?['message'] ?? AppStrings.failedToUpdateRidePinPreference.tr,
    );
  }
}
