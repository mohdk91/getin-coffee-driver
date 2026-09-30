import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/profile/data/driver_profile_repository.dart';
import 'package:getin_driver/features/profile/domain/driver_profile_models.dart';

class _ProfileTransport implements ApiTransport {
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
          '{"success":true,"data":{"id":8,"name":"Live Driver","email":"driver@example.com","phone":"+201000000000","approval_status":"approved","assigned_regions":[{"id":1,"name":"East Alexandria"}],"assigned_branches":[{"id":2,"name":"Stanley"}],"updated_at":"2026-10-01T00:00:00Z"}}',
    );
  }
}

void main() {
  test('Phase 9 profile maps Laravel assignments and approval', () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final secure = MemorySecureStore();
    await secure.write(SecureStoreKeys.accessToken, 'token');
    final repository = ApiDriverProfileRepository(
      DriverApiContext.create(config,
          secureStore: secure, transport: _ProfileTransport()),
    );

    final result = await repository.loadProfile();
    expect(result.isSuccess, isTrue);
    expect(result.profile?.fullName, 'Live Driver');
    expect(result.profile?.assignedRegion, 'East Alexandria');
    expect(result.profile?.assignedBranches, contains('Stanley'));
    expect(result.profile?.verificationStatus,
        DriverProfileVerificationStatus.approved);
  });
}
