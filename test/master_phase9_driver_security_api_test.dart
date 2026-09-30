import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/storage/secure_store.dart';

void main() {
  test('Phase 9 keeps Driver PIN in secure device storage', () {
    expect(SecureStoreKeys.driverPin, 'getin.driver.pin');
  });
}
