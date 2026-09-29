import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_exceptions/data/driver_delivery_exception_repository.dart';
import 'package:getin_driver/features/delivery_exceptions/driver_delivery_exception_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

const delivery = DriverActiveDeliverySummary(
  orderNumber: 'GD-2481',
  status: 'Out for delivery • Demo',
  pickupBranch: 'Stanley',
  destinationArea: 'San Stefano',
  etaMinutes: 19,
);

const config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  setUp(DemoDriverDeliveryExceptionRepository.clearDemoState);

  testWidgets('Task 23 shows every required delivery exception reason',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryExceptionScreen(
          delivery: delivery,
          config: config,
          repository: DemoDriverDeliveryExceptionRepository(),
        ),
      ),
    );

    expect(find.text('Customer unavailable'), findsOneWidget);
    expect(find.text('Wrong address'), findsOneWidget);
    expect(find.text('Customer refused'), findsOneWidget);
    expect(find.text('Cannot access building'), findsOneWidget);
    expect(find.text('Damaged order'), findsOneWidget);
    expect(find.text('Safety issue'), findsOneWidget);
    expect(find.text('Support required'), findsOneWidget);

    expect(find.text('Return to branch'), findsOneWidget);
  });

  testWidgets('Task 23 local report never presents Delivered', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryExceptionScreen(
          delivery: delivery,
          config: config,
          repository: DemoDriverDeliveryExceptionRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Customer unavailable'));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Report Exception'));
    await tester.pumpAndSettle();

    expect(find.text('Exception Recorded'), findsOneWidget);
    expect(find.text('ISSUE • DEMO'), findsOneWidget);
    expect(find.text('DELIVERED'), findsNothing);
    expect(find.textContaining('order is not Delivered'), findsOneWidget);
  });
}
