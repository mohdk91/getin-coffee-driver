import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_exceptions/data/driver_delivery_exception_repository.dart';
import 'package:getin_driver/features/delivery_exceptions/driver_delivery_exception_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  setUp(DemoDriverDeliveryExceptionRepository.clearDemoState);

  testWidgets('Task 265 keeps exception recovery driver-facing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: '',
    );
    const delivery = DriverActiveDeliverySummary(
      orderNumber: 'GD-265',
      status: 'Out for delivery',
      pickupBranch: 'Stanley',
      destinationArea: 'San Stefano',
      etaMinutes: 19,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverDeliveryExceptionScreen(
          delivery: delivery,
          config: config,
          repository: DemoDriverDeliveryExceptionRepository(),
        ),
      ),
    );

    expect(find.text('NEXT STEP'), findsOneWidget);
    await tester.tap(find.text('Return to branch'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Report Exception'));
    await tester.pumpAndSettle();

    expect(find.text('Exception Recorded'), findsOneWidget);
    expect(
        find.textContaining('Return to branch is the recommended next action.'),
        findsOneWidget);
    expect(find.textContaining('Task #24'), findsNothing);
  });
}
