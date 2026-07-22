import '../../../../core/data/models/notification_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPayloadModel> getNotifications({
    int page = 1,
    int limit = 20,
  });

  Future<bool> markAsRead(String notificationId);

  Future<bool> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl();

  @override
  Future<NotificationPayloadModel> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.notification.list,
        method: ApiMethod.get,
        queryParams: {'page': page, 'limit': limit},
      ),
    );

    if (response.data is Map<String, dynamic>) {
      return NotificationPayloadModel.fromJson(response.data);
    }

    final responseData = response.data;
    final message = responseData is Map<String, dynamic>
        ? responseData['message']?.toString()
        : null;

    return NotificationPayloadModel(
      statusCode: response.statusCode,
      message: message,
      data: Data(notifications: const [], unreadCount: 0),
    );
  }

  bool _isSuccess(int? statusCode) {
    return statusCode == 200 || statusCode == 201;
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.notification.readById(notificationId),
        method: ApiMethod.post,
      ),
    );

    return _isSuccess(response.statusCode);
  }

  @override
  Future<bool> markAllAsRead() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.notification.readAll,
        method: ApiMethod.post,
      ),
    );

    return _isSuccess(response.statusCode);
  }
}
