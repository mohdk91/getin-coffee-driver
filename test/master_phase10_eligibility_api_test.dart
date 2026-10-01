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
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    if (uri.path.endsWith('/v1/driver/eligibility')) {
      return const ApiRawResponse(
        statusCode: 200,
        body:
            '{"success":true,"data":{"eligible":true,"reasons":[],"checks":{"approved":true,"online":true,"vehicle":true,"gps_fresh":true,"gps_accurate":true},"details":{"active_orders":0,"max_active_orders":1,"gps_age_seconds":10,"gps_accuracy_meters":8,"assigned_branch_ids":[4],"matched_region_id":7}}}',
      );
    }

    if (uri.path.endsWith('/v1/driver/orders/available') ||
        uri.path.endsWith('/v1/driver/order-offers')) {
      return const ApiRawResponse(
        statusCode: 200,
        body: '{"success":true,"data":[]}',
      );
    }

    return const ApiRawResponse(
      statusCode: 404,
      body: '{"success":false,"message":"Unexpected test endpoint."}',
    );
  }
}

void main() {
  test('Task 105 production eligibility is based on Laravel checks', () async {
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
      availability: DriverAvailabilityState.offline,
      activeOrderCount: 0,
      driverApproved: false,
    );
    expect(repo.source, DriverOrderEligibilityDataSource.api);
    expect(result.isSuccess, isTrue);
    expect(result.snapshot?.context.driverApproved, isTrue);
    expect(result.snapshot?.context.maxActiveOrders, 1);
  });
}
