import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_contact_repository.dart';

class _Transport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    expect(uri.path, '/api/v1/driver/orders/44/customer-contact/call');
    expect(method, 'POST');
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"placed":false,"provider":"unconfigured","call_reference":null,"message":"Protected calling is not configured. No call was placed and the customer phone number remains hidden."}}',
    );
  }
}

void main() {
  test('Task 126 protected contact never requires a raw customer phone',
      () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final repo = ApiDriverCustomerContactRepository(
      DriverApiContext.create(config,
          secureStore: store, transport: _Transport()),
    );
    final result =
        await repo.callCustomer(orderNumber: 'GD-44', apiOrderId: 44);
    expect(result.placed, isFalse);
    expect(result.message, contains('phone number remains hidden'));
  });
}
