import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/save_user_additional_details_request.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SaveUserAdditionalDetailsUseCase {
  final AuthRepository repository;

  SaveUserAdditionalDetailsUseCase(this.repository);

  Future<Either<Failure, UserModel>> call({
    required SaveUserAdditionalDetailsRequest request,
  }) {
    return repository.saveUserAdditionalDetails(request: request);
  }
}
