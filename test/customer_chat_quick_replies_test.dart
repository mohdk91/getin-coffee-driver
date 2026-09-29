import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_chat_repository.dart';
import 'package:getin_driver/features/customer_contact/domain/driver_customer_chat_models.dart';
import 'package:getin_driver/features/customer_contact/driver_customer_chat_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-2481',
    status: 'Out for delivery • Demo',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  test('Task 30 exposes exactly the required customer quick replies', () {
    expect(
      driverCustomerChatQuickReplies,
      const <String>[
        'I’m arriving soon',
        'I’m outside',
        'Please come down',
        'Please check your phone',
        'I’m at the entrance',
        'Where should I meet you?',
      ],
    );
  });

  testWidgets('Task 30 quick reply sends to the current order thread',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const repository = DemoDriverCustomerChatRepository();
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverCustomerChatScreen(
          config: config,
          delivery: delivery,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick replies'), findsOneWidget);
    for (final reply in driverCustomerChatQuickReplies) {
      expect(find.text(reply), findsOneWidget);
    }

    final quickReply = find.byKey(
      const ValueKey<String>('customer-quick-reply:I’m arriving soon'),
    );
    expect(quickReply, findsOneWidget);
    await tester.tap(quickReply);
    await tester.pumpAndSettle();

    final currentOrder = await repository.loadThread(orderNumber: 'GD-2481');
    expect(
      currentOrder.thread!.messages.any(
        (message) =>
            message.author == DriverCustomerChatAuthor.driver &&
            message.text == 'I’m arriving soon',
      ),
      isTrue,
    );

    final otherOrder = await repository.loadThread(orderNumber: 'GD-9999');
    expect(
      otherOrder.thread!.messages.any(
        (message) => message.text == 'I’m arriving soon',
      ),
      isFalse,
    );
  });
}
