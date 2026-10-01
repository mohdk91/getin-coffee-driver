import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/support/data/driver_support_chat_repository.dart';
import 'package:getin_driver/features/support/domain/driver_support_chat_models.dart';

class _Transport implements ApiTransport {
  final List<String> paths = <String>[];
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    paths.add('${method.toUpperCase()} ${uri.path}');
    if (uri.path.endsWith('/support-conversations')) {
      return const ApiRawResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"id":77,"type":"driver_support","messages":[{"id":1,"conversation_id":77,"body":"How can we help?","sent_at":"2026-10-01T01:00:00Z","sender":{"id":2,"name":"Ops","user_type":"admin"}}]}}');
    }
    if (uri.path.endsWith('/conversations/77/messages')) {
      return const ApiRawResponse(
          statusCode: 201, body: '{"success":true,"data":{"id":2}}');
    }
    if (uri.path.endsWith('/conversations/77')) {
      return const ApiRawResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"id":77,"type":"driver_support","messages":[{"id":1,"conversation_id":77,"body":"How can we help?","sent_at":"2026-10-01T01:00:00Z","sender":{"id":2,"name":"Ops","user_type":"admin"}},{"id":2,"conversation_id":77,"body":"Pickup issue","sent_at":"2026-10-01T01:01:00Z","sender":{"id":9,"name":"Driver","user_type":"driver"}}]}}');
    }
    return const ApiRawResponse(statusCode: 404, body: '{}');
  }
}

void main() {
  test('Task 125 support chat opens backend thread and sends messages',
      () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final transport = _Transport();
    final repo = ApiDriverSupportChatRepository(
      DriverApiContext.create(config, secureStore: store, transport: transport),
    );
    final loaded = await repo.loadThread(orderNumber: 'GD-44', apiOrderId: 44);
    expect(loaded.isSuccess, isTrue);
    expect(
        loaded.thread!.messages.single.author, DriverSupportChatAuthor.support);
    final sent = await repo.sendDriverMessage(
        orderNumber: 'GD-44', apiOrderId: 44, text: 'Pickup issue');
    expect(sent.isSuccess, isTrue);
    expect(sent.thread!.messages.last.author, DriverSupportChatAuthor.driver);
    expect(
        transport.paths, contains('POST /api/v1/driver/support-conversations'));
  });
}
