import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/support/data/driver_support_chat_repository.dart';
import 'package:getin_driver/features/support/driver_support_chat_screen.dart';

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

  testWidgets('Task 31 support chat is order-aware for an active delivery',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverSupportChatScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverSupportChatRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Getin Support'), findsWidgets);
    expect(find.text('Order GD-2481'), findsWidgets);
    expect(find.textContaining('Stanley → San Stefano'), findsOneWidget);
    expect(find.textContaining('DEMO SUPPORT CHAT'), findsOneWidget);
    expect(find.text('Quick topics'), findsOneWidget);
  });

  testWidgets('Task 31 quick topic sends inside the active order thread',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const repository = DemoDriverSupportChatRepository();
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverSupportChatScreen(
          config: config,
          delivery: delivery,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final topic = find.byKey(
      const ValueKey<String>('support-quick-topic:Pickup issue'),
    );
    expect(topic, findsOneWidget);
    await tester.tap(topic);
    await tester.pumpAndSettle();

    final thread = await repository.loadThread(orderNumber: 'GD-2481');
    expect(
      thread.thread!.messages.any((message) => message.text == 'Pickup issue'),
      isTrue,
    );
    expect(find.text('Pickup issue'), findsWidgets);
    expect(find.textContaining('Demo acknowledgement for GD-2481'),
        findsOneWidget);
  });

  testWidgets('Task 31 review dispute can open as an order-linked draft',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverSupportChatScreen(
          config: config,
          contextOrderNumber: 'GD-2468',
          initialDraft:
              'I want to report/dispute the customer review for order GD-2468.',
          repository: DemoDriverSupportChatRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order GD-2468'), findsWidgets);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller!.text,
      'I want to report/dispute the customer review for order GD-2468.',
    );
  });
}
