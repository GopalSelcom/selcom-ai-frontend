import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/share_link_entity.dart';
import '../../domain/repositories/ride_share_repository.dart';
import '../datasources/ride_share_remote_datasource.dart';

class RideShareRepositoryImpl implements RideShareRepository {
  final RideShareRemoteDataSource remoteDataSource;

  RideShareRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ShareLinkEntity>> generateShareLink(String rideId) async {
    try {
      final result = await remoteDataSource.generateShareLink(rideId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> revokeShareLink(String rideId) async {
    try {
      await remoteDataSource.revokeShareLink(rideId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    }
  }

  String _extractMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString().trim();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }
}
