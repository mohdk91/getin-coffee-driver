import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/auth/data/driver_auth_repository.dart';
import 'package:getin_driver/features/auth/domain/driver_auth_models.dart';

void main() {
  const repository = DemoDriverAuthRepository();

  test('demo phone auth succeeds only through explicit OTP verification',
      () async {
    final request = await repository.requestOtp(
      dialCode: '+20',
      phoneNumber: '1001234567',
    );

    expect(request.isSuccess, isTrue);
    expect(request.data, isNotNull);

    final verified = await repository.verifyOtp(
      challenge: request.data!,
      code: '123456',
    );

    expect(verified.isSuccess, isTrue);
    expect(verified.data!.accessState, DriverAccessState.active);
  });

  test('demo OTP exposes invalid and retryable failures without authenticating',
      () async {
    final request = await repository.requestOtp(
      dialCode: '+20',
      phoneNumber: '1001234567',
    );

    final invalid = await repository.verifyOtp(
      challenge: request.data!,
      code: '111111',
    );
    expect(invalid.isSuccess, isFalse);
    expect(invalid.failure!.type, DriverAuthFailureType.invalidOtp);

    final temporary = await repository.verifyOtp(
      challenge: request.data!,
      code: '777777',
    );
    expect(temporary.isSuccess, isFalse);
    expect(temporary.failure!.retryable, isTrue);
  });

  test('demo OTP returns blocked account states for auth gating', () async {
    final request = await repository.requestOtp(
      dialCode: '+20',
      phoneNumber: '1001234567',
    );

    final pending = await repository.verifyOtp(
      challenge: request.data!,
      code: '333333',
    );
    final suspended = await repository.verifyOtp(
      challenge: request.data!,
      code: '555555',
    );

    expect(pending.data!.accessState, DriverAccessState.pendingApproval);
    expect(suspended.data!.accessState, DriverAccessState.suspended);
  });

  test('demo email auth supports active and blocked accounts', () async {
    final active = await repository.signInWithEmail(
      email: 'driver@getin.local',
      password: 'Driver123!',
    );
    final rejected = await repository.signInWithEmail(
      email: 'rejected@getin.local',
      password: 'Driver123!',
    );

    expect(active.data!.accessState, DriverAccessState.active);
    expect(rejected.data!.accessState, DriverAccessState.rejected);
  });

  test('unavailable repository never pretends login is connected', () async {
    const unavailable = UnavailableDriverAuthRepository();
    final result = await unavailable.signInWithEmail(
      email: 'driver@getin.local',
      password: 'Driver123!',
    );

    expect(result.isSuccess, isFalse);
    expect(result.failure!.type, DriverAuthFailureType.unavailable);
  });
}
