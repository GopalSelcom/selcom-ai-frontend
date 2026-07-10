import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/set_name_request.dart';
import '../../../../core/data/models/responses/set_name_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Persists the rider's display name when SSO did not provide one.
class SetNameUseCase
    implements UseCase<SetNameResponseModel?, SetNameRequest> {
  SetNameUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, SetNameResponseModel?>> call(SetNameRequest params) {
    return repository.setName(request: params);
  }
}
