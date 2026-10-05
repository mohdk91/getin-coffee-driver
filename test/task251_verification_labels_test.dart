import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_pin_repository.dart';
import 'package:getin_driver/features/delivery_verification/driver_delivery_pin_screen.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: '',
  );
  const delivery = DriverActiveDeliverySummary(
    orderNumber: 'GD-UAT-9001',
    status: 'Verification pending',
    pickupBranch: 'Stanley',
    destinationArea: 'San Stefano',
    etaMinutes: 19,
  );

  testWidgets('Task 251 PIN badge changes to verified after success',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DriverDeliveryPinScreen(
          config: config,
          delivery: delivery,
          repository: DemoDriverDeliveryPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PIN REQUIRED'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4821');
    final verify = find.widgetWithText(FilledButton, 'Verify Delivery');
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(find.text('PIN VERIFIED'), findsOneWidget);
    expect(find.text('PIN REQUIRED'), findsNothing);
    expect(find.text('Delivery Verified'), findsOneWidget);
    expect(find.textContaining('Driver Task #22'), findsNothing);
  });

  test('Task 251 QR success label follows the same verified contract', () {
    final qrSource = File(
      'lib/features/delivery_verification/driver_delivery_qr_screen.dart',
    ).readAsStringSync();

    expect(qrSource, contains("verified ? 'QR VERIFIED' : 'QR VERIFICATION'"));
    expect(qrSource, isNot(contains('Driver Task #22')));
  });
}
