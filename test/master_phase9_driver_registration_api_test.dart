import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/config/app_config.dart';
import 'package:getin_driver/core/config/app_environment.dart';
import 'package:getin_driver/core/data/driver_api_context.dart';
import 'package:getin_driver/core/network/api_transport.dart';
import 'package:getin_driver/core/storage/driver_token_store.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/registration/data/driver_registration_repository.dart';
import 'package:getin_driver/features/registration/domain/driver_registration_models.dart';

class _RegistrationTransport implements ApiTransport {
  @override
  Future<ApiRawResponse> send(
    Uri uri, {
    required String method,
    required Map<String, String> headers,
    Object? body,
    required Duration timeout,
  }) async {
    return const ApiRawResponse(
      statusCode: 201,
      body:
          '{"success":true,"data":{"driver":{"id":91,"approval_status":"pending","application_submitted_at":"2026-10-01T00:00:00Z"},"token":"registration-token"}}',
    );
  }
}

void main() {
  test('Phase 9 registration creates Laravel driver account and stores token',
      () async {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://example.test/api',
    );
    final secure = MemorySecureStore();
    final repository = ApiDriverRegistrationRepository(
      DriverApiContext.create(
        config,
        secureStore: secure,
        transport: _RegistrationTransport(),
      ),
    );
    const draft = DriverRegistrationDraft(
      fullName: 'Live Driver',
      dateOfBirth: '1990-01-01',
      dialCode: '+20',
      phoneNumber: '1000000000',
      email: 'driver@example.com',
      password: 'Driver1234',
      passwordConfirmation: 'Driver1234',
      nationalId: '123',
      drivingLicenseNumber: 'LIC-1',
      drivingLicenseExpiry: '2028-01-01',
      vehicleType: DriverVehicleType.motorbike,
      vehicleMakeModel: 'Honda PCX',
      plateNumber: 'ABC 1',
      vehicleColor: 'Black',
      documents: {
        DriverRegistrationDocumentType.nationalId,
        DriverRegistrationDocumentType.drivingLicense,
        DriverRegistrationDocumentType.vehicleDocument,
      },
      country: 'Egypt',
      city: 'Alexandria',
      region: 'East',
      preferredBranch: 'Stanley',
      acceptedDeclaration: true,
    );

    final result = await repository.submit(draft);
    expect(result.isSuccess, isTrue);
    expect(result.data?.applicationId, '91');
    expect(result.data?.statusLabel, 'Pending review');
    expect(
        await DriverTokenStore(secure).readAccessToken(), 'registration-token');
  });
}
