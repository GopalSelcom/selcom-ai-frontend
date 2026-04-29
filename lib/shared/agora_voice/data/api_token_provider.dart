import 'package:dio/dio.dart';

import '../domain/agora_token_provider.dart';

class ApiTokenProvider implements AgoraTokenProvider {
  ApiTokenProvider({required this.endpoint, Dio? dio}) : _dio = dio ?? Dio();

  final String endpoint;
  final Dio _dio;

  @override
  Future<AgoraTokenData> fetchRtcToken({
    required String channelName,
    required int uid,
  }) async {
    final response = await _dio.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'channel': channelName, 'uid': uid},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid token response shape');
    }

    final nested = data['data'];
    final payload = nested is Map<String, dynamic> ? nested : data;
    final token = (payload['token'] as String?)?.trim();
    final expiresIn = payload['expires_in'] as int?;
    if (token == null || token.isEmpty) {
      throw Exception('Token missing in response');
    }
    return AgoraTokenData(token: token, expiresInSeconds: expiresIn);
  }
}
