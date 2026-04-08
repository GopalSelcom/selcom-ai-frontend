import '../../../../core/data/models/notification_model.dart';
import '../../../../core/network/api_service.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20});
  Future<bool> markAsRead(String notificationId);
  Future<bool> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl();

  @override
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "go/notifications",
        method: ApiMethod.get,
        queryParams: {'page': page, 'limit': limit},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final List data = response.data['data'] ?? response.data['response'] ?? [];
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "go/notifications/$notificationId/read",
        method: ApiMethod.put,
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> markAllAsRead() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "go/notifications/read-all",
        method: ApiMethod.put,
      ),
    );
    return response.statusCode == 200;
  }
}
