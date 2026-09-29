import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/vehicle/data/driver_vehicle_repository.dart';
import 'package:getin_driver/features/vehicle/domain/driver_vehicle_models.dart';
import 'package:getin_driver/features/vehicle/driver_vehicle_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

class _FixedVehicleRepository implements DriverVehicleRepository {
  DriverVehicleSnapshot vehicle = DriverVehicleSnapshot(
    vehicleType: 'Motorcycle',
    plate: 'TEST-033',
    makeModel: 'Test Scooter 125',
    color: 'Green',
    status: DriverVehicleStatus.active,
    documentStatus: DriverVehicleDocumentStatus.valid,
    editableFields: const {
      DriverVehicleField.makeModel,
      DriverVehicleField.color,
    },
    updatedAt: DateTime(2026, 9, 26),
  );

  @override
  DriverVehicleDataSource get source => DriverVehicleDataSource.demo;

  @override
  Future<DriverVehicleLoadResult> loadVehicle() async {
    return DriverVehicleLoadResult.success(vehicle);
  }

  @override
  Future<DriverVehicleUpdateResult> updateVehicle(
    DriverVehicleUpdateRequest request,
  ) async {
    vehicle = vehicle.copyWith(
      makeModel: request.makeModel,
      color: request.color,
      updatedAt: DateTime(2026, 9, 26, 20),
    );
    return DriverVehicleUpdateResult.success(vehicle);
  }
}

class _FailedVehicleRepository implements DriverVehicleRepository {
  @override
  DriverVehicleDataSource get source => DriverVehicleDataSource.api;

  @override
  Future<DriverVehicleLoadResult> loadVehicle() async {
    return const DriverVehicleLoadResult.failure('Vehicle API unavailable.');
  }

  @override
  Future<DriverVehicleUpdateResult> updateVehicle(
    DriverVehicleUpdateRequest request,
  ) async {
    return const DriverVehicleUpdateResult.failure('Vehicle API unavailable.');
  }
}

void main() {
  testWidgets('Task 33 renders every required vehicle field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverVehicleScreen(
          config: _config,
          repository: _FixedVehicleRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assigned vehicle'), findsOneWidget);
    expect(find.text('Motorcycle'), findsWidgets);
    expect(find.text('TEST-033'), findsWidgets);
    expect(find.text('Test Scooter 125'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('vehicle-color-value')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Green'), findsOneWidget);
    expect(find.byKey(const Key('vehicle-status-value')), findsOneWidget);
    expect(
      find.byKey(const Key('vehicle-document-status-value')),
      findsOneWidget,
    );
  });

  testWidgets('Task 33 edit sheet keeps managed fields locked', (tester) async {
    final repository = _FixedVehicleRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DriverVehicleScreen(config: _config, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Edit allowed fields'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Edit allowed fields'));
    await tester.pumpAndSettle();

    final typeField = tester.widget<TextFormField>(
      find.descendant(
        of: find.byKey(const Key('vehicle-edit-type')),
        matching: find.byType(TextFormField),
      ),
    );
    final plateField = tester.widget<TextFormField>(
      find.descendant(
        of: find.byKey(const Key('vehicle-edit-plate')),
        matching: find.byType(TextFormField),
      ),
    );
    final makeModelField = tester.widget<TextFormField>(
      find.descendant(
        of: find.byKey(const Key('vehicle-edit-make-model')),
        matching: find.byType(TextFormField),
      ),
    );

    expect(typeField.enabled, isFalse);
    expect(plateField.enabled, isFalse);
    expect(makeModelField.enabled, isTrue);
  });

  testWidgets('Task 33 exposes unavailable API state without fake data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverVehicleScreen(
          config: _config,
          repository: _FailedVehicleRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vehicle unavailable'), findsOneWidget);
    expect(find.text('Vehicle API unavailable.'), findsOneWidget);
    expect(find.text('ALEX-2417'), findsNothing);
  });
}
