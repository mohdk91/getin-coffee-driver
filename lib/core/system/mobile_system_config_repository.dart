import '../network/api_client.dart';
import 'mobile_system_config.dart';

class MobileSystemConfigRepository {
  final ApiClient apiClient;

  const MobileSystemConfigRepository(this.apiClient);

  Future<MobileSystemConfig> fetch({
    required String platform,
    required String version,
  }) async {
    final payload = await apiClient.getJson(
      '/v1/system/config',
      query: <String, Object?>{
        'platform': platform,
        'version': version,
      },
    );

    return MobileSystemConfig.fromApiEnvelope(payload);
  }
}
