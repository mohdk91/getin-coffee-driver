import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/ratings/data/driver_ratings_repository.dart';
import 'package:getin_driver/features/ratings/domain/driver_rating_models.dart';

class _Transport implements ApiTransport {
  Map<String, String>? headers;
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    this.headers = headers;
    expect(uri.path, '/api/v1/driver/ratings/51/dispute');
    expect(method, 'POST');
    return const ApiRawResponse(
        statusCode: 201,
        body: '{"success":true,"data":{"id":9,"status":"open"}}');
  }
}

void main() {
  test('Task 131 submits an idempotent Laravel rating dispute', () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final transport = _Transport();
    final repo = ApiDriverRatingsRepository(
      DriverApiContext.create(config, secureStore: store, transport: transport),
    );
    final review = DriverCustomerReview(
      id: '51',
      apiReviewId: 51,
      orderNumber: 'GD-44',
      rating: 2,
      createdAt: DateTime(2026, 10, 1),
      tags: <DriverReviewTag>[],
      comment: 'Incorrect delivery feedback.',
    );
    final result = await repo.submitDispute(
      review: review,
      reason: 'The feedback appears to reference a different delivery.',
    );
    expect(result.success, isTrue);
    expect(transport.headers?['Idempotency-Key'], 'driver-rating-dispute-51');
  });
}
