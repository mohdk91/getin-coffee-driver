import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/home/data/driver_home_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

class _HomeTransport implements ApiTransport {
  final List<String> paths = <String>[];

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    paths.add(uri.path);
    final payload = switch (uri.path) {
      '/api/v1/driver/availability' =>
        '{"success":true,"data":{"status":"online"}}',
      '/api/v1/driver/runtime' =>
        '{"success":true,"data":{"active_delivery":{"id":91,"order_number":"GD-91","delivery_state":"out_for_delivery","branch":{"name":"Stanley"},"delivery":{"area":"San Stefano"}}}}',
      '/api/v1/driver/orders/available' =>
        '{"success":true,"data":[],"meta":{"total":3}}',
      '/api/v1/driver/order-offers' =>
        '{"success":true,"data":[{"id":77,"status":"offered"}]}',
      '/api/v1/driver/earnings/summary' =>
        '{"success":true,"data":{"currencies":[{"currency":"EGP","records":4,"final_earning":"286.50"}]}}',
      '/api/v1/driver/ratings/summary' =>
        '{"success":true,"data":{"average_rating":4.8,"total_ratings":52}}',
      '/api/v1/driver/notifications/unread-count' =>
        '{"success":true,"data":{"unread_count":2}}',
      '/api/v1/driver/location' =>
        '{"success":true,"data":{"latitude":31.2,"longitude":29.9,"accuracy":12,"timestamp":"${DateTime.now().toUtc().toIso8601String()}"}}',
      '/api/v1/driver/location/policy' =>
        '{"success":true,"data":{"quality":{"max_stale_seconds":180,"max_accuracy_meters":100}}}',
      _ => throw StateError('Unexpected path ${uri.path}'),
    };
    return ApiRawResponse(statusCode: 200, body: payload);
  }
}

void main() {
  test('Task 270 home uses authoritative runtime, finance, rating and GPS data',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final transport = _HomeTransport();
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final repository = ApiDriverHomeRepository(
      DriverApiContext.create(
        config,
        secureStore: store,
        transport: transport,
      ),
    );

    final result = await repository.loadDashboard();

    expect(result.isSuccess, isTrue);
    final snapshot = result.snapshot!;
    expect(snapshot.availability, DriverAvailabilityState.online);
    expect(snapshot.activeDelivery?.apiOrderId, 91);
    expect(snapshot.activeDelivery?.orderNumber, 'GD-91');
    expect(snapshot.availableOrders, 4);
    expect(snapshot.completedToday, 4);
    expect(snapshot.earningsToday, 286.50);
    expect(snapshot.rating, 4.8);
    expect(snapshot.ratingCount, 52);
    expect(snapshot.unreadNotifications, 2);
    expect(snapshot.gpsState, DriverGpsState.ready);
    expect(transport.paths, contains('/api/v1/driver/runtime'));
    expect(transport.paths, contains('/api/v1/driver/order-offers'));
    expect(transport.paths, contains('/api/v1/driver/earnings/summary'));
  });
}
