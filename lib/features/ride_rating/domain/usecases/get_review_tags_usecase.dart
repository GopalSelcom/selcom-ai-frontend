import 'package:dartz/dartz.dart';

import '../../../../core/data/models/responses/rides/review_tags_response.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ride_rating_repository.dart';

class GetReviewTagsUseCase {
  final RideRatingRepository repository;

  GetReviewTagsUseCase(this.repository);

  Future<Either<Failure, List<ReviewTagModel>>> call({
    required int rating,
  }) {
    return repository.getReviewTags(rating: rating);
  }
}
