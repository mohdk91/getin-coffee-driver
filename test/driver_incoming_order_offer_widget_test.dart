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

  testWidgets('Task 246 incoming offer popup exposes critical order details',
      (tester) async {
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

    expect(find.text('NEW DELIVERY'), findsOneWidget);
    expect(find.text('GD-UAT-9001'), findsOneWidget);
    expect(find.text('Stanley'), findsOneWidget);
    expect(find.text('San Stefano'), findsOneWidget);
    expect(find.text('~19 min'), findsOneWidget);
    expect(find.text('EGP 72.00'), findsOneWidget);
    expect(find.text('Accept Order'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.textContaining('UAT DEMO'), findsOneWidget);
  });
}
