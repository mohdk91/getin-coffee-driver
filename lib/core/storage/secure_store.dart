/// Contract for secrets/tokens that will later be backed by platform secure storage.
///
/// Task #3 introduces the authentication UI and repository boundary, but the
/// current development flow is explicitly local/demo-only. It does not create
/// or persist a real access token. When the Laravel auth contract is connected,
/// provide a platform secure-storage implementation behind this interface.
abstract class SecureStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

class UnconfiguredSecureStore implements SecureStore {
  const UnconfiguredSecureStore();

  StateError _notConfigured() => StateError(
        'Secure token storage is not configured because Driver Task #3 is '
        'running local/demo authentication only. Connect secure storage with '
        'the real Laravel authentication session.',
      );

  @override
  Future<void> clear() => Future.error(_notConfigured());

  @override
  Future<void> delete(String key) => Future.error(_notConfigured());

  @override
  Future<String?> read(String key) => Future.error(_notConfigured());

  @override
  Future<void> write(String key, String value) =>
      Future.error(_notConfigured());
}
