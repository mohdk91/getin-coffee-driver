import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_rating_models.dart';

abstract interface class DriverRatingsRepository {
  DriverRatingsDataSource get source;
  Future<DriverRatingsLoadResult> loadRatings();
}

class DriverRatingsRepositoryFactory {
  DriverRatingsRepositoryFactory._();

  static DriverRatingsRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.isApiConfigured) {
      return ApiDriverRatingsRepository(
        context ?? DriverApiContext.create(config),
      );
    }
    return config.environment == AppEnvironment.development
        ? const DemoDriverRatingsRepository()
        : const UnavailableDriverRatingsRepository();
  }
}

class ApiDriverRatingsRepository implements DriverRatingsRepository {
  final DriverApiContext context;
  const ApiDriverRatingsRepository(this.context);

  @override
  DriverRatingsDataSource get source => DriverRatingsDataSource.api;

  @override
  Future<DriverRatingsLoadResult> loadRatings() async {
    try {
      final summary = DriverApiContext.dataMap(
        await context.apiClient.getJson(
          '/v1/driver/ratings/summary',
          authenticated: true,
        ),
      );
      final listEnvelope = await context.apiClient.getJson(
        '/v1/driver/ratings',
        query: const <String, Object?>{'per_page': 50},
        authenticated: true,
      );
      final reviews = DriverApiContext.nestedItems(listEnvelope)
          .whereType<Map>()
          .map((raw) => _review(Map<String, dynamic>.from(raw)))
          .toList(growable: false);

      final breakdownRaw = summary['star_breakdown'] is Map
          ? Map<String, dynamic>.from(summary['star_breakdown'] as Map)
          : const <String, dynamic>{};

      return DriverRatingsLoadResult.success(
        DriverRatingsSnapshot(
          averageRating:
              double.tryParse(summary['average_rating']?.toString() ?? '') ?? 0,
          deliveryCount: (summary['delivery_count'] as num?)?.toInt() ??
              (summary['total_ratings'] as num?)?.toInt() ??
              reviews.length,
          ratingCount:
              (summary['total_ratings'] as num?)?.toInt() ?? reviews.length,
          distribution: [
            for (var stars = 5; stars >= 1; stars--)
              DriverRatingBucket(
                stars: stars,
                count: (breakdownRaw['$stars'] as num?)?.toInt() ?? 0,
              ),
          ],
          tagSummary: const <DriverReviewTagSummary>[],
          recentReviews: reviews,
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (error) {
      return DriverRatingsLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverRatingsLoadResult.failure(error.message);
    }
  }

  DriverCustomerReview _review(Map<String, dynamic> raw) {
    final order = raw['order'] is Map
        ? Map<String, dynamic>.from(raw['order'] as Map)
        : const <String, dynamic>{};
    final dispute = raw['dispute'] is Map
        ? Map<String, dynamic>.from(raw['dispute'] as Map)
        : const <String, dynamic>{};
    final id = (raw['id'] as num?)?.toInt();

    return DriverCustomerReview(
      id: id?.toString() ?? '',
      apiReviewId: id,
      orderNumber: order['order_number']?.toString() ?? '',
      rating: (raw['rating'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(raw['submitted_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      tags: const <DriverReviewTag>[],
      comment: raw['comment']?.toString(),
      disputeStatus: dispute['status']?.toString(),
    );
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
