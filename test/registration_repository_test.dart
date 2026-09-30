import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/features/registration/data/driver_registration_repository.dart';
import 'package:getin_driver/features/registration/domain/driver_registration_models.dart';

DriverRegistrationDraft validDraft({String email = 'driver@example.com'}) {
  return DriverRegistrationDraft(
    fullName: 'Demo Driver',
    dateOfBirth: '1990-01-01',
    dialCode: '+20',
    phoneNumber: '1000000000',
    email: email,
    nationalId: '29801010000000',
    drivingLicenseNumber: 'LIC-1001',
    drivingLicenseExpiry: '2028-01-01',
    vehicleType: DriverVehicleType.motorbike,
    vehicleMakeModel: 'Demo 125',
    plateNumber: 'ABC 123',
    vehicleColor: 'Black',
    documents: DriverRegistrationDocumentType.values.toSet(),
    country: 'Egypt',
    city: 'Alexandria',
    region: 'Stanley / San Stefano',
    preferredBranch: 'Stanley Branch',
    acceptedDeclaration: true,
  );
}

void main() {
  test('development registration repository uses explicit demo source', () {
    final repository = DriverRegistrationRepositoryFactory.create(
      const AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: '',
      ),
    );

    expect(repository.source, DriverRegistrationSource.demo);
  });

  test('demo registration returns a pending local receipt', () async {
    const repository = DemoDriverRegistrationRepository();
    final result = await repository.submit(validDraft());

    expect(result.isSuccess, isTrue);
    expect(result.data?.applicationId, startsWith('DRV-DEMO-'));
    expect(result.data?.statusLabel, 'Pending review');
  });

  test('demo registration refuses incomplete required documents', () async {
    const repository = DemoDriverRegistrationRepository();
    final draft = validDraft();
    final incomplete = DriverRegistrationDraft(
      fullName: draft.fullName,
      dateOfBirth: draft.dateOfBirth,
      dialCode: draft.dialCode,
      phoneNumber: draft.phoneNumber,
      email: draft.email,
      nationalId: draft.nationalId,
      drivingLicenseNumber: draft.drivingLicenseNumber,
      drivingLicenseExpiry: draft.drivingLicenseExpiry,
      vehicleType: draft.vehicleType,
      vehicleMakeModel: draft.vehicleMakeModel,
      plateNumber: draft.plateNumber,
      vehicleColor: draft.vehicleColor,
      documents: const {},
      country: draft.country,
      city: draft.city,
      region: draft.region,
      preferredBranch: draft.preferredBranch,
      acceptedDeclaration: true,
    );

    final result = await repository.submit(incomplete);
    expect(result.isSuccess, isFalse);
    expect(result.failure?.type, DriverRegistrationFailureType.invalidInput);
  });

  test(
    'configured production repository uses API and never fakes registration success',
    () async {
      final repository = DriverRegistrationRepositoryFactory.create(
        const AppConfig(
          environment: AppEnvironment.production,
          apiBaseUrl: 'https://api.example.com',
        ),
      );

      // The legacy fixture intentionally has no password. Phase 9 production
      // registration must select the real API repository, but invalid input must
      // still fail locally instead of inventing a successful application.
      final result = await repository.submit(validDraft());

      expect(repository.source, DriverRegistrationSource.api);
      expect(result.isSuccess, isFalse);
      expect(result.failure?.type, DriverRegistrationFailureType.invalidInput);
    },
  );
}
