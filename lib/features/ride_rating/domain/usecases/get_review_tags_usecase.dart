import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ride_rating_tag_entity.dart';
import '../repositories/ride_rating_repository.dart';

class GetReviewTagsUseCase {
  final RideRatingRepository repository;

  GetReviewTagsUseCase(this.repository);

  Future<Either<Failure, List<RideRatingTagEntity>>> call({
    required int rating,
  }) {
    return repository.getReviewTags(rating: rating);
  }
}
