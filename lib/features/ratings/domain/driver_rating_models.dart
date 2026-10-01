enum DriverRatingsDataSource { demo, api }

enum DriverReviewTag {
  fastDelivery,
  friendly,
  carefulHandling,
  easyCommunication,
  late,
}

extension DriverReviewTagPresentation on DriverReviewTag {
  String get label => switch (this) {
        DriverReviewTag.fastDelivery => 'Fast delivery',
        DriverReviewTag.friendly => 'Friendly',
        DriverReviewTag.carefulHandling => 'Careful handling',
        DriverReviewTag.easyCommunication => 'Easy communication',
        DriverReviewTag.late => 'Late',
      };
}

class DriverRatingBucket {
  final int stars;
  final int count;

  const DriverRatingBucket({required this.stars, required this.count});
}

class DriverReviewTagSummary {
  final DriverReviewTag tag;
  final int count;

  const DriverReviewTagSummary({required this.tag, required this.count});
}

class DriverCustomerReview {
  final String id;
  final int? apiReviewId;
  final String orderNumber;
  final int rating;
  final DateTime createdAt;
  final List<DriverReviewTag> tags;
  final String? comment;
  final String? disputeStatus;

  const DriverCustomerReview({
    required this.id,
    this.apiReviewId,
    required this.orderNumber,
    required this.rating,
    required this.createdAt,
    required this.tags,
    this.comment,
    this.disputeStatus,
  });
}

class DriverRatingsSnapshot {
  final double averageRating;
  final int deliveryCount;
  final int ratingCount;
  final List<DriverRatingBucket> distribution;
  final List<DriverReviewTagSummary> tagSummary;
  final List<DriverCustomerReview> recentReviews;
  final DateTime updatedAt;

  const DriverRatingsSnapshot({
    required this.averageRating,
    required this.deliveryCount,
    required this.ratingCount,
    required this.distribution,
    required this.tagSummary,
    required this.recentReviews,
    required this.updatedAt,
  });

  int get distributionCount => distribution.fold<int>(
        0,
        (total, bucket) => total + bucket.count,
      );

  DriverRatingBucket bucketFor(int stars) => distribution.firstWhere(
        (bucket) => bucket.stars == stars,
        orElse: () => DriverRatingBucket(stars: stars, count: 0),
      );
}

class DriverRatingsLoadResult {
  final DriverRatingsSnapshot? snapshot;
  final String? errorMessage;

  const DriverRatingsLoadResult._({this.snapshot, this.errorMessage});

  const DriverRatingsLoadResult.success(DriverRatingsSnapshot value)
      : this._(snapshot: value);

  const DriverRatingsLoadResult.failure(String message)
      : this._(errorMessage: message);

  bool get isSuccess => snapshot != null;
}
