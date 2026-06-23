import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_data_source.dart';
import '../models/support_models.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl({required this.remoteDataSource});

  final SupportRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, SupportReasonsResponseModel>>
  getSupportReasons() async {
    try {
      final result = await remoteDataSource.getSupportReasons();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(_messageFrom(e)));
    }
  }

  @override
  Future<Either<Failure, CreateSupportTicketResponseModel>> createSupportTicket(
    CreateSupportTicketRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.createSupportTicket(request);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(_messageFrom(e)));
    }
  }

  String _messageFrom(Object error) {
    if (error is Exception) {
      final raw = error.toString();
      const prefix = 'Exception: ';
      if (raw.startsWith(prefix)) {
        return raw.substring(prefix.length);
      }
      return raw;
    }
    return error.toString();
  }
}
