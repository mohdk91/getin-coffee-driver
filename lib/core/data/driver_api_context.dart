import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/api_retry_policy.dart';
import '../network/api_transport.dart';
import '../storage/secure_store.dart';

class DriverApiContext {
  final AppConfig config;
  final SecureStore secureStore;
  final ApiClient apiClient;

  const DriverApiContext._({
    required this.config,
    required this.secureStore,
    required this.apiClient,
  });

  factory DriverApiContext.create(
    AppConfig config, {
    SecureStore? secureStore,
    ApiTransport? transport,
    ApiRetryPolicy retryPolicy = const ApiRetryPolicy(),
  }) {
    final store = secureStore ?? const FlutterSecureStoreAdapter();
    return DriverApiContext._(
      config: config,
      secureStore: store,
      apiClient: ApiClient(
        config,
        transport: transport,
        tokenProvider: () => store.read(SecureStoreKeys.accessToken),
        retryPolicy: retryPolicy,
      ),
    );
  }

  bool get usesApi => config.isApiConfigured;

  static Map<String, dynamic> dataMap(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('GETIN API response data is not an object.');
  }

  static List<dynamic> dataList(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is List) return data;
    throw const FormatException('GETIN API response data is not a list.');
  }

  static List<dynamic> nestedItems(Map<String, dynamic> envelope) {
    final data = dataMap(envelope);
    final items = data['items'];
    if (items is List) return items;
    throw const FormatException('GETIN API response items are not a list.');
  }
}
