import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationModel>>> getNotifications({int page = 1, int limit = 20});
  Future<Either<Failure, bool>> markAsRead(String notificationId);
  Future<Either<Failure, bool>> markAllAsRead();
}
