import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_chat_repository.dart';
import 'package:getin_driver/features/customer_contact/data/driver_customer_contact_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/navigation/driver_delivery_navigation_screen.dart';

Future<void> _dragUntilBuilt(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 10 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

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

  testWidgets('Task 17 delivery navigation shows CALL and CHAT',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryNavigationScreen(
          config: config,
          delivery: delivery,
          contactRepository: DemoDriverCustomerContactRepository(),
          chatRepository: DemoDriverCustomerChatRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final call = find.text('CALL');
    await _dragUntilBuilt(tester, call);
    expect(find.text('CHAT'), findsOneWidget);
  });

  testWidgets('Task 17 demo CALL protects the customer phone number',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryNavigationScreen(
          config: config,
          delivery: delivery,
          contactRepository: DemoDriverCustomerContactRepository(),
          chatRepository: DemoDriverCustomerChatRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final call = find.text('CALL');
    await _dragUntilBuilt(tester, call);
    await tester.tap(call);
    await tester.pumpAndSettle();

    expect(find.textContaining('No call was placed'), findsOneWidget);
  });

  testWidgets('Task 17 CHAT opens an order-specific conversation and sends',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryNavigationScreen(
          config: config,
          delivery: delivery,
          contactRepository: DemoDriverCustomerContactRepository(),
          chatRepository: DemoDriverCustomerChatRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chat = find.text('CHAT');
    await _dragUntilBuilt(tester, chat);
    await tester.tap(chat);
    await tester.pumpAndSettle();

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Order GD-2481'), findsOneWidget);
    expect(find.textContaining('Local demo order chat'), findsOneWidget);
    expect(find.text('Please message me when you arrive.'), findsOneWidget);

    final composer = find.byType(TextField);
    await tester.enterText(composer, 'I am outside now.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('I am outside now.'), findsOneWidget);
  });
}
