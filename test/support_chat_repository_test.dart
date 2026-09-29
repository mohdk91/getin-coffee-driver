import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/support/data/driver_support_chat_repository.dart';
import 'package:getin_driver/features/support/domain/driver_support_chat_models.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Task 31 exposes exactly the required Getin Support quick topics', () {
    expect(
      driverSupportQuickTopics,
      const <String>[
        'Pickup issue',
        'Customer unavailable',
        'Address issue',
        'Payment/verification issue',
        'Damaged package',
        'Safety issue',
        'Talk to operations',
      ],
    );
  });

  test('Task 31 demo support threads are isolated by order', () async {
    const repository = DemoDriverSupportChatRepository();

    final sent = await repository.sendDriverMessage(
      orderNumber: 'GD-2481',
      text: 'Pickup issue',
    );
    expect(sent.isSuccess, isTrue);
    expect(sent.thread!.threadId, 'support:order:GD-2481');
    expect(
      sent.thread!.messages.any(
        (message) =>
            message.author == DriverSupportChatAuthor.driver &&
            message.text == 'Pickup issue',
      ),
      isTrue,
    );

    final other = await repository.loadThread(orderNumber: 'GD-9999');
    expect(other.thread!.threadId, 'support:order:GD-9999');
    expect(
      other.thread!.messages.any((message) => message.text == 'Pickup issue'),
      isFalse,
    );
  });

  test('Task 31 production repository never invents support messages',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final repository = DriverSupportChatRepositoryFactory.create(config);

    expect(repository.source, DriverSupportChatDataSource.api);
    final load = await repository.loadThread(orderNumber: 'GD-2481');
    expect(load.isSuccess, isFalse);
    expect(load.errorMessage, contains('not connected to Laravel'));
  });
}
