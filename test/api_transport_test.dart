import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/network/api_client.dart';
import 'package:getin_driver/core/network/api_transport.dart';

class _FakeTransport implements ApiTransport {
  Uri? lastUri;

  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    lastUri = uri;
    return const ApiRawResponse(
      statusCode: 200,
      body: '{"success":true,"data":{"ok":true}}',
    );
  }
}

void main() {
  test('driver API transport can perform JSON requests', () async {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'https://example.test/api/',
    );
    final transport = _FakeTransport();
    final client = ApiClient(config, transport: transport);

    final result = await client.getJson('/v1/system/config');

    expect(result['success'], isTrue);
    expect(transport.lastUri.toString(),
        'https://example.test/api/v1/system/config');
  });
}
