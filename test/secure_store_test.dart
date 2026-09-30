import 'package:flutter_test/flutter_test.dart';
import 'package:getin_driver/core/storage/secure_store.dart';

void main() {
  test('memory secure store follows secure store contract', () async {
    final store = MemorySecureStore();

    await store.write(SecureStoreKeys.accessToken, 'token-1');
    expect(await store.read(SecureStoreKeys.accessToken), 'token-1');

    await store.delete(SecureStoreKeys.accessToken);
    expect(await store.read(SecureStoreKeys.accessToken), isNull);

    await store.write('a', '1');
    await store.write('b', '2');
    await store.clear();
    expect(await store.read('a'), isNull);
    expect(await store.read('b'), isNull);
  });
}
