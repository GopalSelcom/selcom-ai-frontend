import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/support_models.dart';

abstract class SupportRepository {
  Future<Either<Failure, SupportReasonsResponseModel>> getSupportReasons();

  Future<Either<Failure, CreateSupportTicketResponseModel>> createSupportTicket(
    CreateSupportTicketRequestModel request,
  );
}
