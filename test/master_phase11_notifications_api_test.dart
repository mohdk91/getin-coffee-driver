import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/notifications/data/driver_notifications_repository.dart';
import 'package:getin_driver/features/notifications/domain/driver_notification_models.dart';

class _Transport implements ApiTransport {
  final List<String> paths = <String>[];
  @override
  Future<ApiRawResponse> send(Uri uri,
      {required String method,
      required Map<String, String> headers,
      Object? body,
      required Duration timeout}) async {
    paths.add('${method.toUpperCase()} ${uri.path}');
    if (uri.path.endsWith('/notifications')) {
      return const ApiRawResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"items":[{"id":7,"type":"customer_message","title":"Customer sent a message","body":"Please call me when you arrive.","data":{"order_number":"GD-3107"},"is_read":false,"created_at":"2026-10-01T01:00:00Z"}]}}');
    }
    if (uri.path.endsWith('/notifications/7/read') ||
        uri.path.endsWith('/notifications/read-all')) {
      return const ApiRawResponse(
          statusCode: 200, body: '{"success":true,"data":{"updated":1}}');
    }
    return const ApiRawResponse(statusCode: 404, body: '{}');
  }
}

void main() {
  test('Task 123 loads and mutates real driver notifications', () async {
    const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test/api');
    final transport = _Transport();
    final store = MemorySecureStore();
    await store.write(SecureStoreKeys.accessToken, 'driver-token');
    final context = DriverApiContext.create(config,
        secureStore: store, transport: transport);
    final repository = ApiDriverNotificationsRepository(context);
    final loaded = await repository.loadNotifications();
    expect(loaded.isSuccess, isTrue);
    expect(loaded.snapshot!.items.single.id, '7');
    expect(loaded.snapshot!.items.single.category,
        DriverNotificationCategory.customerMessage);
    expect(loaded.snapshot!.items.single.orderNumber, 'GD-3107');
    expect((await repository.markRead('7')).isSuccess, isTrue);
    expect((await repository.markAllRead()).isSuccess, isTrue);
    expect(
        transport.paths, contains('POST /api/v1/driver/notifications/7/read'));
    expect(transport.paths,
        contains('POST /api/v1/driver/notifications/read-all'));
  });
}
