import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/earnings/data/driver_earnings_repository.dart';
import 'package:getin_driver/features/earnings/domain/driver_earnings_models.dart';

class _Transport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    expect(uri.path, '/api/v1/driver/earnings');
    expect(uri.queryParameters['date_from'], isNotNull);
    return const ApiRawResponse(
        statusCode: 200,
        body:
            '{"success":true,"data":{"items":[{"id":5,"status":"approved","currency":"EGP","order":{"id":44,"order_number":"GD-44","completed_at":"2026-10-01T01:00:00Z","destination_area":"San Stefano","destination_city":"Alexandria"},"branch":{"id":2,"name":"Stanley","city":"Alexandria"},"components":{"base_earning":"70.00","distance_km":"6.2","distance_bonus":"25.00","peak_bonus":"20.00","customer_tip":"10.00","positive_adjustment":"0.00","negative_adjustment":"2.50","final_earning":"122.50"},"adjustments":[{"reason":"Service adjustment"}],"earned_at":"2026-10-01T01:00:00Z"}]}}');
  }
}

void main() {
  test('Task 128 maps authoritative earning components', () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final repo = ApiDriverEarningsRepository(
      DriverApiContext.create(config,
          secureStore: store, transport: _Transport()),
    );
    final result = await repo.load(DriverEarningsPeriod.today);
    expect(result.isSuccess, isTrue);
    final item = result.snapshot!.deliveries.single;
    expect(item.orderNumber, 'GD-44');
    expect(item.destinationArea, 'San Stefano');
    expect(item.totalEarning, 122.5);
    expect(item.adjustments, -2.5);
  });
}
