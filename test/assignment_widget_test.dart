import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/assignment/data/driver_assignment_repository.dart';
import 'package:getin_driver/features/assignment/domain/driver_assignment_models.dart';
import 'package:getin_driver/features/assignment/driver_assignment_screen.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
);

class _FixedAssignmentRepository implements DriverAssignmentRepository {
  @override
  DriverAssignmentDataSource get source => DriverAssignmentDataSource.demo;

  @override
  Future<DriverAssignmentLoadResult> loadAssignment() async {
    return DriverAssignmentLoadResult.success(
      DriverAssignmentSnapshot(
        assignedCity: 'Alexandria',
        regions: const ['East Alexandria', 'Coastal corridor'],
        allowedBranches: const [
          DriverAssignedBranch(
            id: 'BR-001',
            name: 'Stanley',
            area: 'Stanley Corniche',
          ),
          DriverAssignedBranch(
            id: 'BR-002',
            name: 'San Stefano',
            area: 'San Stefano Corniche',
          ),
        ],
        serviceRadiusKm: 8,
        control: DriverAssignmentControl.managedByGetin,
        policyMessage:
            'Operational assignment is controlled by Getin and cannot be changed by the driver.',
        updatedAt: DateTime(2026, 9, 26),
      ),
    );
  }
}

class _FailedAssignmentRepository implements DriverAssignmentRepository {
  @override
  DriverAssignmentDataSource get source => DriverAssignmentDataSource.api;

  @override
  Future<DriverAssignmentLoadResult> loadAssignment() async {
    return const DriverAssignmentLoadResult.failure(
      'Assignment API unavailable.',
    );
  }
}

void main() {
  testWidgets('Task 35 renders city regions branches and service radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverAssignmentScreen(
          config: _config,
          repository: _FixedAssignmentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operational assignment'), findsOneWidget);
    expect(find.byKey(const Key('assignment-city')), findsOneWidget);
    expect(find.text('Alexandria'), findsOneWidget);
    expect(find.text('East Alexandria'), findsOneWidget);
    expect(find.text('Coastal corridor'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('assignment-branch-BR-002')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Stanley'), findsOneWidget);
    expect(find.text('San Stefano'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('assignment-service-radius')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('8 km'), findsWidgets);
  });

  testWidgets('Task 35 makes operational assignment backend-policy controlled',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverAssignmentScreen(
          config: _config,
          repository: _FixedAssignmentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('assignment-governance-card')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Managed by Getin'), findsOneWidget);
    expect(
        find.textContaining('cannot be changed by the driver'), findsOneWidget);
    expect(find.text('Edit assignment'), findsNothing);
  });

  testWidgets('Task 35 unavailable API state contains no demo coverage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverAssignmentScreen(
          config: _config,
          repository: _FailedAssignmentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assignment unavailable'), findsOneWidget);
    expect(find.text('Assignment API unavailable.'), findsOneWidget);
    expect(find.text('Alexandria'), findsNothing);
  });
}
