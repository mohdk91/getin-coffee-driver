import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/commissions/data/driver_commission_repository.dart';
import 'package:getin_driver/features/commissions/domain/driver_commission_models.dart';

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
            '{"success":true,"data":{"items":[{"id":5,"currency":"EGP","earned_at":"2026-10-01T01:00:00Z","components":{"base_earning":"70.00","distance_km":"6.2","distance_bonus":"25.00","peak_bonus":"20.00","customer_tip":"10.00","positive_adjustment":"0.00","negative_adjustment":"2.50"},"policy":{"version_number":4,"effective_at":"2026-09-01T00:00:00Z"}}]}}');
  }
}

void main() {
  test('Task 129 commission breakdown comes from backend earning snapshot',
      () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final repo = ApiDriverCommissionRepository(
      DriverApiContext.create(config,
          secureStore: store, transport: _Transport()),
    );
    final result = await repo.loadPolicy();
    expect(result.isSuccess, isTrue);
    expect(result.policy!.policyVersion, 'Policy v4');
    expect(result.policy!.activeRules.length, 5);
    expect(
      result.policy!.activeRules.map((r) => r.category).toSet(),
      containsAll(DriverCommissionRuleCategory.values),
    );
  });
}
