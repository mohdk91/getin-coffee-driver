import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/profile/data/driver_profile_repository.dart';
import 'package:getin_driver/features/profile/domain/driver_profile_models.dart';

void main() {
  test('Task 32 demo repository exposes complete driver profile', () async {
    const repository = DemoDriverProfileRepository();

    final result = await repository.loadProfile();

    expect(result.isSuccess, isTrue);
    expect(repository.source, DriverProfileDataSource.demo);
    expect(result.profile!.fullName, 'Test Driver');
    expect(result.profile!.phone, isNotEmpty);
    expect(result.profile!.email, 'driver@getin.local');
    expect(result.profile!.driverId, 'DRV-0001');
    expect(
      result.profile!.verificationStatus,
      DriverProfileVerificationStatus.approved,
    );
    expect(result.profile!.assignedRegion, 'East Alexandria');
    expect(result.profile!.assignedBranches, contains('Stanley'));
    expect(result.profile!.assignedBranches, contains('San Stefano'));
  });

  test('Task 32 unavailable repository never invents production profile',
      () async {
    const repository = UnavailableDriverProfileRepository();

    final result = await repository.loadProfile();

    expect(repository.source, DriverProfileDataSource.api);
    expect(result.isSuccess, isFalse);
    expect(result.profile, isNull);
    expect(result.errorMessage, contains('unavailable right now'));
    expect(result.errorMessage, isNot(contains('Laravel')));
    expect(result.errorMessage, isNot(contains('API')));
  });
}
