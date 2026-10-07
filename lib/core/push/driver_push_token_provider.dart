import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class DriverPushTokenProvider {
  Future<String?> currentToken({bool requestPermission = true});
  Future<void> deleteToken();
}

class FirebaseDriverPushTokenProvider implements DriverPushTokenProvider {
  final FirebaseMessaging? _messaging;

  FirebaseDriverPushTokenProvider({FirebaseMessaging? messaging})
      : _messaging = messaging;

  FirebaseMessaging get _client => _messaging ?? FirebaseMessaging.instance;

  @override
  Future<String?> currentToken({bool requestPermission = true}) async {
    try {
      if (requestPermission) {
        final settings = await _client.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return null;
        }
      }
      final token = await _client.getToken();
      final normalized = token?.trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _client.deleteToken();
    } catch (_) {
      // Token deletion is best-effort. Server-side token removal is attempted
      // separately before the authenticated session is revoked.
    }
  }
}
