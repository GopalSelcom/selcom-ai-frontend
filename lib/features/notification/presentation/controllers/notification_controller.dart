import 'package:get/get.dart';

import '../../../../core/data/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository repository;

  NotificationController({required this.repository});

  final RxList<NotificationModel> notifications =
      <NotificationModel>[].obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getNotifications();
  }

  Future<void> getNotifications() async {
    isLoading.value = true;

    /// TODO: Replace with real API integration (already wired)
    final result = await repository.getNotifications();

    result.fold(
      (failure) {
        notifications.clear();
      },
      (data) {
        notifications.assignAll(data);
      },
    );

    isLoading.value = false;
  }

  Future<void> markAsRead(String id) async {
    final result = await repository.markAsRead(id);

    result.fold(
      (failure) {},
      (success) {
        if (success) {
          final index = notifications.indexWhere((e) => e.id == id);
          if (index != -1) {
            notifications[index] = NotificationModel(
              id: notifications[index].id,
              title: notifications[index].title,
              message: notifications[index].message,
              isRead: true,
              timestamp: notifications[index].timestamp,
            );
            notifications.refresh();
          }
        }
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result = await repository.markAllAsRead();

    result.fold(
      (failure) {},
      (success) {
        if (success) {
          notifications.value = notifications
              .map((e) => NotificationModel(
                    id: e.id,
                    title: e.title,
                    message: e.message,
                    isRead: true,
                    timestamp: e.timestamp,
                  ))
              .toList();
        }
      },
    );
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
  }
}
