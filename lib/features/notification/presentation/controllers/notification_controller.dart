import 'package:get/get.dart';

import '../../../../core/data/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository repository;

  NotificationController({required this.repository});

  final RxList<NotificationModel> notifications =
      <NotificationModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isMarkAllLoading = false.obs;
  final RxInt unreadCount = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final int limit = 20;

  @override
  void onInit() {
    super.onInit();
    getNotifications(markAllOnOpen: true);
  }

  Future<void> getNotifications({bool markAllOnOpen = false}) async {
    currentPage.value = 1;
    isLoading.value = true;
    final result = await repository.getNotifications(
      page: currentPage.value,
      limit: limit,
    );

    result.fold(
      (failure) {
        notifications.clear();
        unreadCount.value = 0;
        totalPages.value = 1;
      },
      (response) {
        final payload = response.data;
        notifications.assignAll(payload?.notifications ?? const []);
        unreadCount.value = payload?.unreadCount ?? 0;
        currentPage.value = payload?.pagination?.page ?? 1;
        totalPages.value = payload?.pagination?.totalPages ?? 1;
      },
    );

    isLoading.value = false;

    if (markAllOnOpen && unreadCount.value > 0) {
      await markAllAsRead(silent: true);
    }
  }

  bool get hasMorePages => currentPage.value < totalPages.value;
  bool get canMarkAllAsRead =>
      unreadCount.value > 0 && notifications.isNotEmpty && !isMarkAllLoading.value;

  Future<void> loadMoreNotifications() async {
    if (isLoading.value || isLoadingMore.value || !hasMorePages) {
      return;
    }

    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;
    final result = await repository.getNotifications(page: nextPage, limit: limit);

    result.fold(
      (failure) {},
      (response) {
        final payload = response.data;
        notifications.addAll(payload?.notifications ?? const []);
        unreadCount.value = payload?.unreadCount ?? unreadCount.value;
        currentPage.value = payload?.pagination?.page ?? nextPage;
        totalPages.value = payload?.pagination?.totalPages ?? totalPages.value;
      },
    );

    isLoadingMore.value = false;
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((e) => e.id == id);
    if (index == -1 || notifications[index].isRead) {
      return;
    }

    final result = await repository.markAsRead(id);

    result.fold(
      (failure) {},
      (success) {
        if (success) {
          notifications[index] = notifications[index].copyWith(isRead: true);
          unreadCount.value = unreadCount.value > 0 ? unreadCount.value - 1 : 0;
          notifications.refresh();
        }
      },
    );
  }

  Future<void> markAllAsRead({bool silent = false}) async {
    if (!canMarkAllAsRead) {
      return;
    }

    if (!silent) {
      isMarkAllLoading.value = true;
    }
    final result = await repository.markAllAsRead();

    result.fold(
      (failure) {},
      (success) {
        if (success) {
          notifications.value = notifications
              .map((e) => e.copyWith(isRead: true))
              .toList();
          unreadCount.value = 0;
        }
      },
    );
    if (!silent) {
      isMarkAllLoading.value = false;
    }
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
  }
}
