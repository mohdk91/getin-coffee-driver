import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/ratings/data/driver_ratings_repository.dart';

class _Transport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    if (uri.path.endsWith('/ratings/summary')) {
      return const ApiRawResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"average_rating":4.75,"total_ratings":8,"delivery_count":12,"star_breakdown":{"5":6,"4":1,"3":1,"2":0,"1":0}}}');
    }
    if (uri.path.endsWith('/ratings')) {
      return const ApiRawResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"items":[{"id":51,"rating":5,"comment":"Great delivery","order":{"id":44,"order_number":"GD-44","completed_at":"2026-10-01T01:00:00Z"},"branch":{"id":2,"name":"Stanley"},"dispute":null,"submitted_at":"2026-10-01T01:30:00Z"}]}}');
    }
    return const ApiRawResponse(statusCode: 404, body: '{}');
  }
}

void main() {
  test('Task 130 ratings are loaded from Laravel summary and review list',
      () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final repo = ApiDriverRatingsRepository(
      DriverApiContext.create(config,
          secureStore: store, transport: _Transport()),
    );
    final result = await repo.loadRatings();
    expect(result.isSuccess, isTrue);
    expect(result.snapshot!.averageRating, 4.75);
    expect(result.snapshot!.deliveryCount, 12);
    expect(result.snapshot!.ratingCount, 8);
    expect(result.snapshot!.recentReviews.single.apiReviewId, 51);
  });
}
