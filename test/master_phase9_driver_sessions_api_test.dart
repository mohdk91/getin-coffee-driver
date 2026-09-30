import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/storage/secure_store.dart';
import 'package:getin_driver/features/security/domain/driver_security_models.dart';

void main() {
  test('Phase 9 session model and stable secure device id key are present', () {
    final session = DriverActiveSession(
        id: '10',
        deviceName: 'Pixel',
        platform: 'android',
        locationLabel: '',
        lastActiveAt: DateTime(2026),
        isCurrent: true);
    expect(session.statusLabel, 'Current device');
    expect(SecureStoreKeys.driverDeviceId, 'getin.driver.device_id');
  });
}
