import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_chat_repository.dart';
import 'package:getin_driver/features/customer_contact/domain/driver_customer_chat_models.dart';

class _Transport implements ApiTransport {
  final List<String> requests = <String>[];
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    requests.add('${method.toUpperCase()} ${uri.path}');
    if (uri.path.endsWith('/orders/44/customer-chat')) {
      return const ApiRawResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"id":91,"type":"driver_customer","messages":[{"id":1,"conversation_id":91,"body":"Meet me outside","sent_at":"2026-10-01T01:00:00Z","sender":{"id":8,"name":"Customer","user_type":"customer"}}]}}');
    }
    if (uri.path.endsWith('/conversations/91/messages')) {
      return const ApiRawResponse(
          statusCode: 201,
          body:
              '{"success":true,"data":{"id":2,"conversation_id":91,"body":"I am outside","sent_at":"2026-10-01T01:01:00Z","sender":{"id":9,"name":"Driver","user_type":"driver"}}}');
    }
    if (uri.path.endsWith('/conversations/91')) {
      return const ApiRawResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"id":91,"type":"driver_customer","messages":[{"id":1,"conversation_id":91,"body":"Meet me outside","sent_at":"2026-10-01T01:00:00Z","sender":{"id":8,"name":"Customer","user_type":"customer"}},{"id":2,"conversation_id":91,"body":"I am outside","sent_at":"2026-10-01T01:01:00Z","sender":{"id":9,"name":"Driver","user_type":"driver"}}]}}');
    }
    return const ApiRawResponse(statusCode: 404, body: '{}');
  }
}

void main() {
  test('Task 124 customer chat is bound to Laravel order and conversation ids',
      () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'token');
    final transport = _Transport();
    final repository = ApiDriverCustomerChatRepository(
      DriverApiContext.create(config, secureStore: store, transport: transport),
    );
    final loaded =
        await repository.loadThread(orderNumber: 'GD-44', apiOrderId: 44);
    expect(loaded.isSuccess, isTrue);
    expect(loaded.thread!.threadId, '91');
    expect(loaded.thread!.messages.single.author,
        DriverCustomerChatAuthor.customer);
    final sent = await repository.sendDriverMessage(
        orderNumber: 'GD-44', apiOrderId: 44, text: 'I am outside');
    expect(sent.isSuccess, isTrue);
    expect(sent.thread!.messages.last.author, DriverCustomerChatAuthor.driver);
    expect(transport.requests,
        contains('POST /api/v1/driver/orders/44/customer-chat'));
    expect(transport.requests,
        contains('POST /api/v1/driver/conversations/91/messages'));
  });
}
