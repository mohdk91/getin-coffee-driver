import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/support/data/driver_support_chat_repository.dart';
import 'package:getin_driver/features/support/domain/driver_support_chat_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Task 31 exposes every required support quick topic', () {
    expect(
      driverSupportQuickTopics,
      containsAll(<String>[
        'Pickup issue',
        'Customer unavailable',
        'Address issue',
        'Payment/verification issue',
        'Damaged package',
        'Safety issue',
        'Talk to operations',
      ]),
    );
  });

  test('Task 31 demo support thread persists driver messages', () async {
    const repository = DemoDriverSupportChatRepository();

    final initial = await repository.loadThread(orderNumber: 'GD-3101');
    expect(initial.isSuccess, isTrue);
    expect(initial.thread, isNotNull);
    expect(initial.thread!.isDemo, isTrue);

    final sent = await repository.sendDriverMessage(
      orderNumber: 'GD-3101',
      text: 'Pickup issue',
    );
    expect(sent.isSuccess, isTrue);
    expect(
      sent.thread!.messages.any(
        (message) =>
            message.author == DriverSupportChatAuthor.driver &&
            message.text == 'Pickup issue',
      ),
      isTrue,
    );

    const freshRepository = DemoDriverSupportChatRepository();
    final reloaded = await freshRepository.loadThread(orderNumber: 'GD-3101');

    expect(reloaded.isSuccess, isTrue);
    expect(
      reloaded.thread!.messages.any(
        (message) =>
            message.author == DriverSupportChatAuthor.driver &&
            message.text == 'Pickup issue',
      ),
      isTrue,
    );
  });

  test('Task 125 configured production support repository is API-backed', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );

    final repository = DriverSupportChatRepositoryFactory.create(config);

    expect(repository, isA<ApiDriverSupportChatRepository>());
    expect(repository.source, DriverSupportChatDataSource.api);
  });

  test(
    'Task 31 unconfigured production repository never invents support messages',
    () async {
      const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: '',
      );

      final repository = DriverSupportChatRepositoryFactory.create(config);
      expect(repository, isA<UnavailableDriverSupportChatRepository>());

      final result = await repository.loadThread(orderNumber: 'GD-3101');

      expect(result.isSuccess, isFalse);
      expect(result.thread, isNull);
      expect(result.errorMessage, contains('not connected'));
    },
  );
}
