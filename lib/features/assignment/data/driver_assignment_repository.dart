import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/driver_api_context.dart';
import '../../../core/network/api_exception.dart';
import '../domain/driver_assignment_models.dart';

abstract interface class DriverAssignmentRepository {
  DriverAssignmentDataSource get source;
  Future<DriverAssignmentLoadResult> loadAssignment();
}

class DriverAssignmentRepositoryFactory {
  DriverAssignmentRepositoryFactory._();

  static DriverAssignmentRepository create(
    AppConfig config, {
    DriverApiContext? context,
  }) {
    if (config.environment == AppEnvironment.development) {
      return const DemoDriverAssignmentRepository();
    }
    return ApiDriverAssignmentRepository(
      context ?? DriverApiContext.create(config),
    );
  }
}

class ApiDriverAssignmentRepository implements DriverAssignmentRepository {
  final DriverApiContext context;

  const ApiDriverAssignmentRepository(this.context);

  @override
  DriverAssignmentDataSource get source => DriverAssignmentDataSource.api;

  @override
  Future<DriverAssignmentLoadResult> loadAssignment() async {
    try {
      final envelope = await context.apiClient.getJson(
        '/v1/driver/assignments',
        authenticated: true,
      );
      final data = DriverApiContext.dataMap(envelope);
      final branches = (data['branches'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);
      final regions = (data['regions'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);

      final primaryRegion = regions.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['is_primary'] == true,
            orElse: () => regions.isEmpty ? null : regions.first,
          );
      final primaryBranch = branches.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['is_primary'] == true,
            orElse: () => branches.isEmpty ? null : branches.first,
          );

      return DriverAssignmentLoadResult.success(
        DriverAssignmentSnapshot(
          assignedCity: primaryRegion?['city']?.toString() ??
              primaryBranch?['city']?.toString() ??
              '',
          regions: regions
              .map((item) => item['name']?.toString() ?? '')
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
          allowedBranches: branches
              .map(
                (item) => DriverAssignedBranch(
                  id: item['id']?.toString() ?? '',
                  name: item['name']?.toString() ?? 'Branch',
                  area: item['city']?.toString(),
                ),
              )
              .toList(growable: false),
          serviceRadiusKm:
              (primaryRegion?['radius_km'] as num?)?.toDouble() ?? 0,
          control: DriverAssignmentControl.managedByGetin,
          policyMessage:
              'Operational assignment is controlled by Getin and loaded from Laravel.',
          updatedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (error) {
      return DriverAssignmentLoadResult.failure(error.message);
    } on FormatException catch (error) {
      return DriverAssignmentLoadResult.failure(error.message);
    }
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
