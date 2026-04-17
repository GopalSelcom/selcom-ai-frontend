import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../../../../core/data/models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, NotificationResponseModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await remoteDataSource.getNotifications(
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(String notificationId) async {
    try {
      final result = await remoteDataSource.markAsRead(notificationId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead() async {
    try {
      final result = await remoteDataSource.markAllAsRead();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
