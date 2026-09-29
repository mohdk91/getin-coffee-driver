import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/assignment/data/driver_assignment_repository.dart';
import 'package:getin_driver/features/assignment/domain/driver_assignment_models.dart';

void main() {
  test('Task 35 demo repository exposes complete operational assignment',
      () async {
    const repository = DemoDriverAssignmentRepository();

    final result = await repository.loadAssignment();

    expect(result.isSuccess, isTrue);
    expect(repository.source, DriverAssignmentDataSource.demo);
    expect(result.assignment!.assignedCity, 'Alexandria');
    expect(result.assignment!.regions, isNotEmpty);
    expect(result.assignment!.allowedBranches, hasLength(2));
    expect(result.assignment!.serviceRadiusKm, 7.5);
    expect(
      result.assignment!.control,
      DriverAssignmentControl.managedByGetin,
    );
    expect(result.assignment!.driverCanChangeAssignment, isFalse);
  });

  test('Task 35 unavailable repository never invents production assignment',
      () async {
    const repository = UnavailableDriverAssignmentRepository();

    final result = await repository.loadAssignment();

    expect(repository.source, DriverAssignmentDataSource.api);
    expect(result.isSuccess, isFalse);
    expect(result.assignment, isNull);
    expect(result.errorMessage, contains('Laravel API'));
  });
}
