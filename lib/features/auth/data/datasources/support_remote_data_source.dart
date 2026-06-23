import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../models/support_models.dart';

abstract class SupportRemoteDataSource {
  Future<SupportReasonsResponseModel> getSupportReasons();

  Future<CreateSupportTicketResponseModel> createSupportTicket(
    CreateSupportTicketRequestModel request,
  );
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  @override
  Future<SupportReasonsResponseModel> getSupportReasons() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.support.reasons,
        method: ApiMethod.get,
        skipAuthInterceptor: true,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return SupportReasonsResponseModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return const SupportReasonsResponseModel(reasons: []);
    }
    throw Exception('Failed to load support reasons');
  }

  @override
  Future<CreateSupportTicketResponseModel> createSupportTicket(
    CreateSupportTicketRequestModel request,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.support.tickets,
        method: ApiMethod.post,
        body: request.toJson(),
        skipAuthInterceptor: true,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data != null) {
      return CreateSupportTicketResponseModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      final data = response.data;
      if (data is Map) {
        return CreateSupportTicketResponseModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      return const CreateSupportTicketResponseModel(
        statusCode: 400,
        message: '',
      );
    }
    final data = response.data;
    final message = data is Map ? data['message']?.toString() : null;
    throw Exception(message ?? 'Failed to create support ticket');
  }
}
