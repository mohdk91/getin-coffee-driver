import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_assignment_models.dart';

abstract interface class DriverAssignmentRepository {
  DriverAssignmentDataSource get source;
  Future<DriverAssignmentLoadResult> loadAssignment();
}

class DriverAssignmentRepositoryFactory {
  DriverAssignmentRepositoryFactory._();

  static DriverAssignmentRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverAssignmentRepository()
        : const UnavailableDriverAssignmentRepository();
  }
}

class DemoDriverAssignmentRepository implements DriverAssignmentRepository {
  const DemoDriverAssignmentRepository();

  @override
  DriverAssignmentDataSource get source => DriverAssignmentDataSource.demo;

  @override
  Future<DriverAssignmentLoadResult> loadAssignment() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    return DriverAssignmentLoadResult.success(
      DriverAssignmentSnapshot(
        assignedCity: 'Alexandria',
        regions: const [
          'East Alexandria',
          'Stanley & Roushdy',
          'San Stefano & Gleem',
        ],
        allowedBranches: const [
          DriverAssignedBranch(
            id: 'BR-STANLEY',
            name: 'Stanley',
            area: 'Stanley Corniche',
          ),
          DriverAssignedBranch(
            id: 'BR-SAN-STEFANO',
            name: 'San Stefano',
            area: 'San Stefano Corniche',
          ),
        ],
        serviceRadiusKm: 7.5,
        control: DriverAssignmentControl.managedByGetin,
        policyMessage:
            'Operational assignment is controlled by Getin. The driver cannot change city, regions, branches or service radius in the app unless backend policy explicitly allows it.',
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class UnavailableDriverAssignmentRepository
    implements DriverAssignmentRepository {
  const UnavailableDriverAssignmentRepository();

  @override
  DriverAssignmentDataSource get source => DriverAssignmentDataSource.api;

  @override
  Future<DriverAssignmentLoadResult> loadAssignment() async {
    return const DriverAssignmentLoadResult.failure(
      'Branch and region assignment is not connected to the Laravel API yet. Getin will not invent production operational coverage.',
    );
  }
}
