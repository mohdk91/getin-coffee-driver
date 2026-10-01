import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/assignment/data/driver_assignment_repository.dart';
import 'package:getin_driver/features/assignment/domain/driver_assignment_models.dart';

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
    return const ApiRawResponse(
      statusCode: 200,
      body:
          '{"success":true,"data":{"branches":[{"id":4,"name":"Stanley","city":"Alexandria","is_primary":true}],"regions":[{"id":7,"name":"East Alexandria","city":"Alexandria","radius_km":8.5,"is_primary":true}]}}',
    );
  }
}

void main() {
  test('Task 102 maps Laravel branch and region assignments', () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final context = DriverApiContext.create(
      config,
      secureStore: _AuthenticatedStore(),
      transport: _Transport(),
    );
    final repository = DriverAssignmentRepositoryFactory.create(
      config,
      context: context,
    );
    final result = await repository.loadAssignment();

    expect(repository.source, DriverAssignmentDataSource.api);
    expect(result.isSuccess, isTrue);
    expect(result.assignment?.assignedCity, 'Alexandria');
    expect(result.assignment?.allowedBranches.single.name, 'Stanley');
    expect(result.assignment?.serviceRadiusKm, 8.5);
  });
}
