import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/eligibility/data/driver_order_eligibility_repository.dart';
import 'package:getin_driver/features/home/domain/driver_home_models.dart';
import 'package:getin_driver/features/order_history/driver_order_history_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

void main() {
  testWidgets(
    'Task 249 compact Orders keeps all tabs visible and search unfocused',
    (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DriverOrderHistoryScreen(
              config: _config,
              eligibilityRepository: DemoDriverOrderEligibilityRepository(),
              availability: DriverAvailabilityState.online,
              activeDelivery: null,
              driverApproved: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Delivered'), findsWidgets);
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.text('New / Available'), findsNothing);
      expect(find.text('Active / On Delivery'), findsNothing);

      final search = tester.widget<TextField>(find.byType(TextField));
      expect(search.autofocus, isFalse);
      expect(search.focusNode, isNotNull);
      expect(search.focusNode!.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
