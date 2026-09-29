import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/verification/data/driver_verification_repository.dart';
import 'package:getin_driver/features/verification/domain/driver_verification_models.dart';

void main() {
  test('demo verification repository preserves mapped driver states', () async {
    const repository = DemoDriverVerificationRepository();
    final now = DateTime(2026, 9, 25, 12);

    final approved = await repository.refreshStatus(
      DriverVerificationProfile(
        driverId: 'DRV-DEMO-001',
        displayName: 'Demo Driver',
        state: DriverVerificationState.pending,
        updatedAt: now,
      ),
    );
    final review = await repository.refreshStatus(
      DriverVerificationProfile(
        driverId: 'DRV-DEMO-004',
        displayName: 'Review Driver',
        state: DriverVerificationState.pending,
        updatedAt: now,
      ),
    );

    expect(approved.isSuccess, isTrue);
    expect(approved.data!.state, DriverVerificationState.approved);
    expect(approved.data!.canReceiveJobs, isTrue);
    expect(review.data!.state,
        DriverVerificationState.additionalInformationRequired);
    expect(review.data!.requestedItems, isNotEmpty);
    expect(review.data!.canReceiveJobs, isFalse);
  });

  test('unavailable verification repository never fakes a refresh', () async {
    const repository = UnavailableDriverVerificationRepository();
    final result = await repository.refreshStatus(
      DriverVerificationProfile(
        driverId: 'DRV-100',
        displayName: 'Driver',
        state: DriverVerificationState.pending,
        updatedAt: DateTime(2026, 9, 25),
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.failure!.type, DriverVerificationFailureType.unavailable);
  });
}
