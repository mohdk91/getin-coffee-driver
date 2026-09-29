import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../offline/mobile_system_config_cache.dart';
import 'mobile_system_config.dart';

abstract class MobileSystemConfigLoader {
  Future<MobileSystemConfig> fetch({
    required String platform,
    required String version,
  });
}

class MobileSystemConfigRepository implements MobileSystemConfigLoader {
  final ApiClient apiClient;
  final MobileSystemConfigCache cache;

  const MobileSystemConfigRepository(
    this.apiClient, {
    this.cache = const MobileSystemConfigCache(),
  });

  Future<MobileSystemConfig> fetch({
    required String platform,
    required String version,
  }) async {
    try {
      final payload = await apiClient.getJson(
        '/v1/system/config',
        query: <String, Object?>{
          'platform': platform,
          'version': version,
        },
      );

      final config = MobileSystemConfig.fromApiEnvelope(payload);
      await cache.write(
        config,
        platform: platform,
        version: version,
      );
      return config;
    } on ApiException {
      final cached = await cache.readFresh(
        platform: platform,
        version: version,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }
}
