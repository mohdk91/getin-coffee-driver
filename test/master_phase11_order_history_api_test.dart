import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/active_delivery/domain/driver_delivery_state_machine.dart';
import 'package:getin_driver/features/order_history/data/driver_order_history_repository.dart';

class _Transport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    expect(uri.path, '/api/v1/driver/history');
    return const ApiRawResponse(
        statusCode: 200,
        body:
            '{"success":true,"data":{"items":[{"order_id":44,"order_number":"GD-44","delivery_state":"delivered","occurred_at":"2026-10-01T01:00:00Z","branch":{"id":2,"name":"Stanley","city":"Alexandria"},"destination":{"area":"San Stefano","city":"Alexandria"},"bag_count":2,"earning":{"amount":"122.50","currency":"EGP"},"note":null}]}}');
  }
}

void main() {
  test('Task 127 loads server-owned driver order history', () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final repo = ApiDriverOrderHistoryRepository(
      DriverApiContext.create(config,
          secureStore: store, transport: _Transport()),
    );
    final result = await repo.load();
    expect(result.isSuccess, isTrue);
    final item = result.snapshot!.items.single;
    expect(item.orderNumber, 'GD-44');
    expect(item.state, DriverDeliveryState.delivered);
    expect(item.bagCount, 2);
    expect(item.driverEarning, 122.5);
  });
}
