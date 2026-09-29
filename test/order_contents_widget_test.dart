import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/order_contents/data/driver_order_contents_repository.dart';
import 'package:getin_driver/features/order_contents/driver_order_contents_screen.dart';

void main() {
  testWidgets('Task 14 shows read-only delivery-safe order contents',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverOrderContentsScreen(
          config: config,
          orderNumber: 'GD-3101',
          repository: DemoDriverOrderContentsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order Contents'), findsOneWidget);
    expect(find.text('GD-3101'), findsOneWidget);
    expect(find.text('Read-only transport summary'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Bags'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Handling instructions'), findsOneWidget);
    expect(find.text('Customer delivery notes'), findsOneWidget);

    expect(find.textContaining('Customer profile'), findsOneWidget);
    expect(find.textContaining('payment'), findsOneWidget);
    expect(find.text('Customer phone'), findsNothing);
    expect(find.text('Payment method'), findsNothing);
  });
}
