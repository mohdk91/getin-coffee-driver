import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/storage/driver_token_store.dart';
import 'package:getin_driver/core/storage/secure_store.dart';

void main() {
  test('Phase 9 token store persists and clears bearer token only', () async {
    final secure = MemorySecureStore();
    final tokens = DriverTokenStore(secure);

    await secure.write(SecureStoreKeys.driverDeviceId, 'device-12345678');
    await tokens.saveAccessToken(' token-abc ');

    expect(await tokens.readAccessToken(), 'token-abc');
    expect(await tokens.hasAccessToken(), isTrue);

    await tokens.clearAccessToken();
    expect(await tokens.readAccessToken(), isNull);
    expect(
        await secure.read(SecureStoreKeys.driverDeviceId), 'device-12345678');
  });
}
