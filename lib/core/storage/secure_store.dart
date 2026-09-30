import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

class FlutterSecureStoreAdapter implements SecureStore {
  final FlutterSecureStorage storage;

  const FlutterSecureStoreAdapter({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<void> clear() => storage.deleteAll();

  @override
  Future<void> delete(String key) => storage.delete(key: key);

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);
}

class MemorySecureStore implements SecureStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> clear() async {
    _values.clear();
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

abstract final class SecureStoreKeys {
  static const accessToken = 'getin.access_token';
  static const refreshToken = 'getin.refresh_token';
  static const driverDeviceId = 'getin.driver.device_id';
  static const driverPin = 'getin.driver.pin';
}
