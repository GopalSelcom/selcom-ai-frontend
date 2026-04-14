import '../../../../core/data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  });

  Future<bool> markAsRead(String notificationId);

  Future<bool> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl();

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      /// TODO: Enable API when backend is ready
      /*
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: "go/notifications",
          method: ApiMethod.get,
          queryParams: {'page': page, 'limit': limit},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List data =
            response.data['data'] ?? response.data['response'] ?? [];

        return data
            .map((e) => NotificationResponse.fromJson(e))
            .toList();
      }
      */

      /// TEMP: Static dummy response
      await Future.delayed(const Duration(milliseconds: 500));

      return [
        NotificationModel(
          id: "1",
          title: "Ride Accepted",
          message: "Your ride has been accepted by driver",
          isRead: false,
          timestamp: "2026-04-14 10:50:20",
          type: 1, // Ride 🚗
        ),
        NotificationModel(
          id: "4",
          title: "Driver Arrived",
          message: "Your driver has arrived at pickup point",
          isRead: false,
          timestamp: "2026-04-14 09:30:00",
          type: 1, // Ride 🚗
        ),
        NotificationModel(
          id: "3",
          title: "Promo Applied",
          message: "You got 20% discount on your ride",
          isRead: false,
          timestamp: "2026-04-10 10:50:20",
          type: 2, // Promotion 🎁
        ),
        NotificationModel(
          id: "5",
          title: "Wallet Credited",
          message: "₹50 cashback added to your wallet",
          isRead: true,
          timestamp: "2026-04-12 14:15:00",
          type: 3, // Payment 💰
        ),
        NotificationModel(
          id: "2",
          title: "Payment Successful",
          message: "Payment of ₹120 completed successfully",
          isRead: true,
          timestamp: "2026-04-01 10:50:20",
          type: 3, // Payment 💰
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    /// TODO: Enable API when backend is ready
    /*
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "go/notifications/$notificationId/read",
        method: ApiMethod.put,
      ),
    );
    return response.statusCode == 200;
    */

    /// TEMP: simulate success
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> markAllAsRead() async {
    /// TODO: Enable API when backend is ready
    /*
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: "go/notifications/read-all",
        method: ApiMethod.put,
      ),
    );
    return response.statusCode == 200;
    */

    /// TEMP: simulate success
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
