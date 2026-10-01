import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/features/delivery_verification/data/driver_delivery_qr_repository.dart';

void main() {
  test('Task 117 production QR never accepts demo payload shape', () {
    expect(DemoDriverDeliveryQrRepository.demoPayload.length, isNot(64));
    expect(
        RegExp(r'^[a-fA-F0-9]{64}$')
            .hasMatch(DemoDriverDeliveryQrRepository.demoPayload),
        isFalse);
  });
}
