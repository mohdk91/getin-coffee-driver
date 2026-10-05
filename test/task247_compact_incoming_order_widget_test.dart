import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/eligibility/domain/driver_order_eligibility_models.dart';
import 'package:getin_driver/features/incoming_orders/driver_incoming_order_offer_dialog.dart';

void main() {
  const order = DriverOrderCandidate(
    orderNumber: 'GD-UAT-9001',
    pickupBranch: 'Stanley',
    region: 'East Alexandria',
    zone: 'San Stefano',
    destinationArea: 'San Stefano',
    distanceToBranchKm: 1.8,
    deliveryDistanceKm: 4.6,
    estimatedDurationMinutes: 19,
    bagCount: 2,
    estimatedDriverEarning: 72,
    currencyCode: 'EGP',
    allowedVehicleTypes: <String>['motorcycle'],
    isAvailable: true,
  );

  testWidgets('Task 247 keeps ETA bags and earning in one compact row',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverIncomingOrderOfferDialog(
            order: order,
            offerDuration: Duration(seconds: 25),
            uatDemo: true,
          ),
        ),
      ),
    );

    final etaY = tester.getTopLeft(find.text('ETA')).dy;
    final bagsY = tester.getTopLeft(find.text('Bags')).dy;
    final earningY = tester.getTopLeft(find.text('Earning')).dy;

    expect((etaY - bagsY).abs(), lessThan(2));
    expect((etaY - earningY).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
  });
}
