import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_rating_models.dart';

abstract interface class DriverRatingsRepository {
  DriverRatingsDataSource get source;
  Future<DriverRatingsLoadResult> loadRatings();
}

class DriverRatingsRepositoryFactory {
  DriverRatingsRepositoryFactory._();

  static DriverRatingsRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverRatingsRepository()
        : const UnavailableDriverRatingsRepository();
  }
}

class DemoDriverRatingsRepository implements DriverRatingsRepository {
  const DemoDriverRatingsRepository();

  @override
  DriverRatingsDataSource get source => DriverRatingsDataSource.demo;

  @override
  Future<DriverRatingsLoadResult> loadRatings() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final now = DateTime.now();

    return DriverRatingsLoadResult.success(
      DriverRatingsSnapshot(
        averageRating: 4.9,
        deliveryCount: 164,
        ratingCount: 126,
        distribution: const [
          DriverRatingBucket(stars: 5, count: 116),
          DriverRatingBucket(stars: 4, count: 8),
          DriverRatingBucket(stars: 3, count: 2),
          DriverRatingBucket(stars: 2, count: 0),
          DriverRatingBucket(stars: 1, count: 0),
        ],
        tagSummary: const [
          DriverReviewTagSummary(
            tag: DriverReviewTag.fastDelivery,
            count: 98,
          ),
          DriverReviewTagSummary(
            tag: DriverReviewTag.friendly,
            count: 87,
          ),
          DriverReviewTagSummary(
            tag: DriverReviewTag.carefulHandling,
            count: 79,
          ),
          DriverReviewTagSummary(
            tag: DriverReviewTag.easyCommunication,
            count: 68,
          ),
          DriverReviewTagSummary(tag: DriverReviewTag.late, count: 2),
        ],
        recentReviews: [
          DriverCustomerReview(
            id: 'review-demo-2481',
            orderNumber: 'GD-2481',
            rating: 5,
            createdAt: now.subtract(const Duration(days: 1)),
            tags: const [
              DriverReviewTag.fastDelivery,
              DriverReviewTag.friendly,
            ],
            comment: 'Quick and friendly delivery. Thank you.',
          ),
          DriverCustomerReview(
            id: 'review-demo-2468',
            orderNumber: 'GD-2468',
            rating: 5,
            createdAt: now.subtract(const Duration(days: 3)),
            tags: const [
              DriverReviewTag.carefulHandling,
              DriverReviewTag.easyCommunication,
            ],
            comment: 'The bags arrived in perfect condition.',
          ),
          DriverCustomerReview(
            id: 'review-demo-2442',
            orderNumber: 'GD-2442',
            rating: 4,
            createdAt: now.subtract(const Duration(days: 5)),
            tags: const [
              DriverReviewTag.fastDelivery,
              DriverReviewTag.easyCommunication,
            ],
          ),
          DriverCustomerReview(
            id: 'review-demo-2415',
            orderNumber: 'GD-2415',
            rating: 3,
            createdAt: now.subtract(const Duration(days: 8)),
            tags: const [DriverReviewTag.late],
            comment: 'Delivery was polite, but later than expected.',
          ),
        ],
        updatedAt: now,
      ),
    );
  }
}

class UnavailableDriverRatingsRepository implements DriverRatingsRepository {
  const UnavailableDriverRatingsRepository();

  @override
  DriverRatingsDataSource get source => DriverRatingsDataSource.api;

  @override
  Future<DriverRatingsLoadResult> loadRatings() async {
    return const DriverRatingsLoadResult.failure(
      'Driver ratings and reviews are not connected to the Laravel API yet. Getin will not invent production ratings, reviews or customer feedback.',
    );
  }
}
