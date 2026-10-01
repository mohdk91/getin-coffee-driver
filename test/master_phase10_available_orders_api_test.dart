import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

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
    if (uri.path.endsWith('/eligibility')) {
      return const ApiRawResponse(
        statusCode: 200,
        body:
            '{"success":true,"data":{"eligible":true,"checks":{"approved":true,"online":true,"vehicle":true,"gps_fresh":true,"gps_accurate":true},"details":{"active_orders":0,"max_active_orders":1,"assigned_branch_ids":[4]}}}',
      );
    }
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":[{"id":91,"order_number":"GD-91","branch":{"id":4,"name":"Stanley","city":"Alexandria"},"destination":{"city":"Alexandria","area":"Gleem"},"currency":"EGP"}],"meta":{"total":1}}',
    );
  }
}

void main() {
  test('Task 106 available orders preserve Laravel numeric order id', () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final repo = DriverOrderEligibilityRepositoryFactory.create(
      config,
      context: DriverApiContext.create(
        config,
        secureStore: _AuthenticatedStore(),
        transport: _Transport(),
      ),
    );
    final result = await repo.evaluate(
      availability: DriverAvailabilityState.online,
      activeOrderCount: 0,
      driverApproved: true,
    );
    final order = result.snapshot!.eligibleOrders.single.order;
    expect(order.apiOrderId, 91);
    expect(order.orderNumber, 'GD-91');
    expect(order.destinationArea, 'Gleem');
  });
}
