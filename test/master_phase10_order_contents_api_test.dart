import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/order_contents/data/driver_order_contents_repository.dart';

class _AuthenticatedStore extends MemorySecureStore {
  @override
  Future<String?> read(String key) async {
    if (key == SecureStoreKeys.accessToken) {
      return 'phase10-driver-token';
    }
    return super.read(key);
  }
}

class _Transport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"id":91,"order_number":"GD-91","customer_notes":"Leave at reception","items":[{"quantity":2,"notes":"Keep upright"},{"quantity":1,"notes":null}]}}',
    );
  }
}

void main() {
  test('Task 109 driver contents are read from assigned Laravel order',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final repo = DriverOrderContentsRepositoryFactory.create(
      config,
      context: DriverApiContext.create(
        config,
        secureStore: _AuthenticatedStore(),
        transport: _Transport(),
      ),
    );
    final result = await repo.load(orderNumber: 'GD-91', apiOrderId: 91);
    expect(result.isSuccess, isTrue);
    expect(result.contents?.itemCount, 3);
    expect(result.contents?.handlingInstructions, contains('Keep upright'));
    expect(
        result.contents?.customerDeliveryNotes, contains('Leave at reception'));
  });
}
