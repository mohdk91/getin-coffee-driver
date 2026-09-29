import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/network/api_client.dart';
import 'package:getin_driver/core/network/api_retry_policy.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/system/mobile_system_config_repository.dart';
import 'package:getin_driver/core/offline/mobile_system_config_cache.dart';
import 'package:getin_driver/core/system/mobile_system_config.dart';

class _OfflineTransport implements ApiTransport {
  const _OfflineTransport();

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) {
    return Future<ApiRawResponse>.error(StateError('offline'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mobile system config cache round-trips a fresh config', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const cache = MobileSystemConfigCache(maxAge: Duration(hours: 1));
    final config = MobileSystemConfig.fromApiEnvelope(<String, dynamic>{
      'data': <String, dynamic>{
        'api_version': 'v1',
        'mobile_apps': <String, dynamic>{
          'ios': <String, dynamic>{
            'minimum_version': '1.0.0',
            'latest_version': '1.0.0'
          },
          'android': <String, dynamic>{
            'minimum_version': '1.0.0',
            'latest_version': '1.1.0'
          },
          'maintenance': <String, dynamic>{'enabled': false},
        },
        'client': <String, dynamic>{
          'platform': 'android',
          'update_required': false
        },
        'languages': <String, dynamic>{
          'default': 'en',
          'supported': <String>['en', 'ar']
        },
        'features': <String, dynamic>{
          'customer': <String, dynamic>{'app': true, 'ordering': true},
          'driver': <String, dynamic>{'app': true, 'orders': true},
        },
      },
    });

    await cache.write(
      config,
      platform: 'android',
      version: '1.0.0',
    );
    final restored = await cache.readFresh(
      platform: 'android',
      version: '1.0.0',
    );

    expect(restored, isNotNull);
    expect(restored!.android.latestVersion, '1.1.0');
    expect(restored.customerFeatures.enabled('ordering'), isTrue);
    expect(restored.driverFeatures.enabled('orders'), isTrue);
  });

  test('system config repository falls back to a fresh cache while offline',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const cache = MobileSystemConfigCache(maxAge: Duration(hours: 1));
    final cachedConfig = MobileSystemConfig.fromApiEnvelope(<String, dynamic>{
      'data': <String, dynamic>{
        'api_version': 'v1',
        'mobile_apps': <String, dynamic>{
          'ios': <String, dynamic>{
            'minimum_version': '1.0.0',
            'latest_version': '1.0.0'
          },
          'android': <String, dynamic>{
            'minimum_version': '1.0.0',
            'latest_version': '1.2.0'
          },
          'maintenance': <String, dynamic>{'enabled': false},
        },
        'client': <String, dynamic>{
          'platform': 'android',
          'version': '1.0.0',
          'update_required': false
        },
        'languages': <String, dynamic>{
          'default': 'en',
          'supported': <String>['en', 'ar']
        },
        'features': <String, dynamic>{
          'customer': <String, dynamic>{'app': true},
          'driver': <String, dynamic>{'app': true},
        },
      },
    });
    await cache.write(
      cachedConfig,
      platform: 'android',
      version: '1.0.0',
    );

    final apiClient = ApiClient(
      const AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: 'https://offline.example/api',
      ),
      transport: const _OfflineTransport(),
      retryPolicy: const ApiRetryPolicy(maxAttempts: 1),
    );
    final repository = MobileSystemConfigRepository(
      apiClient,
      cache: cache,
    );

    final restored = await repository.fetch(
      platform: 'android',
      version: '1.0.0',
    );

    expect(restored.android.latestVersion, '1.2.0');
  });
}
