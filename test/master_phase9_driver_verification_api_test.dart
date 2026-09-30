import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/verification/domain/driver_verification_models.dart';

void main() {
  test('Phase 9 verification source exposes production API mode', () {
    expect(DriverVerificationSource.values,
        contains(DriverVerificationSource.api));
  });
}
