import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../models/settings_models.dart';

abstract class SettingsRemoteDataSource {
  Future<Settings> getAppSettings();

  Future<RidePinPreferenceModel> getRidePinPreference();

  Future<RidePinPreferenceModel> updateRidePinPreference({
    required bool enabled,
  });
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  @override
  Future<Settings> getAppSettings() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.settings.appSettings,
        method: ApiMethod.get,
        skipAuthInterceptor: true,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final raw = response.data;
      if (raw is Map) {
        final parsed = AppSettingsResponse.fromMap(
          Map<String, dynamic>.from(raw),
        );
        final settings = parsed.data?.settings;
        if (settings != null) return settings;

        final data = raw['data'];
        if (data is Map && data['settings'] is Map) {
          return Settings.fromMap(
            Map<String, dynamic>.from(data['settings'] as Map),
          );
        }
      }
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return Settings();
    }
    throw Exception(
      response.data?['message'] ?? AppStrings.failedToLoadSettings.tr,
    );
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
          (response.data['data'] ?? response.data['response'] ?? response.data)
              as Map<String, dynamic>;
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
        body: {Params.enabled: enabled},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final payload =
          (response.data['data'] ?? response.data['response'] ?? response.data)
              as Map<String, dynamic>;
      return RidePinPreferenceModel.fromJson(payload);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return RidePinPreferenceModel.fromJson({});
    }
    throw Exception(
      response.data?['message'] ??
          AppStrings.failedToUpdateRidePinPreference.tr,
    );
  }
}
