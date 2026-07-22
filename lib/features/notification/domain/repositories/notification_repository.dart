import 'package:dartz/dartz.dart';

import '../../../../core/data/models/notification_model.dart';
import '../../../../core/errors/failures.dart';

abstract class NotificationRepository {
  Future<Either<Failure, NotificationPayloadModel>> getNotifications({
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, bool>> markAsRead(String notificationId);

  Future<Either<Failure, bool>> markAllAsRead();
}
