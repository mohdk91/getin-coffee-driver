import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/ratings/data/driver_ratings_repository.dart';
import 'package:getin_driver/features/ratings/domain/driver_rating_models.dart';

void main() {
  test('Task 28 demo ratings expose summary distribution tags and reviews',
      () async {
    const repository = DemoDriverRatingsRepository();

    final result = await repository.loadRatings();

    expect(result.isSuccess, isTrue);
    final snapshot = result.snapshot!;
    expect(snapshot.averageRating, 4.9);
    expect(snapshot.deliveryCount, 164);
    expect(snapshot.ratingCount, 126);
    expect(snapshot.distributionCount, 126);
    expect(snapshot.bucketFor(5).count, 116);
    expect(snapshot.tagSummary.length, 5);
    expect(
      snapshot.tagSummary.any(
        (item) => item.tag == DriverReviewTag.fastDelivery,
      ),
      isTrue,
    );
    expect(snapshot.recentReviews, isNotEmpty);
  });

  test('Task 28 production repository never invents ratings', () async {
    const repository = UnavailableDriverRatingsRepository();

    final result = await repository.loadRatings();

    expect(result.isSuccess, isFalse);
    expect(result.snapshot, isNull);
    expect(result.errorMessage, contains('not connected to the Laravel API'));
  });
}
