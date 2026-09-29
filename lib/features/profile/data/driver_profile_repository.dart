import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../domain/driver_profile_models.dart';

abstract interface class DriverProfileRepository {
  DriverProfileDataSource get source;
  Future<DriverProfileLoadResult> loadProfile();
}

class DriverProfileRepositoryFactory {
  DriverProfileRepositoryFactory._();

  static DriverProfileRepository create(AppConfig config) {
    return config.environment == AppEnvironment.development
        ? const DemoDriverProfileRepository()
        : const UnavailableDriverProfileRepository();
  }
}

class DemoDriverProfileRepository implements DriverProfileRepository {
  const DemoDriverProfileRepository();

  @override
  DriverProfileDataSource get source => DriverProfileDataSource.demo;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    return DriverProfileLoadResult.success(
      DriverProfileSnapshot(
        fullName: 'Demo Driver',
        phone: '+20 100 000 0000',
        email: 'driver@getin.local',
        driverId: 'DRV-DEMO-001',
        verificationStatus: DriverProfileVerificationStatus.approved,
        assignedRegion: 'East Alexandria',
        assignedBranches: const ['Stanley', 'San Stefano'],
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class UnavailableDriverProfileRepository implements DriverProfileRepository {
  const UnavailableDriverProfileRepository();

  @override
  DriverProfileDataSource get source => DriverProfileDataSource.api;

  @override
  Future<DriverProfileLoadResult> loadProfile() async {
    return const DriverProfileLoadResult.failure(
      'Driver profile data is not connected to the Laravel API yet. Getin will not invent production identity, contact or assignment details.',
    );
  }
}
