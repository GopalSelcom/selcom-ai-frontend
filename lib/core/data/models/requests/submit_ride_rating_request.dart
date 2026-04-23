class SubmitRideRatingRequest {
  final String rideId;
  final int rating;
  final List<String> tags;
  final String comment;

  const SubmitRideRatingRequest({
    required this.rideId,
    required this.rating,
    required this.tags,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'tags': tags,
      if (comment.trim().isNotEmpty) 'comment': comment.trim(),
    };
  }
}
