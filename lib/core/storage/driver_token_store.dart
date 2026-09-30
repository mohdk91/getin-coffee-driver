import 'secure_store.dart';

class DriverTokenStore {
  final SecureStore secureStore;

  const DriverTokenStore(this.secureStore);

  Future<String?> readAccessToken() async {
    final token = await secureStore.read(SecureStoreKeys.accessToken);
    final normalized = token?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<bool> hasAccessToken() async => (await readAccessToken()) != null;

  Future<void> saveAccessToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
          token, 'token', 'Access token cannot be empty.');
    }
    await secureStore.write(SecureStoreKeys.accessToken, normalized);
  }

  Future<void> clearAccessToken() =>
      secureStore.delete(SecureStoreKeys.accessToken);
}
