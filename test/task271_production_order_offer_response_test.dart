import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/orders/data/driver_order_offer_response_repository.dart';

class _Transport implements ApiTransport {
  Uri? uri;
  String? method;
  Map<String, String>? headers;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    this.uri = uri;
    this.method = method;
    this.headers = headers;
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"id":77,"status":"rejected"},"message":"Delivery offer rejected."}',
    );
  }
}

void main() {
  test('Task 271 rejects a production offer through its authoritative endpoint',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final transport = _Transport();
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final repository = ApiDriverOrderOfferResponseRepository(
      DriverApiContext.create(
        config,
        secureStore: store,
        transport: transport,
      ),
    );

    final result = await repository.reject(77);

    expect(result.success, isTrue);
    expect(transport.method, 'POST');
    expect(transport.uri?.path, '/api/v1/driver/order-offers/77/reject');
    expect(transport.headers?['Idempotency-Key'], 'driver-offer-reject-77');
  });
}
