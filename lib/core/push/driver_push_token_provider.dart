import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class DriverPushTokenProvider {
  Future<String?> currentToken({bool requestPermission = true});
  Future<void> deleteToken();
}

class DriverPushTokenRetryPolicy {
  final List<Duration> retryDelays;

  const DriverPushTokenRetryPolicy({
    this.retryDelays = const <Duration>[
      Duration(milliseconds: 750),
      Duration(seconds: 2),
    ],
  });

  bool shouldRetry(Object error) {
    final message = error.toString().toUpperCase();
    return message.contains('SERVICE_NOT_AVAILABLE') ||
        message.contains('UNAVAILABLE') ||
        message.contains('INTERNAL_SERVER_ERROR') ||
        message.contains('NETWORK_ERROR') ||
        message.contains('TIMEOUT') ||
        message.contains('TEMPORARY') ||
        message.contains('TOO_MANY_REQUESTS') ||
        message.contains('FID_ALREADY_USED');
  }
}

class FirebaseDriverPushTokenProvider implements DriverPushTokenProvider {
  final FirebaseMessaging? _messaging;
  final DriverPushTokenRetryPolicy retryPolicy;
  final Future<void> Function(Duration) _delay;

  FirebaseDriverPushTokenProvider({
    FirebaseMessaging? messaging,
    DriverPushTokenRetryPolicy? retryPolicy,
    Future<void> Function(Duration)? delay,
  })  : _messaging = messaging,
        retryPolicy = retryPolicy ?? const DriverPushTokenRetryPolicy(),
        _delay = delay ?? Future<void>.delayed;

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
    } catch (_) {
      return null;
    }

    for (var attempt = 0;; attempt += 1) {
      try {
        final token = await _client.getToken();
        final normalized = token?.trim();
        if (normalized != null && normalized.isNotEmpty) {
          return normalized;
        }

        if (attempt >= retryPolicy.retryDelays.length) {
          return null;
        }
      } catch (error) {
        if (attempt >= retryPolicy.retryDelays.length ||
            !retryPolicy.shouldRetry(error)) {
          return null;
        }
      }

      await _delay(retryPolicy.retryDelays[attempt]);
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
