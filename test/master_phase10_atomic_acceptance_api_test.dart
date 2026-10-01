import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/eligibility/domain/driver_order_eligibility_models.dart';
import 'package:getin_driver/features/orders/data/driver_order_acceptance_repository.dart';

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
  Map<String, String>? headers;
  Uri? uri;

  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    this.uri = uri;
    this.headers = headers;
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"assignment_id":72,"accepted_at":"2026-10-01T00:00:00Z","order":{"id":91,"order_number":"GD-91"}}}',
    );
  }
}

void main() {
  test('Task 108 acceptance uses Laravel numeric id and idempotency key',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final transport = _Transport();
    final repo = DriverOrderAcceptanceRepositoryFactory.create(
      config,
      context: DriverApiContext.create(
        config,
        secureStore: _AuthenticatedStore(),
        transport: transport,
      ),
    );
    const order = DriverOrderCandidate(
      apiOrderId: 91,
      orderNumber: 'GD-91',
      pickupBranch: 'Stanley',
      region: '',
      zone: '',
      destinationArea: 'Gleem',
      distanceToBranchKm: 0,
      deliveryDistanceKm: 0,
      allowedVehicleTypes: <String>[],
      isAvailable: true,
    );
    final result = await repo.accept(order: order, driverId: 'ignored-live-id');

    expect(result.isAccepted, isTrue);
    expect(transport.uri?.path, '/api/v1/driver/orders/91/accept');
    expect(transport.headers?['Idempotency-Key'], 'driver-order-accept-91');
  });
}
